import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_time_formats.dart';
import '../core/utils/repeat_expander.dart';
import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/event.dart';
import '../models/reminder_config.dart';

class EventRepository {
  EventRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Event>> watchByDate(String date) {
    return _db.watchAllEvents().map((rows) {
      final domain = rows.map(_toDomain).toList();
      return RepeatExpander.expandForDate(domain, DateTime.parse(date))
          .where((e) => e.hasDate && e.date == date)
          .toList();
    });
  }

  Stream<List<Event>> watchInRange(String startDate, String endDate) {
    return _db.watchEventsInRange(startDate, endDate).map((rows) {
      final domain = rows.map(_toDomain).toList();
      return RepeatExpander.expandForRange(
        domain,
        DateTime.parse(startDate),
        DateTime.parse(endDate),
      );
    });
  }

  Stream<List<Event>> watchAllTodos() {
    return _db.watchTodos().map((rows) => rows.map(_toDomain).toList());
  }

  Future<Event?> getById(int id) async {
    final row = await _db.getEventById(id);
    return row == null ? null : _toDomain(row);
  }

  Future<List<Event>> getAllEvents() async {
    final rows = await _db.getAllEvents();
    return rows.map(_toDomain).toList();
  }

  Future<Set<String>> datesWithEvents(String startDate, String endDate) async {
    final rows = await _db.getAllEvents();
    final domain = rows.map(_toDomain).toList();
    final dates = <String>{};
    var d = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    while (!d.isAfter(end)) {
      final expanded = RepeatExpander.expandForDate(domain, d);
      if (expanded.isNotEmpty) {
        dates.add(DateTimeFormats.formatDate(d));
      }
      d = d.add(const Duration(days: 1));
    }
    return dates;
  }

