import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../config/app_config.dart';
import '../../database/event_repository.dart';
import '../../models/event.dart';
import '../../models/reminder_config.dart';

const _channelId = 'soft_schedule_reminders';
const _channelName = 'Reminders';
const _androidIcon = '@drawable/ic_notification';
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

  /// Optional hook to build localized notification body suffix.
  String Function(int offsetSeconds)? notificationTimeUntilStartBuilder;

  void configure({
    required bool remindersEnabled,
    NotificationTapHandler? onTap,
    String Function(int offsetSeconds)? timeUntilStartBuilder,
  }) {
    _remindersEnabled = remindersEnabled;
    _onTap = onTap;
    notificationTimeUntilStartBuilder = timeUntilStartBuilder;
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
      await _androidPlugin?.createNotificationChannel(
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

  Future<bool> showTestNotification() async {
    await initialize();
    if (!await hasPermission()) {
      await requestPermissions();
      if (!await hasPermission()) return false;
    }

    try {
      await _plugin.show(
        testNotificationId,
        AppConfig.appName,
        AppConfig.testNotificationBody,
        _notificationDetails(),
      );
      return true;
    } catch (e, st) {
      debugPrint('Test notification failed: $e\n$st');
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

    if (Platform.isAndroid) {
      await _androidPlugin?.requestExactAlarmsPermission();
    }

    await cancelAll();
    final rows = await repository.getAllEvents();
    var scheduled = 0;
    for (final event in rows) {
      scheduled += await scheduleForEvent(event, skipPermissionCheck: true);
    }
    debugPrint('Rescheduled $scheduled notification(s)');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Schedules all reminder offsets for [event]. Returns count scheduled.
  Future<int> scheduleForEvent(
    Event event, {
    bool skipPermissionCheck = false,
  }) async {
    await initialize();
    await cancelForEvent(event.id);

    if (!_remindersEnabled) return 0;
    if (!ReminderPresets.hasReminder(event.reminderOffsetsSeconds)) return 0;
    if (event.isCompleted) return 0;

    if (!skipPermissionCheck && !await hasPermission()) {
      debugPrint(
        'Skipping notification for event ${event.id}: permission not granted',
      );
      return 0;
    }

    if (Platform.isAndroid && !skipPermissionCheck) {
      await _androidPlugin?.requestExactAlarmsPermission();
    }

    final anchor = event.reminderAnchorDateTime;
    if (anchor == null) {
      debugPrint(
        'Skipping notification for event ${event.id}: no reminder anchor',
      );
      return 0;
    }

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = 0;
    final offsets = [...event.reminderOffsetsSeconds]
      ..sort((a, b) => b.compareTo(a));

    for (var i = 0; i < offsets.length && i < kMaxRemindersPerEvent; i++) {
      final offsetSeconds = offsets[i];
      final offset = ReminderPresets.toDuration(offsetSeconds);
      if (offset == null) continue;

      final scheduledLocal = anchor.subtract(offset);
      final scheduledTime = tz.TZDateTime.from(scheduledLocal, tz.local);
      if (!scheduledTime.isAfter(now)) {
        debugPrint(
          'Skipping event ${event.id} offset $offsetSeconds: fire time in past',
        );
        continue;
      }

      final notificationId = notificationIdForEvent(event.id, i);
      final untilStart = notificationTimeUntilStartBuilder?.call(offsetSeconds) ??
          _fallbackTimeUntilStart(offsetSeconds);
      final body = '${event.title}\n$untilStart';

      final ok = await _zonedScheduleWithFallback(
        notificationId,
        AppConfig.appName,
        body,
        scheduledTime,
        payload: '$eventPayloadPrefix${event.id}',
      );
      if (ok) {
        scheduled++;
        debugPrint(
          'Scheduled notification $notificationId at $scheduledTime for "${event.title}"',
        );
      }
    }
    return scheduled;
  }

  Future<bool> _zonedScheduleWithFallback(
    int id,
    String title,
    String body,
    tz.TZDateTime scheduled,
    {required String payload}
  ) async {
    final modes = <AndroidScheduleMode>[
      if (Platform.isAndroid && await canScheduleExactAlarms())
        AndroidScheduleMode.alarmClock,
      if (Platform.isAndroid)
        AndroidScheduleMode.exactAllowWhileIdle,
      AndroidScheduleMode.inexactAllowWhileIdle,
    ];

    for (final mode in modes) {
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          _notificationDetails(),
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        return true;
      } catch (e) {
        debugPrint('Schedule mode $mode failed for id $id: $e');
      }
    }
    return false;
  }

  String _fallbackTimeUntilStart(int offsetSeconds) {
    if (offsetSeconds <= 0) return 'Starting now';
    final d = Duration(seconds: offsetSeconds);
    if (d.inDays > 0) return 'Starts in ${d.inDays}d';
    if (d.inHours > 0) return 'Starts in ${d.inHours}h ${d.inMinutes % 60}m';
    return 'Starts in ${d.inMinutes}m';
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
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> cancelForEvent(int eventId) async {
    for (var i = 0; i < kMaxRemindersPerEvent; i++) {
      await _plugin.cancel(notificationIdForEvent(eventId, i));
    }
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
    }
  }
}
