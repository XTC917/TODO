/// Shared constants for the reminder module.
class ReminderConstants {
  ReminderConstants._();

  static const channelId = 'soft_schedule_reminders';
  static const channelName = 'Reminders';
  static const channelDescription = 'Task reminders';

  /// Drawable resource name only — not `@drawable/...`.
  static const androidIcon = 'ic_notification';

  static const eventPayloadPrefix = 'event:';

  /// Reserved notification id for the settings-page test reminder.
  static const testNotificationId = 999999;

  /// How far ahead the test reminder is scheduled.
  static const testScheduleDelay = Duration(minutes: 1);
}
