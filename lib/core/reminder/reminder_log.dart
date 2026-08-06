import 'dart:developer' as developer;

/// Release-visible reminder diagnostics (`adb logcat | findstr "JUJU Reminder"`).
void reminderLog(String message) {
  const tag = 'JUJU Reminder';
  // ignore: avoid_print
  print('[$tag] $message');
  developer.log(message, name: tag);
}
