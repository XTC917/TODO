import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/event.dart';
import '../utils/date_time_formats.dart';
import '../utils/parsed_task.dart';
import '../utils/natural_language_parser.dart';
import '../utils/theme_event_color.dart';

String _formatTime(TimeOfDay time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

TimeOfDay _endFromStart(TimeOfDay start) {
  final minutes = start.hour * 60 + start.minute + 60;
  return TimeOfDay(hour: (minutes ~/ 60) % 24, minute: minutes % 60);
}

/// Builds an [EventDraft] using the same field rules as [EventFormPage._resolveFields].
EventDraft parsedTaskToDraft(ParsedTask parsed, WidgetRef ref) {
  final color = themeEventColorHex(ref);
  final taskType = parsed.taskType;
  final todoMode =
      taskType == TaskType.schedule ? TodoTimeMode.timeBlock : parsed.todoTimeMode;
  final reminders = parsed.reminderOffsetsSeconds;

  if (todoMode == TodoTimeMode.noTime || parsed.date == null) {
    return EventDraft(
      title: parsed.title,
      date: '',
      startTime: '',
      endTime: '',
      color: color,
      taskType: TaskType.todo,
      todoTimeMode: TodoTimeMode.noTime,
    );
  }

  final dateStr = DateTimeFormats.formatDate(parsed.date!);

  if (taskType == TaskType.schedule ||
      todoMode == TodoTimeMode.timeBlock) {
    if (parsed.startTime == null) {
      return EventDraft(
        title: parsed.title,
        date: dateStr,
        startTime: '',
        endTime: '',
        color: color,
        taskType: taskType,
        todoTimeMode: taskType == TaskType.schedule
            ? TodoTimeMode.timeBlock
            : todoMode,
        reminderOffsetsSeconds: const [],
      );
    }
    final start = parsed.startTime!;
    final end = parsed.endTime ?? _endFromStart(start);
    return EventDraft(
      title: parsed.title,
      date: dateStr,
      startTime: _formatTime(start),
      endTime: _formatTime(end),
      color: color,
      taskType: taskType,
      todoTimeMode: TodoTimeMode.timeBlock,
      reminderOffsetsSeconds: reminders,
    );
  }

  if (todoMode == TodoTimeMode.deadline) {
    final end = parsed.endTime ?? parsed.startTime;
    return EventDraft(
      title: parsed.title,
      date: dateStr,
      startTime: '00:00',
      endTime: end == null ? '' : _formatTime(end),
      color: color,
      taskType: TaskType.todo,
      todoTimeMode: TodoTimeMode.deadline,
      reminderOffsetsSeconds: end == null ? const [] : reminders,
    );
  }

  return EventDraft(
    title: parsed.title,
    date: dateStr,
    startTime: '00:00',
    endTime: '00:00',
    color: color,
    taskType: TaskType.todo,
    todoTimeMode: todoMode,
    reminderOffsetsSeconds: reminders,
  );
}
