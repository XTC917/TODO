import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/repeat_expander.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

Event _master({
  required int id,
  required String date,
  bool completed = false,
  String? note,
  String? repeatUntil,
}) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: id,
    title: 'Weekly standup',
    date: date,
    startTime: '09:00',
    endTime: '10:00',
    color: 'blue',
    taskType: TaskType.schedule,
    todoTimeMode: TodoTimeMode.timeBlock,
    isCompleted: completed,
    repeatType: RepeatType.weekly,
    repeatGroupId: 'group-1',
    repeatUntil: repeatUntil,
    note: note,
    focusedSeconds: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  test('virtual repeat instances do not inherit master completion', () {
    final master = _master(id: 1, date: '2026-01-05', completed: true);
    final expanded = RepeatExpander.expandForDate(
      [master],
      DateTime(2026, 1, 12),
    );

    expect(expanded, hasLength(1));
    expect(expanded.single.date, '2026-01-12');
    expect(expanded.single.isCompleted, isFalse);
    expect(expanded.single.completedAt, isNull);
  });

  test('repeatUntil is not exposed on virtual instances', () {
    final master = _master(
      id: 1,
      date: '2026-01-05',
      repeatUntil: '2026-02-01',
      note: 'Bring slides',
    );
    final expanded = RepeatExpander.expandForDate(
      [master],
      DateTime(2026, 1, 12),
    );

    expect(expanded.single.repeatUntil, isNull);
    expect(expanded.single.userNote, 'Bring slides');
  });
}
