import 'package:drift/drift.dart';

import '../core/utils/date_time_formats.dart';
import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/event.dart';

class FocusRepository {
  FocusRepository(this._db);

  final AppDatabase _db;

  Stream<List<FocusRecord>> watchAll() {
    return _db.watchFocusRecords().map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  Stream<List<FocusRecord>> watchByDate(String date) {
    return _db.watchFocusRecordsByDate(date).map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  Stream<List<FocusRecord>> watchInRange(String start, String end) {
    return _db.watchFocusRecordsInRange(start, end).map(
          (rows) => rows.map(_toDomain).toList(growable: false),
        );
  }

  Future<int> save({
    required DateTime start,
    required DateTime end,
    required FocusMode mode,
    int? eventId,
  }) {
    final duration = end.difference(start).inSeconds;
    return _db.insertFocusRecord(
      FocusRecordsCompanion.insert(
        date: DateTimeFormats.formatDate(start),
        startTime: DateTimeFormats.formatTimeOfDay(start),
        endTime: DateTimeFormats.formatTimeOfDay(end),
        durationSeconds: duration,
        mode: mode.storage,
        eventId: Value(eventId),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<int> totalSecondsForDate(String date) async {
    final rows = await _db.watchFocusRecordsByDate(date).first;
    return rows.fold<int>(0, (sum, r) => sum + r.durationSeconds);
  }

  Future<Map<int, int>> topTodoFocusSeconds() async {
    final rows = await _db.watchFocusRecords().first;
    final map = <int, int>{};
    for (final row in rows) {
      if (row.eventId != null) {
        map[row.eventId!] = (map[row.eventId!] ?? 0) + row.durationSeconds;
      }
    }
    return map;
  }

  FocusRecord _toDomain(FocusRecordRow row) {
    return FocusRecord(
      id: row.id,
      date: row.date,
      startTime: row.startTime,
      endTime: row.endTime,
      durationSeconds: row.durationSeconds,
      mode: FocusModeX.fromStorage(row.mode),
      eventId: row.eventId,
      createdAt: row.createdAt,
    );
  }
}
