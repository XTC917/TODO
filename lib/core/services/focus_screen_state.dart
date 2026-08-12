import 'dart:io';



import 'package:flutter/foundation.dart';

import 'package:flutter/services.dart';



/// Distinguishes screen lock from leaving the app during strict focus mode.

class FocusScreenState {

  FocusScreenState._();



  static const _channel = MethodChannel('com.juju.schedule/reminder_native');



  @visibleForTesting

  static const lockDetectPollCount = 10;



  @visibleForTesting

  static const lockDetectPollInterval = Duration(milliseconds: 50);



  /// True when strict mode should treat the user as having left the app.

  ///

  /// On Android, locking the screen (even with display still on / wakelock)

  /// is not counted as leaving.

  static Future<bool> isLeavingAppForStrictMode() async {

    if (!Platform.isAndroid) return true;



    // Keyguard / screen state may settle shortly after [paused].

    for (var i = 0; i < lockDetectPollCount; i++) {

      await Future<void>.delayed(lockDetectPollInterval);

      if (await isStrictFocusScreenLock()) return false;

    }

    return true;

  }



  /// True when the device appears locked or the display is off.

  static Future<bool> isStrictFocusScreenLock() async {

    if (!Platform.isAndroid) return false;

    try {

      return await _channel.invokeMethod<bool>('isStrictFocusScreenLock') ??

          false;

    } catch (_) {

      // Prefer not punishing the user when native checks are unavailable.

      return true;

    }

  }



  static Future<bool> isScreenInteractive() async {

    if (!Platform.isAndroid) return true;

    try {

      return await _channel.invokeMethod<bool>('isScreenInteractive') ?? true;

    } catch (_) {

      return true;

    }

  }



  /// Pure evaluation helper for unit tests.

  @visibleForTesting

  static bool evaluateStrictLeaveSamples(List<bool> screenLockSamples) {

    for (final locked in screenLockSamples) {

      if (locked) return false;

    }

    return true;

  }

}