  Future<int> create(EventDraft draft) async {
    final title = draft.title.trim();
    if (title.isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    final now = DateTime.now();
    final groupId = draft.repeatType == RepeatType.oneTime
        ? null
        : (draft.repeatGroupId ?? _uuid.v4());

    final id = await _db.insertEvent(
      EventsCompanion.insert(
        title: title,
        date: draft.date,
        startTime: draft.startTime,
        endTime: draft.endTime,
        note: Value(_nullableNote(draft.note)),
        color: draft.color,
        taskType: Value(draft.taskType.storage),
        todoTimeMode: Value(draft.todoTimeMode.storage),
        repeatType: Value(draft.repeatType.storage),
        repeatGroupId: Value(groupId),
        reminderOffsetsJson: Value(
          encodeReminderOffsets(draft.reminderOffsetsSeconds),
        ),
        createdAt: now,
        updatedAt: now,
      ),
    );

    if (draft.repeatType != RepeatType.oneTime) {
      await _materializeRepeats(groupId!, draft, excludeDate: draft.date);
    }
    return id;
  }

  Future<void> update(Event event) async {
    await _db.updateEventRow(_toRow(event.copyWith(updatedAt: DateTime.now())));
  }

  Future<void> toggleTodoComplete(int id, {required bool completed}) async {
    final event = await getById(id);
    if (event == null || !event.isTodo) return;
    await update(
      event.copyWith(
        isCompleted: completed,
        completedAt: completed ? DateTime.now() : null,
        clearCompletedAt: !completed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> toggleScheduleComplete(int id, {required bool completed}) async {
    final event = await getById(id);
    if (event == null || !event.isSchedule) return;
    await update(
      event.copyWith(
        isCompleted: completed,
        completedAt: completed ? DateTime.now() : null,
        clearCompletedAt: !completed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> toggleTimelineComplete(int id, {required bool completed}) async {
    final event = await getById(id);
    if (event == null) return;
    if (event.isTodo) {
      await toggleTodoComplete(id, completed: completed);
    } else {
      await toggleScheduleComplete(id, completed: completed);
    }
  }

  Future<void> addFocusedSeconds(int eventId, int seconds) async {
    final event = await getById(eventId);
    if (event == null) return;
    await update(event.copyWith(focusedSeconds: event.focusedSeconds + seconds));
  }

  Future<Event> duplicate(int id) async {
    final event = await getById(id);
    if (event == null) throw StateError('Event not found');
    final newId = await create(
      EventDraft(
        title: '${event.title} (copy)',
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
        note: event.note,
        color: event.color,
        taskType: event.taskType,
        todoTimeMode: event.todoTimeMode,
        repeatType: RepeatType.oneTime,
        reminderOffsetsSeconds: event.reminderOffsetsSeconds,
      ),
    );
    return (await getById(newId))!;
  }

  Future<void> delete(int id) => _db.deleteEvent(id);

  Future<void> batchDelete(Set<int> ids) async {
    for (final id in ids) {
      await delete(id);
    }
  }

  Future<void> batchUpdateDate(Set<int> ids, String newDate) async {
    for (final id in ids) {
      final event = await getById(id);
      if (event == null || !event.hasDate) continue;
      await update(event.copyWith(date: newDate));
    }
  }

  Future<void> deleteWithScope(
    Event event,
    DeleteRepeatScope scope,
  ) async {
    if (event.repeatType == RepeatType.oneTime || event.repeatGroupId == null) {
      await delete(event.id);
      return;
    }

    final groupId = event.repeatGroupId!;
    switch (scope) {
      case DeleteRepeatScope.onlyThis:
        await delete(event.id);
      case DeleteRepeatScope.thisAndFuture:
        await _db.deleteEventsByRepeatGroupFromDate(groupId, event.date);
      case DeleteRepeatScope.all:
        await _db.deleteEventsByRepeatGroup(groupId);
    }
  }

  Future<FilePath> databasePath() async {
    final file = await _db.databaseFile();
    return FilePath(file.path);
  }

  Future<void> _materializeRepeats(
    String groupId,
    EventDraft template, {
    required String excludeDate,
  }) async {
    final now = DateTime.now();
    final start = DateTime.parse(template.date);
    final end = start.add(const Duration(days: 365));
    var cursor = start;

    while (!cursor.isAfter(end)) {
      final key = DateTimeFormats.formatDate(cursor);
      if (key != excludeDate && RepeatExpander.occursOn(template, cursor)) {
        await _db.insertEvent(
          EventsCompanion.insert(
            title: template.title.trim(),
            date: key,
            startTime: template.startTime,
            endTime: template.endTime,
            note: Value(_nullableNote(template.note)),
            color: template.color,
            taskType: Value(template.taskType.storage),
            todoTimeMode: Value(template.todoTimeMode.storage),
            repeatType: Value(template.repeatType.storage),
            repeatGroupId: Value(groupId),
            reminderOffsetsJson: Value(
              encodeReminderOffsets(template.reminderOffsetsSeconds),
            ),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  Event _toDomain(EventRow row) {
    return Event(
      id: row.id,
      title: row.title,
      date: row.date,
      startTime: row.startTime,
      endTime: row.endTime,
      note: row.note,
      color: row.color,
      taskType: TaskTypeX.fromStorage(row.taskType),
      todoTimeMode: TodoTimeModeX.fromStorage(row.todoTimeMode),
      isCompleted: row.isCompleted,
      repeatType: RepeatTypeX.fromStorage(row.repeatType),
      repeatGroupId: row.repeatGroupId,
      reminderOffsetsSeconds: decodeReminderOffsets(
        json: row.reminderOffsetsJson,
        legacySingleOffset: row.reminderOffsetSeconds,
      ),
      focusedSeconds: row.focusedSeconds,
      completedAt: row.completedAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  EventRow _toRow(Event event) {
    return EventRow(
      id: event.id,
      title: event.title,
      date: event.date,
      startTime: event.startTime,
      endTime: event.endTime,
      note: _nullableNote(event.note),
      color: event.color,
      taskType: event.taskType.storage,
      todoTimeMode: event.todoTimeMode.storage,
      isCompleted: event.isCompleted,
      repeatType: event.repeatType.storage,
      repeatGroupId: event.repeatGroupId,
      reminderOffsetsJson: encodeReminderOffsets(event.reminderOffsetsSeconds),
      reminderOffsetSeconds: event.reminderOffsetsSeconds.length == 1
          ? event.reminderOffsetsSeconds.first
          : null,
      focusedSeconds: event.focusedSeconds,
      completedAt: event.completedAt,
      createdAt: event.createdAt,
      updatedAt: event.updatedAt,
    );
  }

  String? _nullableNote(String? note) {
    if (note == null) return null;
    final trimmed = note.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class FilePath {
  const FilePath(this.path);
  final String path;
}
