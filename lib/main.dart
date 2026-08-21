import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:home_widget/home_widget.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/providers/l10n_providers.dart';
import 'core/services/initial_data_seeder.dart';
import 'core/services/focus_notification_service.dart';
import 'core/services/notification_service.dart';
import 'core/widget/home_widget_sync.dart';
import 'l10n/app_localizations.dart';

AppLanguage _readAppLanguage(SharedPreferences prefs) {
  return AppLanguage.values.firstWhere(
    (language) => language.name == prefs.getString('app_language'),
    orElse: () => AppLanguage.system,
  );
}

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
    await InitialDataSeeder.seedIfFirstLaunch(
      prefs: prefs,
      repo: container.read(eventRepositoryProvider),
      l10n: lookupAppLocalizations(
        resolveAppLocale(_readAppLanguage(prefs)),
      ),
    );
    await InitialDataSeeder.ensureWidgetOnboardingTodo(
      prefs: prefs,
      repo: container.read(eventRepositoryProvider),
      l10n: lookupAppLocalizations(
        resolveAppLocale(_readAppLanguage(prefs)),
      ),
    );
    await InitialDataSeeder.ensureReminderBackgroundHint(
      prefs: prefs,
      repo: container.read(eventRepositoryProvider),
      l10n: lookupAppLocalizations(
        resolveAppLocale(_readAppLanguage(prefs)),
      ),
    );
  } catch (e, st) {
    debugPrint('Initial data seed failed (app will continue): $e\n$st');
  }

  Future(() async {
    try {
      await container
          .read(eventRepositoryProvider)
          .compactAllLegacyMaterialized();
    } catch (e, st) {
      debugPrint('Repeat series compact failed (app will continue): $e\n$st');
    }
  });

  try {
    await NotificationService.instance.initialize();
    await FocusNotificationService.instance.initialize();
  } catch (e, st) {
    debugPrint('Notification init failed (app will continue): $e\n$st');
  }

  await HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SoftScheduleApp(),
    ),
  );
}
