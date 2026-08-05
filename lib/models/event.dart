import 'enums.dart';

/// Domain model for schedule blocks and todos.
class Event {
  const Event({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.note,
    required this.color,
    required this.taskType,
    required this.todoTimeMode,
    required this.isCompleted,
    required this.repeatType,
    this.repeatGroupId,
    this.reminderOffsetsSeconds = const [],
    required this.focusedSeconds,
    this.completedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String? note;
  final String color;
  final TaskType taskType;
  final TodoTimeMode todoTimeMode;
  final bool isCompleted;
  final RepeatType repeatType;
  final String? repeatGroupId;
  /// Seconds before [reminderAnchorDateTime] to fire. Empty = no reminder.
  final List<int> reminderOffsetsSeconds;
  final int focusedSeconds;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTodo => taskType == TaskType.todo;
  bool get isSchedule => taskType == TaskType.schedule;
  bool get hasDate => date.isNotEmpty;
  bool get isNoTimeTodo => isTodo && todoTimeMode == TodoTimeMode.noTime;
  bool get hasReminder => reminderOffsetsSeconds.isNotEmpty;

  /// Appears on the home Timeline (schedules + timed todos with date).
  bool get showsInTimeline =>
      hasDate &&
      (isSchedule ||
          (isTodo &&
              (todoTimeMode == TodoTimeMode.timeBlock ||
                  todoTimeMode == TodoTimeMode.deadline)));

  /// Sort key for timeline ordering.
  String get timelineSortKey {
    if (isTodo && todoTimeMode == TodoTimeMode.deadline) {
      return endTime.isEmpty ? '99:99' : endTime;
    }
    return startTime.isEmpty ? '99:99' : startTime;
  }

  bool get isDeadlineTodo =>
      isTodo && todoTimeMode == TodoTimeMode.deadline;

  bool get isTimeRangeTimeline =>
      isSchedule || (isTodo && todoTimeMode == TodoTimeMode.timeBlock);

  /// Appears in Todo list (all todo modes).
  bool get showsInTodoList => isTodo;

  /// Todos tied to a specific calendar day on Home.
  bool showsOnHomeDate(String dateKey) =>
      showsInTodoList && hasDate && date == dateKey;

  /// Visual completion state for timeline rows (user-controlled only).
  bool isTimelineDone(DateTime now) => isCompleted;

  /// Todo completion for stats and todo list (manual only).
  bool isTodoDone() => isTodo && isCompleted;

  DateTime _dateTimeAt(String time) {
    if (!hasDate || time.isEmpty) return DateTime.now();
    final parts = time.split(':');
    final d = DateTime.parse(date);
    return DateTime(d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime get startDateTime => _dateTimeAt(startTime);
  DateTime get endDateTime => _dateTimeAt(endTime);

  /// When reminders should fire (start for schedules/blocks, deadline for due todos).
  DateTime? get reminderAnchorDateTime {
    if (!hasDate || isNoTimeTodo) return null;
    if (isTodo && todoTimeMode == TodoTimeMode.deadline) {
      return endTime.isEmpty ? null : endDateTime;
    }
    return startTime.isEmpty ? null : startDateTime;
  }

  String get dateLabel {
    if (!hasDate) return '';
    return date;
  }

  Event copyWith({
    int? id,
    String? title,
    String? date,
    String? startTime,
    String? endTime,
    String? note,
    bool clearNote = false,
    String? color,
    TaskType? taskType,
    TodoTimeMode? todoTimeMode,
    bool? isCompleted,
    RepeatType? repeatType,
    String? repeatGroupId,
    bool clearRepeatGroupId = false,
    List<int>? reminderOffsetsSeconds,
    bool clearReminderOffsets = false,
    int? focusedSeconds,
    DateTime? completedAt,
    bool clearCompletedAt = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      note: clearNote ? null : (note ?? this.note),
      color: color ?? this.color,
      taskType: taskType ?? this.taskType,
      todoTimeMode: todoTimeMode ?? this.todoTimeMode,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatType: repeatType ?? this.repeatType,
      repeatGroupId: clearRepeatGroupId ? null : (repeatGroupId ?? this.repeatGroupId),
      reminderOffsetsSeconds: clearReminderOffsets
          ? const []
          : (reminderOffsetsSeconds ?? this.reminderOffsetsSeconds),
      focusedSeconds: focusedSeconds ?? this.focusedSeconds,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class EventDraft {
  const EventDraft({
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.note,
    required this.color,
    this.taskType = TaskType.todo,
    this.todoTimeMode = TodoTimeMode.timeBlock,
    this.repeatType = RepeatType.oneTime,
    this.repeatGroupId,
    this.reminderOffsetsSeconds = const [],
  });

  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String? note;
  final String color;
  final TaskType taskType;
  final TodoTimeMode todoTimeMode;
  final RepeatType repeatType;
  final String? repeatGroupId;
  final List<int> reminderOffsetsSeconds;
}

class FocusRecord {
  const FocusRecord({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    required this.mode,
    this.eventId,
    required this.createdAt,
  });

  final int id;
  final String date;
  final String startTime;
  final String endTime;
  final int durationSeconds;
  final FocusMode mode;
  final int? eventId;
  final DateTime createdAt;
}

class FocusLaunchConfig {
  const FocusLaunchConfig({
    required this.eventId,
    this.mode = FocusMode.pomodoro,
    this.durationMinutes = 25,
    this.autoStart = true,
  });

  final int eventId;
  final FocusMode mode;
  final int durationMinutes;
  final bool autoStart;
}

class DaySummary {
  const DaySummary({
    required this.focusSeconds,
    required this.scheduleTotal,
    required this.todoCompleted,
    required this.todoTotal,
  });

  final int focusSeconds;
  final int scheduleTotal;
  final int todoCompleted;
  final int todoTotal;

  double get progress => todoTotal == 0 ? 0 : todoCompleted / todoTotal;
}
