import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ko'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'JUJU Schedule'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get navTodo;

  /// No description provided for @navFocus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get navFocus;

  /// No description provided for @navCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get navCalendar;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @accentColor.
  ///
  /// In en, this message translates to:
  /// **'Accent Color'**
  String get accentColor;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Follow System'**
  String get languageSystem;

  /// No description provided for @languageZh.
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageZh;

  /// No description provided for @languageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageKo.
  ///
  /// In en, this message translates to:
  /// **'한국어'**
  String get languageKo;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @enableReminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get enableReminders;

  /// No description provided for @notificationPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'Notifications allowed'**
  String get notificationPermissionGranted;

  /// No description provided for @notificationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Notifications not allowed'**
  String get notificationPermissionDenied;

  /// No description provided for @openNotificationSettings.
  ///
  /// In en, this message translates to:
  /// **'Open notification settings'**
  String get openNotificationSettings;

  /// No description provided for @requestNotificationPermission.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get requestNotificationPermission;

  /// No description provided for @testNotificationNow.
  ///
  /// In en, this message translates to:
  /// **'Send test notification'**
  String get testNotificationNow;

  /// No description provided for @testNotificationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Test notification sent'**
  String get testNotificationSuccess;

  /// No description provided for @testNotificationFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send notification. Check permission and system settings.'**
  String get testNotificationFailed;

  /// No description provided for @pendingNotifications.
  ///
  /// In en, this message translates to:
  /// **'{count} scheduled reminder(s)'**
  String pendingNotifications(Object count);

  /// No description provided for @reminderSetupHint.
  ///
  /// In en, this message translates to:
  /// **'Tap Reminder when creating a task to choose when to notify.'**
  String get reminderSetupHint;

  /// No description provided for @remindersDisabledHint.
  ///
  /// In en, this message translates to:
  /// **'Reminders are turned off in settings'**
  String get remindersDisabledHint;

  /// No description provided for @exportDatabase.
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get exportDatabase;

  /// No description provided for @importDatabase.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importDatabase;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Soft Schedule {version}'**
  String aboutSubtitle(String version);

  /// No description provided for @aboutLegalese.
  ///
  /// In en, this message translates to:
  /// **'Personal schedule book\nData stored locally only'**
  String get aboutLegalese;

  /// No description provided for @exportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Exported: {path}'**
  String exportSuccess(String path);

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importTitle;

  /// No description provided for @importMessage.
  ///
  /// In en, this message translates to:
  /// **'This will replace all current data. Continue?'**
  String get importMessage;

  /// No description provided for @importSuccess.
  ///
  /// In en, this message translates to:
  /// **'Import successful'**
  String get importSuccess;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @import.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get import;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @changeDate.
  ///
  /// In en, this message translates to:
  /// **'Change date'**
  String get changeDate;

  /// No description provided for @batchSelected.
  ///
  /// In en, this message translates to:
  /// **'Selected {count}'**
  String batchSelected(int count);

  /// No description provided for @noTimeTasksCannotChangeDate.
  ///
  /// In en, this message translates to:
  /// **'No-time tasks cannot change date.'**
  String get noTimeTasksCannotChangeDate;

  /// No description provided for @backToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to Today'**
  String get backToToday;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @swipeHint.
  ///
  /// In en, this message translates to:
  /// **'← swipe anywhere to change day →'**
  String get swipeHint;

  /// No description provided for @timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get timeline;

  /// No description provided for @todaysTodo.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Todo'**
  String get todaysTodo;

  /// No description provided for @todoSection.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get todoSection;

  /// No description provided for @completed.
  ///
  /// In en, this message translates to:
  /// **'Completed ({count})'**
  String completed(int count);

  /// No description provided for @longTermTasks.
  ///
  /// In en, this message translates to:
  /// **'Long-term ({count})'**
  String longTermTasks(int count);

  /// No description provided for @longTermTask.
  ///
  /// In en, this message translates to:
  /// **'Long-term task'**
  String get longTermTask;

  /// No description provided for @noTodosYet.
  ///
  /// In en, this message translates to:
  /// **'No todos yet'**
  String get noTodosYet;

  /// No description provided for @noTodosForDay.
  ///
  /// In en, this message translates to:
  /// **'No todos for this day'**
  String get noTodosForDay;

  /// No description provided for @noTimelineItems.
  ///
  /// In en, this message translates to:
  /// **'No timeline items for this day'**
  String get noTimelineItems;

  /// No description provided for @noTodos.
  ///
  /// In en, this message translates to:
  /// **'No todos'**
  String get noTodos;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Load failed: {error}'**
  String loadFailed(String error);

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorGeneric(String error);

  /// No description provided for @titleRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a task title.'**
  String get titleRequired;

  /// No description provided for @titleTooLong.
  ///
  /// In en, this message translates to:
  /// **'Title must be at most {max} characters.'**
  String titleTooLong(int max);

  /// No description provided for @noteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Note must be at most {max} characters.'**
  String noteTooLong(int max);

  /// No description provided for @saveFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Save failed. Please try again.'**
  String get saveFailedRetry;

  /// No description provided for @confirmDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get confirmDeleteTitle;

  /// No description provided for @confirmDeleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete this item?'**
  String get confirmDeleteMessage;

  /// No description provided for @addTitle.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get addTitle;

  /// No description provided for @editTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editTitle;

  /// No description provided for @titleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleLabel;

  /// No description provided for @typeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get typeLabel;

  /// No description provided for @taskTypeTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get taskTypeTodo;

  /// No description provided for @taskTypeSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get taskTypeSchedule;

  /// No description provided for @timeModeLabel.
  ///
  /// In en, this message translates to:
  /// **'Time mode'**
  String get timeModeLabel;

  /// No description provided for @timeBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get timeBlock;

  /// No description provided for @deadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadline;

  /// No description provided for @noTime.
  ///
  /// In en, this message translates to:
  /// **'No time'**
  String get noTime;

  /// No description provided for @dateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// No description provided for @startLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get startLabel;

  /// No description provided for @endLabel.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get endLabel;

  /// No description provided for @deadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineLabel;

  /// No description provided for @noteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get noteLabel;

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// No description provided for @endTimeAfterStart.
  ///
  /// In en, this message translates to:
  /// **'End time must be after start time'**
  String get endTimeAfterStart;

  /// No description provided for @detailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailType;

  /// No description provided for @detailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get detailDate;

  /// No description provided for @detailTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get detailTime;

  /// No description provided for @detailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get detailNote;

  /// No description provided for @detailTodo.
  ///
  /// In en, this message translates to:
  /// **'Todo'**
  String get detailTodo;

  /// No description provided for @detailSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get detailSchedule;

  /// No description provided for @markComplete.
  ///
  /// In en, this message translates to:
  /// **'Mark complete'**
  String get markComplete;

  /// No description provided for @completedLabel.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completedLabel;

  /// No description provided for @deadlineBadge.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get deadlineBadge;

  /// No description provided for @relativeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get relativeYesterday;

  /// No description provided for @relativeToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get relativeToday;

  /// No description provided for @relativeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get relativeTomorrow;

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySun;

  /// No description provided for @notificationUpcomingTodo.
  ///
  /// In en, this message translates to:
  /// **'Upcoming todo'**
  String get notificationUpcomingTodo;

  /// No description provided for @notificationUpcomingSchedule.
  ///
  /// In en, this message translates to:
  /// **'Upcoming schedule'**
  String get notificationUpcomingSchedule;

  /// No description provided for @schedulesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} schedules'**
  String schedulesCount(int count);

  /// No description provided for @todosCount.
  ///
  /// In en, this message translates to:
  /// **'{count} todos'**
  String todosCount(int count);

  /// No description provided for @doneCount.
  ///
  /// In en, this message translates to:
  /// **'done {count}'**
  String doneCount(int count);

  /// No description provided for @focusDuration.
  ///
  /// In en, this message translates to:
  /// **' · Focus {duration}'**
  String focusDuration(String duration);

  /// No description provided for @exportDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Export Database'**
  String get exportDialogTitle;

  /// No description provided for @importDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Import Database'**
  String get importDialogTitle;

  /// No description provided for @repeatOneTime.
  ///
  /// In en, this message translates to:
  /// **'One Time'**
  String get repeatOneTime;

  /// No description provided for @repeatDaily.
  ///
  /// In en, this message translates to:
  /// **'Every Day'**
  String get repeatDaily;

  /// No description provided for @repeatWeekly.
  ///
  /// In en, this message translates to:
  /// **'Every Week'**
  String get repeatWeekly;

  /// No description provided for @repeatMonthly.
  ///
  /// In en, this message translates to:
  /// **'Every Month'**
  String get repeatMonthly;

  /// No description provided for @reminderLabel.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminderLabel;

  /// No description provided for @reminderNone.
  ///
  /// In en, this message translates to:
  /// **'No reminder'**
  String get reminderNone;

  /// No description provided for @reminderAtDueTime.
  ///
  /// In en, this message translates to:
  /// **'At due time'**
  String get reminderAtDueTime;

  /// No description provided for @reminderMinutesBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{count} minutes before due time'**
  String reminderMinutesBeforeDue(int count);

  /// No description provided for @reminderHoursBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{count} hours before due time'**
  String reminderHoursBeforeDue(int count);

  /// No description provided for @reminderDaysBeforeDue.
  ///
  /// In en, this message translates to:
  /// **'{count} days before due time'**
  String reminderDaysBeforeDue(int count);

  /// No description provided for @reminderCustomOption.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get reminderCustomOption;

  /// No description provided for @reminderCustomTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom reminder'**
  String get reminderCustomTitle;

  /// No description provided for @reminderEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get reminderEnterAmount;

  /// No description provided for @reminderUnitMinutes.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get reminderUnitMinutes;

  /// No description provided for @reminderUnitHours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get reminderUnitHours;

  /// No description provided for @reminderUnitDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get reminderUnitDays;

  /// No description provided for @reminderSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} reminders selected'**
  String reminderSelectedCount(int count);

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @timeUntilStart.
  ///
  /// In en, this message translates to:
  /// **'Starts in {time}'**
  String timeUntilStart(String time);

  /// No description provided for @timeUntilStartNow.
  ///
  /// In en, this message translates to:
  /// **'Starting now'**
  String get timeUntilStartNow;

  /// No description provided for @timeUntilStartMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {count} min'**
  String timeUntilStartMinutes(int count);

  /// No description provided for @timeUntilStartHours.
  ///
  /// In en, this message translates to:
  /// **'in {count} hr'**
  String timeUntilStartHours(int count);

  /// No description provided for @timeUntilStartHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'in {hours} hr {minutes} min'**
  String timeUntilStartHoursMinutes(int hours, int minutes);

  /// No description provided for @timeUntilStartDays.
  ///
  /// In en, this message translates to:
  /// **'in {count} days'**
  String timeUntilStartDays(int count);

  /// No description provided for @timeUntilStartDaysHours.
  ///
  /// In en, this message translates to:
  /// **'in {days} days {hours} hr'**
  String timeUntilStartDaysHours(int days, int hours);

  /// No description provided for @detailTimeUntilStart.
  ///
  /// In en, this message translates to:
  /// **'Time until start'**
  String get detailTimeUntilStart;

  /// No description provided for @detailReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get detailReminder;

  /// No description provided for @focusTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get focusTitle;

  /// No description provided for @focusPomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get focusPomodoro;

  /// No description provided for @focusStopwatch.
  ///
  /// In en, this message translates to:
  /// **'Stopwatch'**
  String get focusStopwatch;

  /// No description provided for @focusStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get focusStart;

  /// No description provided for @focusPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get focusPause;

  /// No description provided for @focusResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get focusResume;

  /// No description provided for @focusEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get focusEnd;

  /// No description provided for @focusMinutes.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String focusMinutes(int minutes);

  /// No description provided for @focusCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom {minutes}'**
  String focusCustom(int minutes);

  /// No description provided for @focusSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved {duration}'**
  String focusSaved(String duration);

  /// No description provided for @focusSelectTask.
  ///
  /// In en, this message translates to:
  /// **'Select Focus Task'**
  String get focusSelectTask;

  /// No description provided for @focusTodayTasks.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Schedule & Tasks'**
  String get focusTodayTasks;

  /// No description provided for @focusNoTask.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get focusNoTask;

  /// No description provided for @focusCompletedTitle.
  ///
  /// In en, this message translates to:
  /// **'Focus Completed 🎉'**
  String get focusCompletedTitle;

  /// No description provided for @focusSummaryTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get focusSummaryTask;

  /// No description provided for @focusSummaryDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get focusSummaryDuration;

  /// No description provided for @focusSummaryStart.
  ///
  /// In en, this message translates to:
  /// **'Start Time'**
  String get focusSummaryStart;

  /// No description provided for @focusSummaryEnd.
  ///
  /// In en, this message translates to:
  /// **'End Time'**
  String get focusSummaryEnd;

  /// No description provided for @focusCustomDuration.
  ///
  /// In en, this message translates to:
  /// **'Custom Duration'**
  String get focusCustomDuration;

  /// No description provided for @focusHoursLabel.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get focusHoursLabel;

  /// No description provided for @focusMinutesFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Minutes'**
  String get focusMinutesFieldLabel;

  /// No description provided for @focusAddPreset.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get focusAddPreset;

  /// No description provided for @focusTapToToggleDisplay.
  ///
  /// In en, this message translates to:
  /// **'Tap to switch display'**
  String get focusTapToToggleDisplay;

  /// No description provided for @focusDoneDelete.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get focusDoneDelete;

  /// No description provided for @focusCurrentTask.
  ///
  /// In en, this message translates to:
  /// **'Select task'**
  String get focusCurrentTask;

  /// No description provided for @focusCustomTaskHint.
  ///
  /// In en, this message translates to:
  /// **'Type a custom task name'**
  String get focusCustomTaskHint;

  /// No description provided for @focusUseCustomTask.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get focusUseCustomTask;

  /// No description provided for @focusCurrentFocus.
  ///
  /// In en, this message translates to:
  /// **'Current Focus'**
  String get focusCurrentFocus;

  /// No description provided for @focusSelectTodo.
  ///
  /// In en, this message translates to:
  /// **'Select Task'**
  String get focusSelectTodo;

  /// No description provided for @focusTaskModeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get focusTaskModeCustom;

  /// No description provided for @focusImmersiveExit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get focusImmersiveExit;

  /// No description provided for @focusLongPressImmersive.
  ///
  /// In en, this message translates to:
  /// **'Long press timer for immersive mode'**
  String get focusLongPressImmersive;

  /// No description provided for @focusDurationHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String focusDurationHoursMinutes(int hours, int minutes);

  /// No description provided for @focusDurationHours.
  ///
  /// In en, this message translates to:
  /// **'{hours}h'**
  String focusDurationHours(int hours);

  /// No description provided for @focusDurationMinutesOnly.
  ///
  /// In en, this message translates to:
  /// **'{minutes} min'**
  String focusDurationMinutesOnly(int minutes);

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statsTitle;

  /// No description provided for @statsDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get statsDay;

  /// No description provided for @statsWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get statsWeek;

  /// No description provided for @statsDailyFocus.
  ///
  /// In en, this message translates to:
  /// **'Daily Focus'**
  String get statsDailyFocus;

  /// No description provided for @statsWeeklyFocus.
  ///
  /// In en, this message translates to:
  /// **'Weekly Focus'**
  String get statsWeeklyFocus;

  /// No description provided for @statsDailyTodo.
  ///
  /// In en, this message translates to:
  /// **'Daily Todo Completion'**
  String get statsDailyTodo;

  /// No description provided for @statsWeeklyTodo.
  ///
  /// In en, this message translates to:
  /// **'Weekly Completion'**
  String get statsWeeklyTodo;

  /// No description provided for @statsFocusLabel.
  ///
  /// In en, this message translates to:
  /// **'Focus: {duration}'**
  String statsFocusLabel(String duration);

  /// No description provided for @statsTasksLabel.
  ///
  /// In en, this message translates to:
  /// **'Tasks: {done}/{total}'**
  String statsTasksLabel(int done, int total);

  /// No description provided for @statsProgressLabel.
  ///
  /// In en, this message translates to:
  /// **'Progress: {percent}%'**
  String statsProgressLabel(int percent);

  /// No description provided for @deadlineTime.
  ///
  /// In en, this message translates to:
  /// **'Deadline {time}'**
  String deadlineTime(String time);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ko', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
