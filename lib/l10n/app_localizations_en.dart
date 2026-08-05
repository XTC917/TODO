// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Soft Schedule';

  @override
  String get navHome => 'Home';

  @override
  String get navTodo => 'Todo';

  @override
  String get navFocus => 'Focus';

  @override
  String get navCalendar => 'Calendar';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accentColor => 'Accent Color';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Follow System';

  @override
  String get languageZh => '简体中文';

  @override
  String get languageEn => 'English';

  @override
  String get notifications => 'Notifications';

  @override
  String get enableReminders => 'Enable Reminders';

  @override
  String get notificationPermissionGranted => 'Notifications allowed';

  @override
  String get notificationPermissionDenied => 'Notifications not allowed';

  @override
  String get openNotificationSettings => 'Open notification settings';

  @override
  String get requestNotificationPermission => 'Allow notifications';

  @override
  String get remindersDisabledHint => 'Reminders are turned off in settings';

  @override
  String get exportDatabase => 'Export Database';

  @override
  String get importDatabase => 'Import Database';

  @override
  String get about => 'About';

  @override
  String aboutSubtitle(String version) {
    return 'Soft Schedule $version';
  }

  @override
  String get aboutLegalese =>
      'Personal schedule book\nData stored locally only';

  @override
  String exportSuccess(String path) {
    return 'Exported: $path';
  }

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get importTitle => 'Import Database';

  @override
  String get importMessage => 'This will replace all current data. Continue?';

  @override
  String get importSuccess => 'Import successful';

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get import => 'Import';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get copy => 'Copy';

  @override
  String get changeDate => 'Change date';

  @override
  String batchSelected(int count) {
    return 'Selected $count';
  }

  @override
  String get noTimeTasksCannotChangeDate => 'No-time tasks cannot change date.';

  @override
  String get backToToday => 'Back to Today';

  @override
  String get today => 'Today';

  @override
  String get swipeHint => '← swipe anywhere to change day →';

  @override
  String get timeline => 'Timeline';

  @override
  String get todaysTodo => 'Today\'s Todo';

  @override
  String get todoSection => 'Todo';

  @override
  String completed(int count) {
    return 'Completed ($count)';
  }

  @override
  String longTermTasks(int count) {
    return 'Long-term ($count)';
  }

  @override
  String get longTermTask => 'Long-term task';

  @override
  String get noTodosYet => 'No todos yet';

  @override
  String get noTodosForDay => 'No todos for this day';

  @override
  String get noTimelineItems => 'No timeline items for this day';

  @override
  String get noTodos => 'No todos';

  @override
  String loadFailed(String error) {
    return 'Load failed: $error';
  }

  @override
  String errorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get titleRequired => 'Please enter a task title.';

  @override
  String get saveFailedRetry => 'Save failed. Please try again.';

  @override
  String get confirmDeleteTitle => 'Delete';

  @override
  String get confirmDeleteMessage => 'Delete this item?';

  @override
  String get addTitle => 'Add';

  @override
  String get editTitle => 'Edit';

  @override
  String get titleLabel => 'Title';

  @override
  String get typeLabel => 'Type';

  @override
  String get taskTypeTodo => 'Todo';

  @override
  String get taskTypeSchedule => 'Schedule';

  @override
  String get timeModeLabel => 'Time mode';

  @override
  String get timeBlock => 'Block';

  @override
  String get deadline => 'Deadline';

  @override
  String get noTime => 'No time';

  @override
  String get dateLabel => 'Date';

  @override
  String get startLabel => 'Start';

  @override
  String get endLabel => 'End';

  @override
  String get deadlineLabel => 'Deadline';

  @override
  String get noteLabel => 'Note';

  @override
  String get moreOptions => 'More options';

  @override
  String get endTimeAfterStart => 'End time must be after start time';

  @override
  String get detailType => 'Type';

  @override
  String get detailDate => 'Date';

  @override
  String get detailTime => 'Time';

  @override
  String get detailNote => 'Note';

  @override
  String get detailTodo => 'Todo';

  @override
  String get detailSchedule => 'Schedule';

  @override
  String get markComplete => 'Mark complete';

  @override
  String get completedLabel => 'Completed';

  @override
  String get deadlineBadge => 'Deadline';

  @override
  String get relativeYesterday => 'Yesterday';

  @override
  String get relativeToday => 'Today';

  @override
  String get relativeTomorrow => 'Tomorrow';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get notificationUpcomingTodo => 'Upcoming todo';

  @override
  String get notificationUpcomingSchedule => 'Upcoming schedule';

  @override
  String schedulesCount(int count) {
    return '$count schedules';
  }

  @override
  String todosCount(int count) {
    return '$count todos';
  }

  @override
  String doneCount(int count) {
    return 'done $count';
  }

  @override
  String focusDuration(String duration) {
    return ' · Focus $duration';
  }

  @override
  String get exportDialogTitle => 'Export Database';

  @override
  String get importDialogTitle => 'Import Database';

  @override
  String get repeatOneTime => 'One Time';

  @override
  String get repeatDaily => 'Every Day';

  @override
  String get repeatWeekly => 'Every Week';

  @override
  String get repeatMonthly => 'Every Month';

  @override
  String get reminderLabel => 'Reminder';

  @override
  String get reminderNone => 'No Reminder';

  @override
  String get reminderAtTime => 'At Time';

  @override
  String get reminderMin5 => '5 min before';

  @override
  String get reminderMin10 => '10 min before';

  @override
  String get reminderMin15 => '15 min before';

  @override
  String get reminderMin30 => '30 min before';

  @override
  String get reminderHour1 => '1 hour before';

  @override
  String get focusTitle => 'Focus';

  @override
  String get focusPomodoro => 'Pomodoro';

  @override
  String get focusStopwatch => 'Stopwatch';

  @override
  String get focusStart => 'Start';

  @override
  String get focusPause => 'Pause';

  @override
  String get focusResume => 'Resume';

  @override
  String get focusEnd => 'End';

  @override
  String focusMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String focusCustom(int minutes) {
    return 'Custom $minutes';
  }

  @override
  String focusSaved(String duration) {
    return 'Saved $duration';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsDay => 'Day';

  @override
  String get statsWeek => 'Week';

  @override
  String get statsDailyFocus => 'Daily Focus';

  @override
  String get statsWeeklyFocus => 'Weekly Focus';

  @override
  String get statsDailyTodo => 'Daily Todo Completion';

  @override
  String get statsWeeklyTodo => 'Weekly Completion';

  @override
  String statsFocusLabel(String duration) {
    return 'Focus: $duration';
  }

  @override
  String statsTasksLabel(int done, int total) {
    return 'Tasks: $done/$total';
  }

  @override
  String statsProgressLabel(int percent) {
    return 'Progress: $percent%';
  }

  @override
  String deadlineTime(String time) {
    return 'Deadline $time';
  }
}
