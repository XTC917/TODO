import 'package:flutter/material.dart';

import '../../features/schedule/event_form_page.dart';
import '../../models/enums.dart';
import 'parsed_task.dart';

/// Opens [EventFormPage] when the user switches task type on the quick-add preview.
/// Does not touch the database or notification scheduler.
class QuickAddFormBridge {
  QuickAddFormBridge._();

  static EventFormPage formPageForTypeSwitch({
    required ParsedTask parsed,
    required TaskType targetType,
    DateTime? fallbackDate,
    TaskType? lockedForceTaskType,
  }) {
    final effectiveType = lockedForceTaskType ?? targetType;

    if (effectiveType == TaskType.schedule) {
      return EventFormPage(
        initialDate: parsed.date ?? fallbackDate,
        initialTitle: parsed.title,
        initialStartTime: parsed.startTime,
        initialEndTime: parsed.endTime,
        forceTaskType: TaskType.schedule,
        forceTodoTimeMode: TodoTimeMode.timeBlock,
        initialReminderOffsetsSeconds:
            parsed.startTime != null && parsed.hasReminders
                ? parsed.reminderOffsetsSeconds
                : const [],
      );
    }

    // Todo: keep title + date; drop schedule-only times/reminders when unsupported.
    final hasTimedTodo = parsed.startTime != null;
    final todoMode = parsed.date == null
        ? TodoTimeMode.noTime
        : (hasTimedTodo ? TodoTimeMode.timeBlock : TodoTimeMode.deadline);

    return EventFormPage(
      initialDate: parsed.date ?? fallbackDate,
      initialTitle: parsed.title,
      initialStartTime: hasTimedTodo ? parsed.startTime : null,
      initialEndTime: hasTimedTodo ? parsed.endTime : null,
      forceTaskType: TaskType.todo,
      forceTodoTimeMode: todoMode,
      initialReminderOffsetsSeconds:
          hasTimedTodo && parsed.hasReminders
              ? parsed.reminderOffsetsSeconds
              : const [],
    );
  }
}
