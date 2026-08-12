import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/date_time_formats.dart';
import 'package:soft_schedule/core/utils/focus_task_picker_items.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

Event _event({
  required int id,
  required String title,
  required String date,
  TaskType taskType = TaskType.todo,
  TodoTimeMode todoTimeMode = TodoTimeMode.deadline,
  bool isCompleted = false,
  RepeatType repeatType = RepeatType.oneTime,
  String? repeatGroupId,
}) {
  final now = DateTime(2026, 1, 1);
  return Event(
    id: id,
    title: title,
    date: date,
    startTime: '09:00',
    endTime: '10:00',
    color: 'blue',
    taskType: taskType,
    todoTimeMode: todoTimeMode,
    isCompleted: isCompleted,
    repeatType: repeatType,
    repeatGroupId: repeatGroupId,
    focusedSeconds: 0,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  final today = DateTime(2026, 8, 11);

  test('groups tasks in required section order', () {
    final sections = FocusTaskPickerItems.build(
      [
        _event(id: 1, title: 'Today schedule', date: '2026-08-11', taskType: TaskType.schedule),
        _event(id: 2, title: 'Today todo', date: '2026-08-11'),
        _event(id: 3, title: 'Long term', date: '2026-08-11', todoTimeMode: TodoTimeMode.noTime),
        _event(id: 4, title: 'Tomorrow todo', date: '2026-08-12'),
      ],
      today: today,
    );

    expect(
      sections.map((s) => s.kind).toList(),
      [
        FocusTaskPickerSectionKind.todaySchedules,
        FocusTaskPickerSectionKind.todayTodos,
        FocusTaskPickerSectionKind.longTermTodos,
        FocusTaskPickerSectionKind.otherDateTodos,
      ],
    );
    expect(sections[0].items.map((e) => e.title), ['Today schedule']);
    expect(sections[1].items.map((e) => e.title), ['Today todo']);
    expect(sections[2].items.map((e) => e.title), ['Long term']);
    expect(sections[3].items.map((e) => e.title), ['Tomorrow todo']);
  });

  test('other date todos sort by nearest date first', () {
    final sections = FocusTaskPickerItems.build(
      [
        _event(id: 1, title: 'Far future', date: '2026-09-01'),
        _event(id: 2, title: 'Yesterday', date: '2026-08-10'),
        _event(id: 3, title: 'Tomorrow', date: '2026-08-12'),
      ],
      today: today,
    );

    final other = sections
        .firstWhere((s) => s.kind == FocusTaskPickerSectionKind.otherDateTodos)
        .items;
    expect(other.map((e) => e.title), ['Yesterday', 'Tomorrow', 'Far future']);
  });

  test('recurring todos in other dates show only one nearest occurrence', () {
    final groupId = 'daily-group';
    final sections = FocusTaskPickerItems.build(
      [
        _event(
          id: 10,
          title: 'Daily review',
          date: '2026-08-01',
          repeatType: RepeatType.daily,
          repeatGroupId: groupId,
        ),
      ],
      today: today,
    );

    final other = sections
        .firstWhere((s) => s.kind == FocusTaskPickerSectionKind.otherDateTodos)
        .items;
    expect(other, hasLength(1));
    expect(other.single.title, 'Daily review');
    expect(other.single.date, '2026-08-10');
  });

  test('excludes completed and today todos from other dates', () {
    final sections = FocusTaskPickerItems.build(
      [
        _event(id: 1, title: 'Done', date: '2026-08-12', isCompleted: true),
        _event(id: 2, title: 'Today', date: DateTimeFormats.formatDate(today)),
      ],
      today: today,
    );

    final other = sections
        .firstWhere((s) => s.kind == FocusTaskPickerSectionKind.otherDateTodos)
        .items;
    expect(other, isEmpty);
  });
}
