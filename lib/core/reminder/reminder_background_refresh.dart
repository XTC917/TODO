import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reminder_config.dart';
import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import '../services/notification_service.dart';
import 'reminder_log.dart';

/// Rebuilds the rolling reminder window from a background isolate.
///
/// Used when the daily native WorkManager job fires without the UI opening.
Future<void> refreshRemindersInBackground() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (await NotificationService.shouldSkipBackgroundRefresh()) {
    reminderLog('background refresh skipped — recently rescheduled');
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  if (!(prefs.getBool('reminders_enabled') ?? true)) {
    reminderLog('background refresh skipped — reminders disabled');
    return;
  }

  final db = AppDatabase();
  try {
    await NotificationService.instance.initialize();
    NotificationService.instance.remindersEnabled = true;
    NotificationService.instance.setBodyBuilder((offsetSeconds) {
      final language = AppLanguage.values.firstWhere(
        (item) => item.name == prefs.getString('app_language'),
        orElse: () => AppLanguage.system,
      );
      return formatNotificationTimeUntilStart(
        lookupAppLocalizations(resolveAppLocale(language)),
        offsetSeconds,
      );
    });
    await NotificationService.instance.rescheduleAll(EventRepository(db));
    reminderLog('background refresh done');
  } catch (e, st) {
    reminderLog('background refresh failed — $e\n$st');
  } finally {
    await db.close();
  }
}
