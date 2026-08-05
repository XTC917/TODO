import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../database/event_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

const _channelId = 'soft_schedule_reminders';
const _channelName = 'Reminders';
const _androidIcon = '@drawable/ic_notification';
const notificationTitle = 'Reminder';
const eventPayloadPrefix = 'event:';
const testNotificationId = 999999;

typedef NotificationTapHandler = void Function(int eventId);

/// Schedules and cancels local notifications for todos/schedules.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _remindersEnabled = true;
  NotificationTapHandler? _onTap;

  void configure({
    required bool remindersEnabled,
    NotificationTapHandler? onTap,
  }) {
    _remindersEnabled = remindersEnabled;
    _onTap = onTap;
  }

  set remindersEnabled(bool value) => _remindersEnabled = value;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const android = AndroidInitializationSettings(_androidIcon);
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _androidPlugin;
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Task reminders',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
    }

    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      _dispatchPayload(launchDetails!.notificationResponse?.payload);
    }
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<bool> requestPermissions() async {
    await initialize();
    try {
      if (Platform.isAndroid) {
        final androidPlugin = _androidPlugin;
        if (androidPlugin == null) return false;

        final granted =
            await androidPlugin.requestNotificationsPermission() ?? false;
        await androidPlugin.requestExactAlarmsPermission();
        final enabled = await androidPlugin.areNotificationsEnabled();
        return granted || (enabled ?? false);
      }

      if (Platform.isIOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (iosPlugin == null) return false;
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }

      return true;
    } catch (e, st) {
      debugPrint('Notification permission request failed: $e\n$st');
      return false;
    }
  }

  Future<bool> hasPermission() async {
    await initialize();
    try {
      if (Platform.isAndroid) {
        return await _androidPlugin?.areNotificationsEnabled() ?? false;
      }
      if (Platform.isIOS) {
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        final settings = await iosPlugin?.checkPermissions();
        return settings?.isEnabled ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission check failed: $e');
      return false;
    }
  }

  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    return await _androidPlugin?.canScheduleExactNotifications() ?? false;
  }

  Future<int> pendingCount() async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.length;
  }

  /// Fires a notification immediately — use to verify the phone can display alerts.
  Future<bool> showTestNotification() async {
    await initialize();
    if (!await hasPermission()) {
      await requestPermissions();
      if (!await hasPermission()) return false;
    }

    try {
      await _plugin.show(
        testNotificationId,
        notificationTitle,
        'Test notification — reminders are working',
        _notificationDetails(),
      );
      debugPrint('Test notification shown');
      return true;
    } catch (e, st) {
      debugPrint('Test notification failed: $e\n$st');
      return false;
    }
  }

  /// Schedules a test notification [seconds] from now.
  Future<bool> scheduleTestNotification({int seconds = 5}) async {
    await initialize();
    if (!await hasPermission()) {
      await requestPermissions();
      if (!await hasPermission()) return false;
    }

    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    try {
      await _plugin.zonedSchedule(
        testNotificationId - 1,
        notificationTitle,
        'Scheduled test — fired after $seconds seconds',
        when,
        _notificationDetails(),
        androidScheduleMode: await _pickScheduleMode(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('Test notification scheduled for $when');
      return true;
    } catch (e, st) {
      debugPrint('Scheduled test notification failed: $e\n$st');
      return false;
    }
  }

  Future<void> rescheduleAll(EventRepository repository) async {
    await initialize();
    if (!_remindersEnabled) {
      await cancelAll();
      return;
    }
    if (!await hasPermission()) return;

    await cancelAll();
    final rows = await repository.getAllEvents();
    var scheduled = 0;
    for (final event in rows) {
      if (await scheduleForEvent(event, skipPermissionCheck: true)) {
        scheduled++;
      }
    }
    debugPrint('Rescheduled $scheduled notification(s)');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<bool> scheduleForEvent(
    Event event, {
    bool skipPermissionCheck = false,
  }) async {
    await initialize();
    await cancelForEvent(event.id);

    if (!_remindersEnabled) return false;
    if (event.reminderType == ReminderType.none) return false;
    if (event.isCompleted) return false;

    if (!skipPermissionCheck && !await hasPermission()) {
      debugPrint(
        'Skipping notification for event ${event.id}: permission not granted',
      );
      return false;
    }

    final offset = event.reminderType.offset;
    if (offset == null) return false;

    final anchor = event.reminderAnchorDateTime;
    if (anchor == null) {
      debugPrint(
        'Skipping notification for event ${event.id}: no reminder anchor',
      );
      return false;
    }

    final scheduledLocal = anchor.subtract(offset);
    final scheduled = tz.TZDateTime.from(scheduledLocal, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(now)) {
      debugPrint(
        'Skipping event ${event.id}: fire time $scheduled is not after now $now',
      );
      return false;
    }

    try {
      await _plugin.zonedSchedule(
        event.id,
        notificationTitle,
        event.title,
        scheduled,
        _notificationDetails(),
        androidScheduleMode: await _pickScheduleMode(),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$eventPayloadPrefix${event.id}',
      );
      debugPrint(
        'Scheduled notification ${event.id} at $scheduled for "${event.title}"',
      );
      return true;
    } catch (e, st) {
      debugPrint('Failed to schedule notification for event ${event.id}: $e\n$st');
      return false;
    }
  }

  NotificationDetails _notificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Task reminders',
        importance: Importance.max,
        priority: Priority.max,
        icon: _androidIcon,
        playSound: true,
        enableVibration: true,
        visibility: NotificationVisibility.public,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<AndroidScheduleMode> _pickScheduleMode() async {
    if (Platform.isAndroid && await canScheduleExactAlarms()) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

  Future<void> cancelForEvent(int eventId) async {
    await _plugin.cancel(eventId);
  }

  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {}

  void _handleNotificationResponse(NotificationResponse response) {
    _dispatchPayload(response.payload);
  }

  void _dispatchPayload(String? payload) {
    if (payload == null || !payload.startsWith(eventPayloadPrefix)) return;
    final id = int.tryParse(payload.substring(eventPayloadPrefix.length));
    if (id != null) _onTap?.call(id);
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('Notification timezone: $timeZoneName');
      return;
    } catch (e) {
      debugPrint('FlutterTimezone failed: $e');
    }

    final offset = DateTime.now().timeZoneOffset;
    final fallback = switch (offset.inHours) {
      8 => 'Asia/Shanghai',
      9 => 'Asia/Tokyo',
      -5 => 'America/New_York',
      -8 => 'America/Los_Angeles',
      0 => 'UTC',
      _ => null,
    };

    if (fallback != null) {
      tz.setLocalLocation(tz.getLocation(fallback));
      debugPrint('Notification timezone fallback: $fallback');
    } else {
      debugPrint(
        'Notification timezone: using offset ${offset.inHours}h (local wall clock)',
      );
    }
  }
}
