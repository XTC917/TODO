import 'package:flutter/material.dart';

import '../../features/schedule/event_form_page.dart';
import '../../models/enums.dart';
import 'parsed_task.dart';

/// Resolved field values to prefill [EventFormPage] from a [ParsedTask].
class QuickAddPrefill {
  const QuickAddPrefill({
    required this.date,
    required this.title,
    this.startTime,
    this.endTime,
    this.deadline,
    required this.taskType,
    required this.todoTimeMode,
    required this.reminderOffsetsSeconds,
  });

  final DateTime? date;
  final String title;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TimeOfDay? deadline;
  final TaskType taskType;
  final TodoTimeMode todoTimeMode;
  final List<int> reminderOffsetsSeconds;

  factory QuickAddPrefill.fromParsed({
    required ParsedTask parsed,
    TaskType? taskTypeOverride,
    DateTime? fallbackDate,
  }) {
    final taskType = taskTypeOverride ?? parsed.taskType;
    final todoMode = QuickAddFormBridge.effectiveTodoMode(parsed, taskType);
    final times = QuickAddFormBridge.prefillTimes(parsed, taskType, todoMode);
    final reminders = QuickAddFormBridge.prefillReminders(
      parsed,
      taskType,
      todoMode,
      times,
    );

    TimeOfDay? deadline;
    if (taskType == TaskType.todo && todoMode == TodoTimeMode.deadline) {
      deadline = times.end;
    }

    return QuickAddPrefill(
      date: parsed.date ?? fallbackDate,
      title: parsed.title,
      startTime: times.start,
      endTime: times.end,
      deadline: deadline,
      taskType: taskType,
      todoTimeMode: todoMode,
      reminderOffsetsSeconds: reminders,
    );
  }
}

/// Maps quick-add parse results onto [EventFormPage] without writing to DB.
class QuickAddFormBridge {
  QuickAddFormBridge._();

  static EventFormPage formPageFromParsed({
    required ParsedTask parsed,
    TaskType? taskTypeOverride,
    DateTime? fallbackDate,
  }) {
    final prefill = QuickAddPrefill.fromParsed(
      parsed: parsed,
      taskTypeOverride: taskTypeOverride,
      fallbackDate: fallbackDate,
    );

    return EventFormPage(
      initialDate: prefill.date,
      initialTitle: prefill.title,
      initialStartTime: prefill.startTime,
      initialEndTime: prefill.deadline ?? prefill.endTime,
      initialTaskType: prefill.taskType,
      initialTodoTimeMode:
          prefill.taskType == TaskType.todo ? prefill.todoTimeMode : null,
      initialReminderOffsetsSeconds: prefill.reminderOffsetsSeconds,
    );
  }

  /// Preview-only: switch task type without leaving [QuickAddPage].
  static ParsedTask parsedForTaskType(ParsedTask parsed, TaskType taskType) {
    final prefill = QuickAddPrefill.fromParsed(
      parsed: parsed,
      taskTypeOverride: taskType,
    );
    return ParsedTask(
      rawInput: parsed.rawInput,
      title: prefill.title,
      date: prefill.date,
      startTime: prefill.startTime,
      endTime: prefill.todoTimeMode == TodoTimeMode.deadline
          ? prefill.deadline
          : prefill.endTime,
      taskType: prefill.taskType,
      todoTimeMode: prefill.todoTimeMode,
      reminderOffsetsSeconds: prefill.reminderOffsetsSeconds,
    );
  }

  static TodoTimeMode effectiveTodoMode(ParsedTask parsed, TaskType taskType) {
    if (taskType == TaskType.schedule) return TodoTimeMode.timeBlock;
    if (parsed.todoTimeMode == TodoTimeMode.deadline ||
        (parsed.endTime != null && parsed.startTime == null)) {
      return TodoTimeMode.deadline;
    }
    if (parsed.taskType == taskType) return parsed.todoTimeMode;
    if (parsed.startTime != null) return TodoTimeMode.timeBlock;
    if (parsed.endTime != null) return TodoTimeMode.deadline;
    if (parsed.date != null) return TodoTimeMode.deadline;
    return TodoTimeMode.noTime;
  }

  static ({TimeOfDay? start, TimeOfDay? end}) prefillTimes(
    ParsedTask parsed,
    TaskType taskType,
    TodoTimeMode todoMode,
  ) {
    if (todoMode == TodoTimeMode.noTime) {
      return (start: null, end: null);
    }

    if (parsed.date == null &&
        todoMode == TodoTimeMode.deadline &&
        parsed.endTime != null) {
      return (start: null, end: parsed.endTime);
    }

    if (parsed.date == null && todoMode == TodoTimeMode.timeBlock) {
      return (start: null, end: null);
    }

    if (taskType == TaskType.schedule || todoMode == TodoTimeMode.timeBlock) {
      return (start: parsed.startTime, end: parsed.endTime);
    }

    if (todoMode == TodoTimeMode.deadline) {
      final end = parsed.endTime ?? parsed.startTime;
      return (start: null, end: end);
    }

    return (start: null, end: null);
  }

  static List<int> prefillReminders(
    ParsedTask parsed,
    TaskType taskType,
    TodoTimeMode todoMode,
    ({TimeOfDay? start, TimeOfDay? end}) times,
  ) {
    if (!parsed.hasReminders) return const [];

    if (taskType == TaskType.schedule || todoMode == TodoTimeMode.timeBlock) {
      return times.start != null ? parsed.reminderOffsetsSeconds : const [];
    }
    if (todoMode == TodoTimeMode.deadline) {
      return times.end != null ? parsed.reminderOffsetsSeconds : const [];
    }
    return const [];
  }
}
