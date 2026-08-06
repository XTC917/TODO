import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../database/event_repository.dart';
import '../../models/event.dart';
import '../reminder/reminder_constants.dart';
import '../reminder/reminder_engine.dart';
import '../reminder/reminder_log.dart';
import '../reminder/reminder_permissions.dart';
import '../reminder/reminder_scheduler.dart';

export '../reminder/reminder_constants.dart' show ReminderConstants;

typedef NotificationTapHandler = void Function(int eventId);

enum TestNotificationResult {
  success,
  notInitialized,
  permissionDenied,
  showFailed,
  timedOut,
}

/// Public facade for the reminder module. Other features talk to this class only.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final ReminderPermissions _permissions = ReminderPermissions(_plugin);
  late final ReminderScheduler _scheduler = ReminderScheduler(
    plugin: _plugin,
    permissions: _permissions,
  );
  late final ReminderEngine _engine = ReminderEngine(
    permissions: _permissions,
    scheduler: _scheduler,
  );

  NotificationTapHandler? _onTap;
  bool _initialized = false;

  static const eventPayloadPrefix = ReminderConstants.eventPayloadPrefix;
  static const testNotificationId = ReminderConstants.testNotificationId;

  String Function(int offsetSeconds)? notificationTimeUntilStartBuilder;

  void configure({
    required bool remindersEnabled,
    NotificationTapHandler? onTap,
    String Function(int offsetSeconds)? timeUntilStartBuilder,
  }) {
    _engine.remindersEnabled = remindersEnabled;
    _onTap = onTap;
    notificationTimeUntilStartBuilder = timeUntilStartBuilder;
    _engine.bodyBuilder = timeUntilStartBuilder;
  }

  set remindersEnabled(bool value) => _engine.remindersEnabled = value;

  void setBodyBuilder(String Function(int offsetSeconds) builder) {
    notificationTimeUntilStartBuilder = builder;
    _engine.bodyBuilder = builder;
  }

  Future<void> initialize() async {
    if (_initialized) {
      reminderLog('initialize() skipped — already initialized');
      return;
    }

    reminderLog('initialize()');

    const settings = InitializationSettings(
      android: AndroidInitializationSettings(ReminderConstants.androidIcon),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );

    try {
      final ok = await _plugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );
      if (ok != true) {
        reminderLog('initialize() failed — plugin returned $ok');
        return;
      }
    } catch (e) {
      reminderLog('initialize() failed — $e');
      return;
    }

    await _scheduler.ensureTimezone();
    await _permissions.createChannel();
    _permissions.markReady();
    _initialized = true;

    try {
      final launch = await _plugin.getNotificationAppLaunchDetails();
      if (launch?.didNotificationLaunchApp == true) {
        _dispatchPayload(launch!.notificationResponse?.payload);
      }
    } catch (e) {
      reminderLog('initialize() launch details failed — $e');
    }

    reminderLog('initialize() success');
  }

  Future<bool> requestPermissionsWhenReady({bool force = false}) =>
      _permissions.requestPermissionWhenReady(force: force);

  Future<bool> requestPermissions({bool force = false}) =>
      _permissions.requestPermission(force: force);

  Future<bool> hasPermission() => _permissions.hasNotificationPermission();

  Future<bool> canScheduleExactAlarms() =>
      _permissions.canScheduleExactAlarms();

  Future<bool> requestExactAlarmsPermission() =>
      _permissions.requestExactAlarmPermission();

  Future<bool> isBatteryOptimizationIgnored() =>
      _permissions.isBatteryOptimizationIgnored();

  Future<bool> requestIgnoreBatteryOptimization() =>
      _permissions.requestIgnoreBatteryOptimization();

  /// Re-check permissions needed for background alarm delivery (no reschedule).
  Future<void> refreshBackgroundPermissions() async {
    reminderLog('refreshBackgroundPermissions()');
    await requestExactAlarmsPermission();
    await isBatteryOptimizationIgnored();
  }

  Future<int> pendingCount() => _scheduler.pendingCount();

  Future<TestNotificationResult> showTestNotification() async {
    await initialize();
    if (!_initialized) return TestNotificationResult.notInitialized;

    if (!await _permissions.hasNotificationPermission()) {
      await _permissions.requestPermission(force: true);
      if (!await _permissions.hasNotificationPermission()) {
        return TestNotificationResult.permissionDenied;
      }
    }

    final ok = await _scheduler.scheduleTestReminder();
    return ok ? TestNotificationResult.success : TestNotificationResult.showFailed;
  }

  Future<void> rescheduleAll(EventRepository repository) =>
      _engine.rescheduleAll(repository);

  Future<void> cancelAll() => _scheduler.cancelAll();

  Future<int> scheduleForEvent(
    Event event, {
    bool skipPermissionCheck = false,
    Event? previousEvent,
  }) =>
      _engine.scheduleForEvent(
        event,
        previousEvent: previousEvent,
        skipPermissionCheck: skipPermissionCheck,
      );

  Future<void> cancelForEvent(int eventId) => _engine.cancelForEvent(eventId);

  Future<void> deleteEventReminders(int eventId) =>
      _engine.deleteEventReminders(eventId);

  void _onNotificationResponse(NotificationResponse response) {
    _dispatchPayload(response.payload);
  }

  void _dispatchPayload(String? payload) {
    if (payload == null ||
        !payload.startsWith(ReminderConstants.eventPayloadPrefix)) {
      return;
    }
    final id = int.tryParse(
      payload.substring(ReminderConstants.eventPayloadPrefix.length),
    );
    if (id == null || id == 0) return;
    reminderLog('received payload=$payload eventId=$id');
    _onTap?.call(id);
  }
}
