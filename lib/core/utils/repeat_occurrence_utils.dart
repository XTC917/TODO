import '../../database/app_database.dart';
import '../../models/event.dart';

/// Helpers for recurring-series single-occurrence rows stored as one-time copies.
class RepeatOccurrenceUtils {
  RepeatOccurrenceUtils._();

  /// True when [row] is an old bulk-materialized clone of [master], not a user edit.
  static bool isRedundantMaterializedCopy({
    required EventRow master,
    required EventRow row,
  }) {
    if (row.title == kRepeatSkipMarker) return false;
    if (row.repeatType != 'oneTime') return false;
    if (row.isCompleted) return false;
    if (row.title != master.title) return false;
    if (row.startTime != master.startTime) return false;
    if (row.endTime != master.endTime) return false;
    if (row.reminderOffsetsJson != master.reminderOffsetsJson) return false;
    if (row.reminderOffsetSeconds != master.reminderOffsetSeconds) return false;
    if (row.note != master.note) return false;
    if (row.color != master.color) return false;
    if (row.todoTimeMode != master.todoTimeMode) return false;
    if (row.taskType != master.taskType) return false;
    return true;
  }
}
