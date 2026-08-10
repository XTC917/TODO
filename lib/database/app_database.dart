import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('EventRow')
class Events extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get date => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  TextColumn get note => text().nullable()();
  TextColumn get color => text()();
  TextColumn get taskType =>
      text().withDefault(const Constant('todo'))();
  TextColumn get todoTimeMode =>
      text().withDefault(const Constant('timeBlock'))();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  TextColumn get repeatType =>
      text().withDefault(const Constant('oneTime'))();
  TextColumn get repeatGroupId => text().nullable()();
  IntColumn get reminderOffsetSeconds => integer().nullable()();
  TextColumn get reminderOffsetsJson => text().nullable()();
  IntColumn get focusedSeconds =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

@DataClassName('FocusRecordRow')
class FocusRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get date => text()();
  TextColumn get startTime => text()();
  TextColumn get endTime => text()();
  IntColumn get durationSeconds => integer()();
  TextColumn get mode => text()();
  IntColumn get eventId => integer().nullable()();
  TextColumn get taskTitle => text().nullable()();
  IntColumn get plannedDurationSeconds => integer().nullable()();
  BoolColumn get completed =>
      boolean().withDefault(const Constant(true))();
  TextColumn get enforcementMode =>
      text().withDefault(const Constant('normal'))();
  DateTimeColumn get createdAt => dateTime()();
}

@DriftDatabase(tables: [Events, FocusRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(events, events.taskType);
            await m.addColumn(events, events.isCompleted);
            await m.addColumn(events, events.repeatType);
            await m.addColumn(events, events.repeatGroupId);
            await m.addColumn(events, events.focusedSeconds);
            await m.addColumn(events, events.completedAt);
            await m.createTable(focusRecords);
          }
          if (from < 3) {
            await m.addColumn(events, events.todoTimeMode);
          }
          if (from < 4) {
            await m.addColumn(events, events.reminderOffsetSeconds);
            if (from >= 2) {
              await customStatement('''
                UPDATE events SET reminder_offset_seconds = CASE reminder_type
                  WHEN 'atTime' THEN 0
                  WHEN 'min5' THEN 300
                  WHEN 'min10' THEN 600
                  WHEN 'min15' THEN 900
                  WHEN 'min30' THEN 1800
                  WHEN 'hour1' THEN 3600
                  ELSE NULL
                END
              ''');
            }
          }
          if (from < 5) {
            await m.addColumn(events, events.reminderOffsetsJson);
            await customStatement('''
              UPDATE events
              SET reminder_offsets_json = '[' || reminder_offset_seconds || ']'
              WHERE reminder_offset_seconds IS NOT NULL
            ''');
          }
          if (from < 6) {
            await m.addColumn(focusRecords, focusRecords.taskTitle);
            await m.addColumn(focusRecords, focusRecords.plannedDurationSeconds);
            await m.addColumn(focusRecords, focusRecords.completed);
          }
          if (from < 7) {
            await customStatement(
              "ALTER TABLE focus_records ADD COLUMN enforcement_mode TEXT NOT NULL DEFAULT 'normal'",
            );
          }
        },
      );

  Future<List<EventRow>> getAllEvents() => select(events).get();

  Future<List<EventRow>> getEventsByDate(String date) {
    return (select(events)
          ..where((t) => t.date.equals(date))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  Stream<List<EventRow>> watchAllEvents() {
    return (select(events)
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.startTime),
          ]))
        .watch();
  }

  Stream<List<EventRow>> watchEventsByDate(String date) {
    return (select(events)
          ..where((t) => t.date.equals(date))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Stream<List<EventRow>> watchEventsInRange(String startDate, String endDate) {
    return (select(events)
          ..where((t) => t.date.isBetweenValues(startDate, endDate))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.startTime),
          ]))
        .watch();
  }

  Stream<List<EventRow>> watchTodos() {
    return (select(events)
          ..where((t) => t.taskType.equals('todo'))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.startTime),
          ]))
        .watch();
  }

  Future<Set<String>> getDatesWithEventsInRange(
    String startDate,
    String endDate,
  ) async {
    final rows = await (select(events)
          ..where((t) => t.date.isBetweenValues(startDate, endDate)))
        .get();
    return rows.map((e) => e.date).toSet();
  }

  Future<EventRow?> getEventById(int id) {
    return (select(events)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<EventRow>> getEventsByRepeatGroup(String groupId) {
    return (select(events)..where((t) => t.repeatGroupId.equals(groupId)))
        .get();
  }

  Future<EventRow?> getEventByRepeatGroupAndDate(
    String groupId,
    String date,
  ) {
    return (select(events)
          ..where(
            (t) => t.repeatGroupId.equals(groupId) & t.date.equals(date),
          ))
        .getSingleOrNull();
  }

  Future<EventRow?> getSeriesTemplateRow(String groupId) async {
    final rows = await getEventsByRepeatGroup(groupId);
    if (rows.isEmpty) return null;
    final masters = rows.where((row) => row.repeatType != 'oneTime').toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    if (masters.isEmpty) return null;
    return masters.first;
  }

  Future<int> updateEventsByRepeatGroupFromDate(
    String groupId,
    String fromDate,
    EventsCompanion companion,
  ) {
    return (update(events)
          ..where(
            (t) =>
                t.repeatGroupId.equals(groupId) &
                t.date.isBiggerOrEqualValue(fromDate),
          ))
        .write(companion);
  }

  Future<int> insertEvent(EventsCompanion companion) {
    return into(events).insert(companion);
  }

  Future<bool> updateEventRow(EventRow row) {
    return update(events).replace(row);
  }

  Future<int> deleteEvent(int id) {
    return (delete(events)..where((t) => t.id.equals(id))).go();
  }

  Future<int> deleteEventsByRepeatGroup(String groupId) {
    return (delete(events)..where((t) => t.repeatGroupId.equals(groupId))).go();
  }

  Future<int> deleteEventsByRepeatGroupFromDate(
    String groupId,
    String fromDate,
  ) {
    return (delete(events)
          ..where((t) =>
              t.repeatGroupId.equals(groupId) & t.date.isBiggerOrEqualValue(fromDate)))
        .go();
  }

  // Focus records
  Stream<List<FocusRecordRow>> watchFocusRecords() {
    return (select(focusRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<FocusRecordRow>> watchFocusRecordsByDate(String date) {
    return (select(focusRecords)
          ..where((t) => t.date.equals(date))
          ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Stream<List<FocusRecordRow>> watchFocusRecordsInRange(
    String startDate,
    String endDate,
  ) {
    return (select(focusRecords)
          ..where((t) => t.date.isBetweenValues(startDate, endDate))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .watch();
  }

  Future<int> insertFocusRecord(FocusRecordsCompanion companion) {
    return into(focusRecords).insert(companion);
  }

  Future<int> updateFocusRecord(FocusRecordsCompanion companion) {
    final id = companion.id.value;
    return (update(focusRecords)..where((t) => t.id.equals(id)))
        .write(companion);
  }

  Future<int> deleteFocusRecord(int id) {
    return (delete(focusRecords)..where((t) => t.id.equals(id))).go();
  }

  Future<FocusRecordRow?> getFocusRecordById(int id) {
    return (select(focusRecords)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<List<FocusRecordRow>> getFocusRecordsInRange(
    String startDate,
    String endDate,
  ) {
    return (select(focusRecords)
          ..where((t) => t.date.isBetweenValues(startDate, endDate)))
        .get();
  }

  Future<File> databaseFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'soft_schedule.sqlite'));
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'soft_schedule.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
