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
    required this.reminderType,
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
  final ReminderType reminderType;
  final int focusedSeconds;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTodo => taskType == TaskType.todo;
  bool get isSchedule => taskType == TaskType.schedule;
  bool get hasDate => date.isNotEmpty;
  bool get isNoTimeTodo => isTodo && todoTimeMode == TodoTimeMode.noTime;

  /// Appears on the home Timeline (schedules + time-block todos with date).
  bool get showsInTimeline =>
      hasDate &&
      (isSchedule || (isTodo && todoTimeMode == TodoTimeMode.timeBlock));

  /// Appears in Todo list (all todo modes).
  bool get showsInTodoList => isTodo;

  /// Todos tied to a specific calendar day on Home.
  bool showsOnHomeDate(String dateKey) =>
      showsInTodoList && hasDate && date == dateKey;

  /// Visual completion state for timeline rows.
  bool isTimelineDone(DateTime now) {
    if (isSchedule) return isCompleted || _isPastEnd(now);
    if (isTodo && todoTimeMode == TodoTimeMode.timeBlock) return isCompleted;
    return false;
  }

  /// Todo completion for stats and todo list (manual only).
  bool isTodoDone() => isTodo && isCompleted;

  bool _isPastEnd(DateTime now) {
    if (!hasDate || startTime.isEmpty || endTime.isEmpty) return false;
    final end = _dateTimeAt(endTime);
    return !now.isBefore(end);
  }

  DateTime _dateTimeAt(String time) {
    if (!hasDate || time.isEmpty) return DateTime.now();
    final parts = time.split(':');
    final d = DateTime.parse(date);
    return DateTime(d.year, d.month, d.day, int.parse(parts[0]), int.parse(parts[1]));
  }

  DateTime get startDateTime => _dateTimeAt(startTime);
  DateTime get endDateTime => _dateTimeAt(endTime);

  String get timeLabel {
    if (isNoTimeTodo) return '';
    if (isSchedule || todoTimeMode == TodoTimeMode.timeBlock) {
      if (startTime.isEmpty || endTime.isEmpty) return '';
      return '$startTime – $endTime';
    }
    if (todoTimeMode == TodoTimeMode.deadline) {
      return endTime.isEmpty ? '' : 'Deadline $endTime';
    }
    return '';
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
    ReminderType? reminderType,
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
      reminderType: reminderType ?? this.reminderType,
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
    this.reminderType = ReminderType.none,
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
  final ReminderType reminderType;
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
