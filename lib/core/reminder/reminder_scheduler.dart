import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/app_config.dart';
import 'reminder_constants.dart';
import 'reminder_log.dart';
import 'reminder_permissions.dart';

/// Timezone setup and low-level [zonedSchedule] calls.
class ReminderScheduler {
  ReminderScheduler({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderPermissions permissions,
  })  : _plugin = plugin,
        _permissions = permissions;

  final FlutterLocalNotificationsPlugin _plugin;
  final ReminderPermissions _permissions;
  bool _timezoneReady = false;

  Future<void> ensureTimezone() async {
    if (_timezoneReady) return;
    try {
      tz.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
      reminderLog('timezone() set to $name');
    } catch (e) {
      reminderLog('timezone() FlutterTimezone failed — $e, using offset fallback');
      tz.initializeTimeZones();
      final offset = DateTime.now().timeZoneOffset;
      final fallback = switch (offset.inHours) {
        8 => 'Asia/Shanghai',
        9 => 'Asia/Tokyo',
        -5 => 'America/New_York',
        -8 => 'America/Los_Angeles',
        0 => 'UTC',
        _ => 'UTC',
      };
      tz.setLocalLocation(tz.getLocation(fallback));
      reminderLog('timezone() fallback=$fallback');
    }
    _timezoneReady = true;
  }

  NotificationDetails notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        ReminderConstants.channelId,
        ReminderConstants.channelName,
        channelDescription: ReminderConstants.channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        icon: ReminderConstants.androidIcon,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  /// Schedules one notification. Returns the mode that succeeded, or null.
  Future<AndroidScheduleMode?> scheduleAt({
    required int notificationId,
    required String title,
    required String body,
    required tz.TZDateTime triggerTime,
    required String payload,
    String? logContext,
  }) async {
    await ensureTimezone();

    final exactOk =
        !Platform.isAndroid || await _permissions.canScheduleExactAlarms();
    final modes = <AndroidScheduleMode>[
      if (exactOk) AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];

    for (final mode in modes) {
      final ctx = logContext ?? 'id=$notificationId';
      try {
        await _plugin.zonedSchedule(
          notificationId,
          title,
          body,
          triggerTime,
          notificationDetails(),
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        reminderLog(
          'schedule $ctx triggerTime=$triggerTime scheduleMode=$mode schedule success',
        );
        return mode;
      } catch (e) {
        reminderLog(
          'schedule $ctx triggerTime=$triggerTime scheduleMode=$mode schedule failed — $e',
        );
      }
    }
    return null;
  }

  Future<bool> cancel(int notificationId) async {
    reminderLog('cancel(id=$notificationId)');
    try {
      await _plugin.cancel(notificationId);
      return true;
    } catch (e) {
      reminderLog('cancel(id=$notificationId) failed — $e');
      return false;
    }
  }

  Future<void> cancelAll() async {
    reminderLog('cancelAll()');
    try {
      await _plugin.cancelAll();
    } catch (e) {
      reminderLog('cancelAll() failed — $e');
    }
  }

  Future<int> pendingCount() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      reminderLog('pendingCount() failed — $e');
      return 0;
    }
  }

  Future<List<int>> pendingIds() async {
    try {
      final pending = await _plugin.pendingNotificationRequests();
      return pending.map((request) => request.id).toList();
    } catch (e) {
      reminderLog('pendingIds() failed — $e');
      return const [];
    }
  }

  /// Settings-page test — same [zonedSchedule] path as real reminders.
  Future<bool> scheduleTestReminder() async {
    await _permissions.createChannel();

    if (!await _permissions.hasNotificationPermission()) {
      await _permissions.requestPermission(force: true);
      if (!await _permissions.hasNotificationPermission()) {
        reminderLog('test notification permission denied');
        return false;
      }
    }

    await ensureTimezone();
    final triggerTime = tz.TZDateTime.now(tz.local).add(
      ReminderConstants.testScheduleDelay,
    );

    reminderLog('schedule test notification triggerTime=$triggerTime');

    final mode = await scheduleAt(
      notificationId: ReminderConstants.testNotificationId,
      title: AppConfig.appName,
      body: AppConfig.testNotificationBody,
      triggerTime: triggerTime,
      payload: '${ReminderConstants.eventPayloadPrefix}0',
      logContext: 'test notification',
    );

    if (mode != null) {
      reminderLog('schedule test notification schedule success');
      return true;
    }
    reminderLog('schedule test notification schedule failed');
    return false;
  }
}
