import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../reminder/reminder_log.dart';

/// Local notifications for focus session end and strict-mode reminders.
class FocusNotificationService {
  FocusNotificationService._();
  static final FocusNotificationService instance = FocusNotificationService._();

  static const _channelId = 'juju_focus';
  static const _channelName = 'Focus';
  static const endNotificationId = 900001;
  static const strictReminderBaseId = 900010;
  static const strictFailNotificationId = 900016;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Focus session alerts',
            importance: Importance.max,
          ),
        );
    _initialized = true;
  }

  NotificationDetails _details() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Focus session alerts',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: true,
      ),
    );
  }

  Future<void> schedulePomodoroEnd({
    required DateTime endAt,
    required String title,
    required String body,
  }) async {
    await initialize();
    await cancelEndNotification();
    final trigger = tz.TZDateTime.from(endAt, tz.local);
    if (!trigger.isAfter(tz.TZDateTime.now(tz.local))) return;
    try {
      await _plugin.zonedSchedule(
        endNotificationId,
        title,
        body,
        trigger,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: 'focus_end',
      );
      reminderLog('focus schedule end at $endAt');
    } catch (e) {
      reminderLog('focus schedule end failed — $e');
    }
  }

  Future<void> cancelEndNotification() async {
    try {
      await _plugin.cancel(endNotificationId);
    } catch (_) {}
  }

  Future<void> showEndNow({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(endNotificationId, title, body, _details());
  }

  Future<void> showStrictReminder({
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(strictReminderBaseId, title, body, _details());
  }

  Future<void> scheduleStrictBackgroundReminders({
    required DateTime backgroundedAt,
    required String reminderTitle,
    required String reminderBody,
    required String failTitle,
    required String failBody,
  }) async {
    await initialize();
    await cancelStrictReminders();
    final now = tz.TZDateTime.now(tz.local);
    for (var i = 1; i <= 5; i++) {
      final trigger = tz.TZDateTime.from(
        backgroundedAt.add(Duration(seconds: i * 10)),
        tz.local,
      );
      if (!trigger.isAfter(now)) continue;
      await _scheduleAt(
        id: strictReminderBaseId + i - 1,
        title: reminderTitle,
        body: reminderBody,
        trigger: trigger,
        payload: 'focus_strict_reminder',
      );
    }
    final failTrigger = tz.TZDateTime.from(
      backgroundedAt.add(const Duration(seconds: 60)),
      tz.local,
    );
    if (failTrigger.isAfter(now)) {
      await _scheduleAt(
        id: strictFailNotificationId,
        title: failTitle,
        body: failBody,
        trigger: failTrigger,
        payload: 'focus_strict_fail',
      );
    }
  }

  Future<void> _scheduleAt({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime trigger,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        trigger,
        _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      reminderLog('focus schedule id=$id failed — $e');
    }
  }

  Future<void> cancelStrictReminders() async {
    for (var id = strictReminderBaseId;
        id <= strictFailNotificationId;
        id++) {
      try {
        await _plugin.cancel(id);
      } catch (_) {}
    }
  }

  Future<void> cancelAll() async {
    await cancelEndNotification();
    await cancelStrictReminders();
  }
}
