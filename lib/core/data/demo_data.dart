import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../utils/date_time_formats.dart';

/// Demo events use negative IDs and are never persisted to the database.
const demoScheduleIdStart = -1;
const demoTodoIdStart = -101;

bool isDemoEventId(int id) => id < 0;

bool isDemoEvent(Event event) => isDemoEventId(event.id);

int compareDemoFirst(Event a, Event b) {
  final aDemo = isDemoEventId(a.id);
  final bDemo = isDemoEventId(b.id);
  if (aDemo != bDemo) return aDemo ? -1 : 1;
  return 0;
}

List<Event> mergeDemoFirst(List<Event> demo, List<Event> user) {
  return [...demo, ...user];
}

List<Event> demoScheduleEventsForDate(AppLocalizations l10n, String dateKey) {
  final today = DateTimeFormats.formatDate(DateTime.now());
  if (dateKey != today) return const [];

  return [
    _schedule(
      id: demoScheduleIdStart,
      title: l10n.demoScheduleWelcomeTitle,
      note: l10n.demoScheduleWelcomeNote,
      date: dateKey,
      start: '09:00',
      end: '09:30',
    ),
    _schedule(
      id: demoScheduleIdStart - 1,
      title: l10n.demoScheduleAddTitle,
      note: l10n.demoScheduleAddNote,
      date: dateKey,
      start: '10:00',
      end: '10:30',
    ),
    _schedule(
      id: demoScheduleIdStart - 2,
      title: l10n.demoScheduleDetailTitle,
      note: l10n.demoScheduleDetailNote,
      date: dateKey,
      start: '11:00',
      end: '11:30',
    ),
    _schedule(
      id: demoScheduleIdStart - 3,
      title: l10n.demoScheduleSwipeTitle,
      note: l10n.demoScheduleSwipeNote,
      date: dateKey,
      start: '13:00',
      end: '13:30',
    ),
    _schedule(
      id: demoScheduleIdStart - 4,
      title: l10n.demoScheduleReminderTitle,
      note: l10n.demoScheduleReminderNote,
      date: dateKey,
      start: '14:00',
      end: '14:30',
      reminderOffsetsSeconds: const [0, 300],
    ),
    _schedule(
      id: demoScheduleIdStart - 5,
      title: l10n.demoScheduleHideTitle,
      note: l10n.demoScheduleHideNote,
      date: dateKey,
      start: '15:00',
      end: '15:30',
    ),
  ];
}

List<Event> demoTodos(AppLocalizations l10n) {
  return [
    _todo(
      id: demoTodoIdStart,
      title: l10n.demoTodoWelcomeTitle,
      completed: true,
    ),
    _todo(id: demoTodoIdStart - 1, title: l10n.demoTodoAddTitle),
    _todo(id: demoTodoIdStart - 2, title: l10n.demoTodoSwipeTitle),
    _todo(id: demoTodoIdStart - 3, title: l10n.demoTodoThemeTitle),
    _todo(id: demoTodoIdStart - 4, title: l10n.demoTodoLanguageTitle),
    _todo(id: demoTodoIdStart - 5, title: l10n.demoTodoFocusTitle),
    _todo(id: demoTodoIdStart - 6, title: l10n.demoTodoStatsTitle),
    _todo(id: demoTodoIdStart - 7, title: l10n.demoTodoHideTitle),
  ];
}

Event _schedule({
  required int id,
  required String title,
  required String note,
  required String date,
  required String start,
  required String end,
  List<int> reminderOffsetsSeconds = const [],
}) {
  return _baseEvent(
    id: id,
    title: title,
    note: note,
    date: date,
    startTime: start,
    endTime: end,
    taskType: TaskType.schedule,
    todoTimeMode: TodoTimeMode.noTime,
    reminderOffsetsSeconds: reminderOffsetsSeconds,
  );
}

Event _todo({
  required int id,
  required String title,
  bool completed = false,
}) {
  return _baseEvent(
    id: id,
    title: title,
    date: '',
    startTime: '',
    endTime: '',
    taskType: TaskType.todo,
    todoTimeMode: TodoTimeMode.noTime,
    isCompleted: completed,
    completedAt: completed ? _demoTimestamp : null,
  );
}

final _demoTimestamp = DateTime(2024, 1, 1);

Event _baseEvent({
  required int id,
  required String title,
  String? note,
  required String date,
  required String startTime,
  required String endTime,
  required TaskType taskType,
  required TodoTimeMode todoTimeMode,
  bool isCompleted = false,
  DateTime? completedAt,
  List<int> reminderOffsetsSeconds = const [],
}) {
  return Event(
    id: id,
    title: title,
    date: date,
    startTime: startTime,
    endTime: endTime,
    note: note,
    color: 'blue',
    taskType: taskType,
    todoTimeMode: todoTimeMode,
    isCompleted: isCompleted,
    repeatType: RepeatType.oneTime,
    reminderOffsetsSeconds: reminderOffsetsSeconds,
    focusedSeconds: 0,
    completedAt: completedAt,
    createdAt: _demoTimestamp,
    updatedAt: _demoTimestamp,
  );
}
