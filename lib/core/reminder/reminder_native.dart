import 'dart:io';

import 'package:flutter/services.dart';

import 'autostart_guide.dart';
import 'reminder_log.dart';

/// Android-only helpers for manufacturer autostart / background settings.
class ReminderNative {
  ReminderNative._();

  static const _channel = MethodChannel('com.juju.schedule/reminder_native');

  static Future<AutostartGuideType> getAutostartGuideType() async {
    if (!Platform.isAndroid) return AutostartGuideType.generic;
    try {
      final raw =
          await _channel.invokeMethod<String>('getAutostartGuideType');
      return AutostartGuideType.fromStorage(raw);
    } catch (e) {
      reminderLog('autostart guideType failed — $e');
      return AutostartGuideType.generic;
    }
  }

  static Future<AutostartOpenResult> openAutostartSettings() async {
    if (!Platform.isAndroid) {
      return const AutostartOpenResult(opened: false, destination: 'failed');
    }
    try {
      final raw = await _channel.invokeMethod<Object>('openAutostartSettings');
      final result = AutostartOpenResult.fromMap(raw);
      reminderLog(
        'autostart openSettings opened=${result.opened} '
        'destination=${result.destination}',
      );
      return result;
    } catch (e) {
      reminderLog('autostart openSettings failed — $e');
      return const AutostartOpenResult(opened: false, destination: 'failed');
    }
  }
}
