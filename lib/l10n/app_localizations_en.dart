// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'JUJU Schedule';

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
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsFocus => 'Focus';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsGeneral => 'General';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsStatusEnabled => 'Enabled';

  @override
  String get settingsStatusDisabled => 'Disabled';

  @override
  String settingsVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get settingsDefaultCountdown => 'Default Countdown';

  @override
  String get settingsDefaultDisplayMode => 'Default Display Mode';

  @override
  String get settingsDisplayModeHour => 'Hour';

  @override
  String get settingsDisplayModeMinute => 'Minute';

  @override
  String get settingsKeepScreenAwake => 'Keep Screen Awake';

  @override
  String get settingsKeepScreenAwakeHint =>
      'Prevent screen sleep during an active focus session';

  @override
  String get settingsImmersiveModeHint =>
      'Long press the running timer to enter immersive mode.';

  @override
  String get settingsNotificationPermission => 'Notification Permission';

  @override
  String get settingsAppName => 'App Name';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsGitHub => 'GitHub';

  @override
  String get settingsGitHubCopied => 'GitHub link copied';

  @override
  String get settingsLicenses => 'Licenses';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get initialTimelineWelcomeTitle => '👋 Welcome to JUJU Schedule';

  @override
  String get initialTimelineAddTitle => '➕ Tap + at bottom right to add a task';

  @override
  String get initialTimelineEditTitle => '✏️ Swipe left or long-press to edit';

  @override
  String get initialTimelineReminderTitle =>
      '🔔 Set reminders when creating tasks';

  @override
  String get initialTimelineFocusTitle => '🍅 Start your first focus session';

  @override
  String get initialTodoThemeTitle => '🎨 Change theme color in Settings';

  @override
  String get initialTodoLanguageTitle => '🌐 Switch language in Settings';

  @override
  String get initialTodoStatsTitle =>
      '📊 View focus stats on the Statistics page';

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
  String get languageKo => '한국어';

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
  String get settingsAutostartPermission => 'Autostart';

  @override
  String get autostartPermissionGranted => 'Autostart enabled';

  @override
  String get autostartPermissionNotConfigured => 'Autostart not confirmed';

  @override
  String get autostartPermissionHint =>
      'On Xiaomi/Redmi devices, enable autostart or reminders may stop after swiping the app away.';

  @override
  String get requestAutostartPermission => 'Enable autostart';

  @override
  String get exactAlarmPermissionHint =>
      'Reminders need exact alarm permission to fire on time. Tap below to open system settings.';

  @override
  String get requestExactAlarmPermission => 'Allow exact alarms';

  @override
  String get batteryOptimizationHint =>
      'Reminders may not fire in the background if battery optimization is enabled. Allow unrestricted background activity for this app.';

  @override
  String get requestBatteryOptimization => 'Disable battery optimization';

  @override
  String pendingNotifications(Object count) {
    return '$count scheduled reminder(s)';
  }

  @override
  String get reminderSetupHint =>
      'Tap Reminder when creating a task to choose when to notify.';

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
  String titleTooLong(int max) {
    return 'Title must be at most $max characters.';
  }

  @override
  String noteTooLong(int max) {
    return 'Note must be at most $max characters.';
  }

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
  String get reminderNone => 'No reminder';

  @override
  String get reminderAtDueTime => 'At due time';

  @override
  String reminderMinutesBeforeDue(int count) {
    return '$count minutes before due time';
  }

  @override
  String reminderHoursBeforeDue(int count) {
    return '$count hours before due time';
  }

  @override
  String reminderDaysBeforeDue(int count) {
    return '$count days before due time';
  }

  @override
  String get reminderCustomOption => 'Custom…';

  @override
  String get reminderCustomTitle => 'Custom reminder';

  @override
  String get reminderEnterAmount => 'Amount';

  @override
  String get reminderUnitMinutes => 'Minutes';

  @override
  String get reminderUnitHours => 'Hours';

  @override
  String get reminderUnitDays => 'Days';

  @override
  String reminderSelectedCount(int count) {
    return '$count reminders selected';
  }

  @override
  String get done => 'Done';

  @override
  String timeUntilStart(String time) {
    return 'Starts in $time';
  }

  @override
  String get timeUntilStartNow => 'Starting now';

  @override
  String timeUntilStartMinutes(int count) {
    return 'in $count min';
  }

  @override
  String timeUntilStartHours(int count) {
    return 'in $count hr';
  }

  @override
  String timeUntilStartHoursMinutes(int hours, int minutes) {
    return 'in $hours hr $minutes min';
  }

  @override
  String timeUntilStartDays(int count) {
    return 'in $count days';
  }

  @override
  String timeUntilStartDaysHours(int days, int hours) {
    return 'in $days days $hours hr';
  }

  @override
  String get detailTimeUntilStart => 'Time until start';

  @override
  String get detailReminder => 'Reminder';

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
  String get focusSelectTask => 'Select Focus Task';

  @override
  String get focusTodayTasks => 'Today\'s Schedule & Tasks';

  @override
  String get focusNoTask => 'Uncategorized';

  @override
  String get focusCompletedTitle => 'Focus Completed 🎉';

  @override
  String get focusSummaryTask => 'Task';

  @override
  String get focusSummaryDuration => 'Duration';

  @override
  String get focusSummaryStart => 'Start Time';

  @override
  String get focusSummaryEnd => 'End Time';

  @override
  String get focusCustomDuration => 'Custom Duration';

  @override
  String get focusHoursLabel => 'Hours';

  @override
  String get focusMinutesFieldLabel => 'Minutes';

  @override
  String get focusAddPreset => 'Add';

  @override
  String get focusTapToToggleDisplay => 'Tap to switch display';

  @override
  String get focusDoneDelete => 'Done';

  @override
  String get focusCurrentTask => 'Select task';

  @override
  String get focusCustomTaskHint => 'Type a custom task name';

  @override
  String get focusUseCustomTask => 'Use';

  @override
  String get focusCurrentFocus => 'Current Focus';

  @override
  String get focusSelectTodo => 'Select Task';

  @override
  String get focusTaskModeCustom => 'Custom';

  @override
  String get focusImmersiveExit => 'Exit';

  @override
  String get focusLongPressImmersive => 'Long press timer for immersive mode';

  @override
  String get focusViewRecords => 'View focus records';

  @override
  String get focusRecordsTitle => 'Focus records';

  @override
  String get focusRecordsEmpty => 'No focus records yet';

  @override
  String get focusEditRecord => 'Edit focus record';

  @override
  String get focusRecordTaskLabel => 'Task name';

  @override
  String get focusRecordDate => 'Date';

  @override
  String get focusRecordStartTime => 'Start time';

  @override
  String get focusRecordEndTime => 'End time';

  @override
  String focusDurationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String focusDurationHours(int hours) {
    return '${hours}h';
  }

  @override
  String focusDurationMinutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get statsTitle => 'Statistics';

  @override
  String get statsDay => 'Day';

  @override
  String get statsWeek => 'Week';

  @override
  String get statsMonth => 'Month';

  @override
  String get statsYear => 'Year';

  @override
  String get statsOverview => 'Overview';

  @override
  String get statsCompleted => 'Completed';

  @override
  String get statsPending => 'Pending';

  @override
  String get statsFocusTime => 'Focus Time';

  @override
  String get statsFocusRanking => 'Focus Ranking';

  @override
  String get statsViewAll => 'View All >';

  @override
  String get statsViewDetails => 'View Details >';

  @override
  String get statsMonthlyFocus => 'Monthly Focus';

  @override
  String get statsThisWeek => 'This Week';

  @override
  String get statsLastWeek => 'Last Week';

  @override
  String get statsNextWeek => 'Next Week';

  @override
  String get statsFocus => 'Focus';

  @override
  String statsSessionsCount(int count) {
    return 'Sessions $count';
  }

  @override
  String statsSessionDetail(String start, String end, String duration) {
    return '$start–$end  $duration';
  }

  @override
  String get statsRankingEmpty => 'No focus sessions yet';

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
