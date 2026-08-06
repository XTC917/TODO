import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  final prefs = await SharedPreferences.getInstance();
  final packageInfo = await PackageInfo.fromPlatform();
  final remindersEnabled = prefs.getBool('reminders_enabled') ?? true;

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      packageInfoProvider.overrideWithValue(packageInfo),
    ],
  );

  NotificationService.instance.configure(
    remindersEnabled: remindersEnabled,
    onTap: (eventId) {
      container.read(pendingNotificationEventIdProvider.notifier).state =
          eventId;
    },
  );

  try {
    await NotificationService.instance.initialize();
  } catch (e, st) {
    debugPrint('Notification init failed (app will continue): $e\n$st');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SoftScheduleApp(),
    ),
  );
}
