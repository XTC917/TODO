import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../core/utils/date_time_formats.dart';
import '../core/utils/event_constants.dart';
import '../core/utils/repeat_occurrence_utils.dart';
import '../core/utils/repeat_expander.dart';
import '../core/utils/repeat_until_storage.dart';
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
    return _db.watchAllEvents().map((rows) {
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

  Future<List<Event>> getEventsByRepeatGroup(String groupId) async {
    final rows = await _db.getEventsByRepeatGroup(groupId);
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
    if (title.length > kMaxEventTitleLength) {
      throw ArgumentError('Title too long');
    }
    final note = _nullableNote(draft.note);
    if (note != null && note.length > kMaxEventNoteLength) {
      throw ArgumentError('Note too long');
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

    return id;
  }

  Future<void> update(Event event) async {
    _validateEvent(event);
    final previous = await getById(event.id);
    await _db.updateEventRow(_toRow(event.copyWith(updatedAt: DateTime.now())));
    if (previous != null) {
      await _maybeUpgradeToRecurring(previous, event);
    }
  }

  /// When an existing one-time row becomes recurring, assign a group and materialize.
  Future<void> _maybeUpgradeToRecurring(Event previous, Event updated) async {
    if (updated.repeatType == RepeatType.oneTime ||
        updated.repeatGroupId != null ||
        previous.repeatType != RepeatType.oneTime ||
        !updated.hasDate) {
      return;
    }

    final groupId = _uuid.v4();
    final master = updated.copyWith(
      repeatGroupId: groupId,
      updatedAt: DateTime.now(),
    );
    await _db.updateEventRow(_toRow(master));
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

  /// Complete/uncomplete a single calendar occurrence (never the whole series).
  Future<void> toggleTimelineForOccurrence(
    Event occurrence, {
    required bool completed,
  }) async {
    if (occurrence.repeatGroupId == null) {
      await toggleTimelineComplete(occurrence.id, completed: completed);
      return;
    }

    final groupId = occurrence.repeatGroupId!;
    final dateKey = occurrence.date;
    final concrete = await _db.getEventByRepeatGroupAndDate(groupId, dateKey);

    if (concrete != null) {
      if (concrete.title == kRepeatSkipMarker) return;
      await toggleTimelineComplete(concrete.id, completed: completed);
      return;
    }

    final template = await _seriesTemplate(groupId, fallbackId: occurrence.id);
    if (template == null) return;
    await _insertOccurrenceRow(
      template: template,
      dateKey: dateKey,
      completed: completed,
    );
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
        note: event.userNote,
        color: event.color,
        taskType: event.taskType,
        todoTimeMode: event.todoTimeMode,
        repeatType: RepeatType.oneTime,
        reminderOffsetsSeconds: event.reminderOffsetsSeconds,
      ),
    );
    return (await getById(newId))!;
  }

  Future<Event?> getSeriesTemplate(String groupId) async {
    final row = await _seriesMasterRow(groupId);
    return row != null ? _toDomain(row) : null;
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
    Event occurrence,
    RepeatScope scope,
  ) async {
    if (occurrence.repeatGroupId == null) {
      await delete(occurrence.id);
      return;
    }

    final groupId = occurrence.repeatGroupId!;
    await _compactRedundantInstances(groupId);
    switch (scope) {
      case RepeatScope.onlyThis:
        await _deleteSingleOccurrence(occurrence);
      case RepeatScope.thisAndFuture:
        await _db.deleteEventsByRepeatGroupFromDate(groupId, occurrence.date);
        await _truncateSeriesFrom(groupId, occurrence.date);
        await _demoteMaterializedMasters(groupId);
      case RepeatScope.all:
        await _db.deleteEventsByRepeatGroup(groupId);
    }
  }

  Future<void> updateWithScope(
    Event occurrence,
    Event updated,
    RepeatScope scope,
  ) async {
    _validateEvent(updated);
    if (occurrence.repeatGroupId == null) {
      await update(updated.copyWith(id: occurrence.id, date: occurrence.date));
      return;
    }

    final groupId = occurrence.repeatGroupId!;
    switch (scope) {
      case RepeatScope.onlyThis:
        await _updateSingleOccurrence(occurrence, updated);
      case RepeatScope.thisAndFuture:
        await _updateFutureOccurrences(groupId, occurrence.date, updated);
        await _demoteMaterializedMasters(groupId);
      case RepeatScope.all:
        await _updateAllInGroup(groupId, updated);
    }
  }

  Future<FilePath> databasePath() async {
    final file = await _db.databaseFile();
    return FilePath(file.path);
  }

  Future<void> _deleteSingleOccurrence(Event occurrence) async {
    final groupId = occurrence.repeatGroupId!;
    final dateKey = occurrence.date;
    final master = await _seriesMasterRow(groupId);
    final concrete = await _db.getEventByRepeatGroupAndDate(groupId, dateKey);
    if (concrete != null &&
        concrete.title != kRepeatSkipMarker &&
        (master == null || concrete.id != master.id)) {
      await delete(concrete.id);
    }

    final template = await _seriesTemplate(groupId, fallbackId: occurrence.id);
    if (template == null) return;
    await _insertSkipOccurrence(template, dateKey);
  }

  Future<void> _updateSingleOccurrence(Event occurrence, Event updated) async {
    final groupId = occurrence.repeatGroupId!;
    final dateKey = occurrence.date;
    final concrete = await _db.getEventByRepeatGroupAndDate(groupId, dateKey);
    final now = DateTime.now();
    final master = await _seriesMasterRow(groupId);

    if (concrete != null && concrete.title != kRepeatSkipMarker) {
      if (master != null && concrete.id == master.id) {
        final rows = await _db.getEventsByRepeatGroup(groupId);
        final existingOverrides = rows
            .where(
              (row) =>
                  row.date == dateKey &&
                  row.id != master.id &&
                  row.title != kRepeatSkipMarker &&
                  row.repeatType == RepeatType.oneTime.storage,
            )
            .toList();
        if (existingOverrides.isNotEmpty) {
          final existingOverride = existingOverrides.first;
          await update(
            updated.copyWith(
              id: existingOverride.id,
              date: dateKey,
              repeatType: RepeatType.oneTime,
              repeatGroupId: groupId,
            ),
          );
          return;
        }
        await _insertOccurrenceRow(
          template: updated.copyWith(
            id: master.id,
            date: dateKey,
            repeatType: RepeatType.oneTime,
            repeatGroupId: groupId,
            updatedAt: now,
          ),
          dateKey: dateKey,
          completed: updated.isCompleted,
        );
        return;
      }

      await update(
        updated.copyWith(
          id: concrete.id,
          date: dateKey,
          repeatType: RepeatType.oneTime,
          repeatGroupId: groupId,
        ),
      );
      return;
    }

    final template = await _seriesTemplate(groupId, fallbackId: occurrence.id);
    if (template == null) return;
    await _insertOccurrenceRow(
      template: updated.copyWith(
        id: template.id,
        date: dateKey,
        repeatType: RepeatType.oneTime,
        repeatGroupId: groupId,
        updatedAt: now,
      ),
      dateKey: dateKey,
      completed: updated.isCompleted,
    );
  }

  Future<void> _updateFutureOccurrences(
    String groupId,
    String fromDate,
    Event updated,
  ) async {
    final now = DateTime.now();
    final companion = EventsCompanion(
      title: Value(updated.title.trim()),
      startTime: Value(updated.startTime),
      endTime: Value(updated.endTime),
      note: Value(_nullableNote(updated.note)),
      color: Value(updated.color),
      taskType: Value(updated.taskType.storage),
      todoTimeMode: Value(updated.todoTimeMode.storage),
      repeatType: Value(updated.repeatType.storage),
      reminderOffsetsJson: Value(
        encodeReminderOffsets(updated.reminderOffsetsSeconds),
      ),
      updatedAt: Value(now),
    );
    await _db.updateEventsByRepeatGroupFromDate(groupId, fromDate, companion);

    final template = await _seriesTemplate(groupId);
    if (template != null && template.date.compareTo(fromDate) < 0) {
      await update(
        template.copyWith(
          repeatType: updated.repeatType,
          repeatUntil: _dayBefore(fromDate),
        ),
      );
    }
  }

  Future<void> _updateAllInGroup(String groupId, Event updated) async {
    final rows = await _db.getEventsByRepeatGroup(groupId);
    final now = DateTime.now();
    for (final row in rows) {
      if (row.title == kRepeatSkipMarker) continue;
      await update(
        updated.copyWith(
          id: row.id,
          date: row.date,
          repeatType: updated.repeatType,
          repeatGroupId: groupId,
          updatedAt: now,
        ),
      );
    }
  }

  Future<void> _truncateSeriesFrom(String groupId, String fromDate) async {
    final template = await _seriesTemplate(groupId);
    if (template == null) return;
    if (template.date.compareTo(fromDate) < 0) {
      await update(
        template.copyWith(
          repeatUntil: _dayBefore(fromDate),
        ),
      );
    }
  }

  /// Legacy materialized rows were stored with repeatType != oneTime and could
  /// each expand into duplicate virtual instances after partial series edits.
  Future<void> _demoteMaterializedMasters(String groupId) async {
    final master = await _seriesMasterRow(groupId);
    if (master == null) return;

    final rows = await _db.getEventsByRepeatGroup(groupId);
    for (final row in rows) {
      if (row.id == master.id || row.title == kRepeatSkipMarker) continue;
      if (row.repeatType == RepeatType.oneTime.storage) continue;
      await update(_toDomain(row).copyWith(repeatType: RepeatType.oneTime));
    }
  }

  Future<Event?> _seriesTemplate(String groupId, {int? fallbackId}) async {
    final row = await _seriesMasterRow(groupId);
    if (row != null) return _toDomain(row);
    if (fallbackId != null) return getById(fallbackId);
    return null;
  }

  Future<EventRow?> _seriesMasterRow(String groupId) async {
    return _db.getSeriesTemplateRow(groupId);
  }

  Future<void> _insertOccurrenceRow({
    required Event template,
    required String dateKey,
    required bool completed,
  }) async {
    final now = DateTime.now();
    await _db.insertEvent(
      EventsCompanion.insert(
        title: template.title.trim(),
        date: dateKey,
        startTime: template.startTime,
        endTime: template.endTime,
        note: Value(_nullableNote(template.userNote)),
        color: template.color,
        taskType: Value(template.taskType.storage),
        todoTimeMode: Value(template.todoTimeMode.storage),
        isCompleted: Value(completed),
        repeatType: const Value('oneTime'),
        repeatGroupId: Value(template.repeatGroupId),
        reminderOffsetsJson: Value(
          encodeReminderOffsets(template.reminderOffsetsSeconds),
        ),
        completedAt: Value(completed ? now : null),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  Future<void> _insertSkipOccurrence(Event template, String dateKey) async {
    final existing =
        await _db.getEventByRepeatGroupAndDate(template.repeatGroupId!, dateKey);
    if (existing != null) return;

    final now = DateTime.now();
    await _db.insertEvent(
      EventsCompanion.insert(
        title: kRepeatSkipMarker,
        date: dateKey,
        startTime: template.startTime,
        endTime: template.endTime,
        color: template.color,
        taskType: Value(template.taskType.storage),
        todoTimeMode: Value(template.todoTimeMode.storage),
        repeatType: const Value('oneTime'),
        repeatGroupId: Value(template.repeatGroupId),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  String _dayBefore(String dateKey) {
    final day = DateTimeFormats.parseDate(dateKey);
    return DateTimeFormats.formatDate(day.subtract(const Duration(days: 1)));
  }

  /// One-time cleanup for repeat series materialized by older app versions.
  Future<void> compactAllLegacyMaterialized() async {
    final rows = await _db.getAllEvents();
    final groupIds = rows
        .map((row) => row.repeatGroupId)
        .whereType<String>()
        .toSet();
    for (final groupId in groupIds) {
      await _compactRedundantInstances(groupId);
    }
  }

  /// Removes bulk materialized copies left by older versions. Keeps skips,
  /// completed days, and user-edited single occurrences (e.g. custom reminders).
  Future<void> _compactRedundantInstances(String groupId) async {
    final master = await _seriesMasterRow(groupId);
    if (master == null) return;

    final rows = await _db.getEventsByRepeatGroup(groupId);
    for (final row in rows) {
      if (row.id == master.id || row.title == kRepeatSkipMarker) continue;
      if (!RepeatOccurrenceUtils.isRedundantMaterializedCopy(
        master: master,
        row: row,
      )) {
        continue;
      }
      await delete(row.id);
    }
  }

  void _validateEvent(Event event) {
    if (event.title.trim().isEmpty) {
      throw ArgumentError('Title cannot be empty');
    }
    if (event.title.length > kMaxEventTitleLength) {
      throw ArgumentError('Title too long');
    }
    final note = _nullableNote(event.note);
    if (note != null && note.length > kMaxEventNoteLength) {
      throw ArgumentError('Note too long');
    }
  }

  Event _toDomain(EventRow row) {
    final repeatUntil =
        row.repeatUntil ?? RepeatUntilStorage.parseFromNote(row.note);
    return Event(
      id: row.id,
      title: row.title,
      date: row.date,
      startTime: row.startTime,
      endTime: row.endTime,
      note: RepeatUntilStorage.userNote(row.note, repeatUntil: repeatUntil),
      color: row.color,
      taskType: TaskTypeX.fromStorage(row.taskType),
      todoTimeMode: TodoTimeModeX.fromStorage(row.todoTimeMode),
      isCompleted: row.isCompleted,
      repeatType: RepeatTypeX.fromStorage(row.repeatType),
      repeatGroupId: row.repeatGroupId,
      repeatUntil: repeatUntil,
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
      note: _nullableNote(
        RepeatUntilStorage.userNote(event.note, repeatUntil: event.repeatUntil),
      ),
      color: event.color,
      taskType: event.taskType.storage,
      todoTimeMode: event.todoTimeMode.storage,
      isCompleted: event.isCompleted,
      repeatType: event.repeatType.storage,
      repeatGroupId: event.repeatGroupId,
      repeatUntil: event.repeatUntil,
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
    final trimmed = RepeatUntilStorage.stripFromNote(note)?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

class FilePath {
  const FilePath(this.path);
  final String path;
}
