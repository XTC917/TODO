import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/repeat_occurrence_utils.dart';
import 'package:soft_schedule/database/app_database.dart';
import 'package:soft_schedule/models/event.dart';

EventRow _row({
  required int id,
  required String date,
  required String repeatType,
  String title = 'Standup',
  String? reminderOffsetsJson,
  int? reminderOffsetSeconds,
  bool isCompleted = false,
}) {
  final now = DateTime(2026, 1, 1);
  return EventRow(
    id: id,
    title: title,
    date: date,
    startTime: '09:00',
    endTime: '10:00',
    note: null,
    color: 'blue',
    taskType: 'schedule',
    todoTimeMode: 'timeBlock',
    isCompleted: isCompleted,
    repeatType: repeatType,
    repeatGroupId: 'g1',
    repeatUntil: null,
    reminderOffsetSeconds: reminderOffsetSeconds,
    reminderOffsetsJson: reminderOffsetsJson,
    focusedSeconds: 0,
    completedAt: null,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final master = _row(
    id: 1,
    date: '2026-01-05',
    repeatType: 'weekly',
    reminderOffsetsJson: '[0]',
  );

  test('custom reminder override is not treated as redundant copy', () {
    final override = _row(
      id: 2,
      date: '2026-01-12',
      repeatType: 'oneTime',
      reminderOffsetsJson: '[300]',
    );
    expect(
      RepeatOccurrenceUtils.isRedundantMaterializedCopy(
        master: master,
        row: override,
      ),
      isFalse,
    );
  });

  test('identical legacy materialized clone is redundant', () {
    final clone = _row(
      id: 3,
      date: '2026-01-12',
      repeatType: 'oneTime',
      reminderOffsetsJson: '[0]',
    );
    expect(
      RepeatOccurrenceUtils.isRedundantMaterializedCopy(
        master: master,
        row: clone,
      ),
      isTrue,
    );
  });
}
