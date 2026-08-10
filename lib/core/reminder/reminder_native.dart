import 'dart:io';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'reminder_log.dart';

const autostartConfiguredKey = 'autostart_configured';

/// Android-only: MIUI autostart settings (no foreground service).
class ReminderNative {
  ReminderNative._();

  static const _channel = MethodChannel('com.juju.schedule/reminder_native');

  static Future<bool> needsAutostartGuide() async {
    if (!Platform.isAndroid) return false;
    try {
      final manufacturer =
          (await _channel.invokeMethod<String>('getManufacturer'))
              ?.toLowerCase() ??
              '';
      return manufacturer.contains('xiaomi') ||
          manufacturer.contains('redmi') ||
          manufacturer.contains('poco');
    } catch (e) {
      reminderLog('autostart needsGuide check failed — $e');
      return false;
    }
  }

  static Future<bool> isAutostartConfigured(SharedPreferences prefs) async {
    if (!Platform.isAndroid) return true;
    return prefs.getBool(autostartConfiguredKey) ?? false;
  }

  static Future<void> markAutostartConfigured(SharedPreferences prefs) async {
    await prefs.setBool(autostartConfiguredKey, true);
    reminderLog('autostart configured by user');
  }

  static Future<bool> openAutostartSettings() async {
    if (!Platform.isAndroid) return false;
    try {
      final opened =
          await _channel.invokeMethod<bool>('openAutostartSettings') ?? false;
      reminderLog('autostart openSettings opened=$opened');
      return opened;
    } catch (e) {
      reminderLog('autostart openSettings failed — $e');
      return false;
    }
  }
}
