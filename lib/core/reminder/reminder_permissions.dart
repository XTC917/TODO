import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

import 'reminder_constants.dart';
import 'reminder_log.dart';

/// Android channel and runtime permission helpers.
class ReminderPermissions {
  ReminderPermissions(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;
  bool _ready = false;

  bool get isReady => _ready;

  void markReady() => _ready = true;

  // Short-TTL cache for `canScheduleExactNotifications()`. The N reminders
  // of one task are scheduled milliseconds apart; without this a single
  // transient `false` from the platform channel silently downgrades exactly
  // one of them to inexact (1-15 min batching jitter) while its siblings
  // stay exact — precisely the "17:00准时、18:02延迟、18:40准时" symptom.
  bool _exactCached = false;
  DateTime? _exactCheckAt;
  static const _exactCacheTtl = Duration(seconds: 10);

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  bool get _activityReady {
    if (!WidgetsBinding.instance.isRootWidgetAttached) return false;
    return WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  Future<void> createChannel() async {
    if (!Platform.isAndroid) return;
    reminderLog('createChannel() id=${ReminderConstants.channelId}');
    try {
      await _android?.createNotificationChannel(
        const AndroidNotificationChannel(
          ReminderConstants.channelId,
          ReminderConstants.channelName,
          description: ReminderConstants.channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        ),
      );
      reminderLog('createChannel() success');
    } catch (e) {
      reminderLog('createChannel() failed — $e');
    }
  }

  Future<bool> hasNotificationPermission() async {
    if (!Platform.isAndroid) {
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final settings = await ios?.checkPermissions();
      return settings?.isEnabled ?? false;
    }

    try {
      if (await Permission.notification.status == PermissionStatus.granted) {
        return true;
      }
    } catch (e) {
      reminderLog('hasNotificationPermission() permission_handler error — $e');
    }

    final android = _android;
    if (android == null) return false;

    for (var attempt = 0; attempt < 3; attempt++) {
      final enabled = await android.areNotificationsEnabled();
      if (enabled == true) return true;
      if (attempt < 2) {
        await Future<void>.delayed(Duration(milliseconds: 150 * (attempt + 1)));
      }
    }
    return false;
  }

  bool _permissionRequestedThisSession = false;
  bool _permissionRequestInFlight = false;

  Future<bool> requestPermission({bool force = false}) async {
    if (_permissionRequestInFlight) {
      return hasNotificationPermission();
    }
    if (!force && _permissionRequestedThisSession) {
      return hasNotificationPermission();
    }
    if (!_activityReady) {
      reminderLog('requestPermission() skipped — no active Activity');
      return hasNotificationPermission();
    }

    _permissionRequestInFlight = true;
    reminderLog('requestPermission()');

    try {
      if (!_activityReady) return false;

      if (Platform.isAndroid) {
        final android = _android;
        if (android == null) return false;

        _permissionRequestedThisSession = true;
        final granted =
            await android.requestNotificationsPermission() ?? false;
        final enabled = await android.areNotificationsEnabled();
        final ok = granted || (enabled ?? false);
        reminderLog('requestPermission() granted=$ok');
        if (ok) await requestExactAlarmPermission();
        return ok;
      }

      if (Platform.isIOS) {
        final ios = _plugin.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();
        if (ios == null) return false;
        _permissionRequestedThisSession = true;
        final granted = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        final ok = granted ?? false;
        reminderLog('requestPermission() granted=$ok');
        return ok;
      }

      return true;
    } catch (e) {
      reminderLog('requestPermission() failed — $e');
      return false;
    } finally {
      _permissionRequestInFlight = false;
    }
  }

  Future<bool> requestPermissionWhenReady({bool force = false}) async {
    for (var attempt = 0; attempt < 40; attempt++) {
      if (_activityReady) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        if (_activityReady) {
          return requestPermission(force: force);
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    reminderLog('requestPermissionWhenReady() timed out waiting for Activity');
    return hasNotificationPermission();
  }

  Future<bool> canScheduleExactAlarms({bool useCache = true}) async {
    if (!Platform.isAndroid) return true;
    // Cache the platform check for a short TTL so that the N reminders of
    // one task (scheduled within milliseconds of each other) always share a
    // single consistent answer. Without this, one transient `false` in the
    // middle of a batch silently downgrades exactly one reminder to inexact.
    if (useCache &&
        _exactCheckAt != null &&
        DateTime.now().difference(_exactCheckAt!) < _exactCacheTtl) {
      return _exactCached;
    }
    bool ok = false;
    try {
      ok = await _android?.canScheduleExactNotifications() ?? false;
    } catch (e) {
      reminderLog('exactAlarmPermission() check failed — $e');
      if (_exactCheckAt != null) return _exactCached;
      return false;
    }
    _exactCached = ok;
    _exactCheckAt = DateTime.now();
    reminderLog('exactAlarmPermission() granted=$ok');
    return ok;
  }

  void invalidateExactAlarmCache() => _exactCheckAt = null;

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _android;
    if (android == null) return false;
    if (await canScheduleExactAlarms(useCache: false)) return true;

    reminderLog('exactAlarmPermission() requesting…');
    try {
      final requested = await android.requestExactAlarmsPermission() ?? false;
      final ok =
          requested || await canScheduleExactAlarms(useCache: false);
      reminderLog('exactAlarmPermission() granted=$ok');
      return ok;
    } catch (e) {
      reminderLog('exactAlarmPermission() failed — $e');
      return false;
    }
  }

  Future<bool> isBatteryOptimizationIgnored() async {
    if (!Platform.isAndroid) return true;
    try {
      final ignored = await Permission.ignoreBatteryOptimizations.isGranted;
      reminderLog('batteryOptimization() ignored=$ignored');
      return ignored;
    } catch (e) {
      reminderLog('batteryOptimization() check failed — $e');
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimization() async {
    if (!Platform.isAndroid) return true;
    if (await isBatteryOptimizationIgnored()) return true;
    if (!_activityReady) {
      reminderLog('batteryOptimization() skipped — no active Activity');
      return isBatteryOptimizationIgnored();
    }

    reminderLog('batteryOptimization() requesting…');
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      final ok = status.isGranted;
      reminderLog('batteryOptimization() ignored=$ok');
      return ok;
    } catch (e) {
      reminderLog('batteryOptimization() request failed — $e');
      return false;
    }
  }
}
