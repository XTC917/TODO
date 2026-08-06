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

  Future<bool> canScheduleExactAlarms() async {
    if (!Platform.isAndroid) return true;
    final ok = await _android?.canScheduleExactNotifications() ?? false;
    reminderLog('exactAlarmPermission() granted=$ok');
    return ok;
  }

  Future<bool> requestExactAlarmPermission() async {
    if (!Platform.isAndroid) return true;
    final android = _android;
    if (android == null) return false;
    if (await canScheduleExactAlarms()) return true;

    reminderLog('exactAlarmPermission() requesting…');
    try {
      final requested = await android.requestExactAlarmsPermission() ?? false;
      final ok = requested || await canScheduleExactAlarms();
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
