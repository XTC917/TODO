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

  test('reminderSource skips a date that has an only-this override', () {
    final master = _master(id: 1, date: '2026-01-05');
    final override = master.copyWith(
      id: 42,
      title: 'Renamed standup',
      date: '2026-01-12',
      repeatType: RepeatType.oneTime,
      reminderOffsetsSeconds: const [0],
    );
    final series = [master, override];
    final from = DateTime(2026, 1, 12, 8);

    final masterSource = RepeatExpander.reminderSource(
      master,
      series,
      from: from,
    );
    final overrideSource = RepeatExpander.reminderSource(
      override,
      series,
      from: from,
    );

    expect(masterSource, isNotNull);
    expect(masterSource!.id, 1);
    expect(masterSource.title, 'Weekly standup');
    expect(masterSource.date, '2026-01-19');
    expect(overrideSource, isNotNull);
    expect(overrideSource!.id, 42);
    expect(overrideSource.title, 'Renamed standup');
    expect(overrideSource.date, '2026-01-12');
  });

  test('reminderSource keeps next occurrence when series was renamed', () {
    final master = _master(id: 1, date: '2026-01-05').copyWith(
      title: 'Renamed standup',
    );
    final source = RepeatExpander.reminderSource(
      master,
      [master],
      from: DateTime(2026, 1, 12, 8),
    );

    expect(source, isNotNull);
    expect(source!.title, 'Renamed standup');
    expect(source.date, '2026-01-12');
  });

  test('reminderSource ignores skip-marker rows', () {
    final skip = _master(id: 9, date: '2026-01-12').copyWith(
      title: kRepeatSkipMarker,
      repeatType: RepeatType.oneTime,
    );
    expect(
      RepeatExpander.reminderSource(
        skip,
        [skip],
        from: DateTime(2026, 1, 12, 8),
      ),
      isNull,
    );
  });
}
