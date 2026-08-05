import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/providers/app_providers.dart';
import 'core/services/notification_service.dart';
import 'database/app_database.dart';
import 'database/event_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final remindersEnabled = prefs.getBool('reminders_enabled') ?? true;

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  NotificationService.instance.configure(
    remindersEnabled: remindersEnabled,
    onTap: (eventId) {
      container.read(pendingNotificationEventIdProvider.notifier).state =
          eventId;
    },
  );

  await NotificationService.instance.initialize();

  final db = AppDatabase();
  final repo = EventRepository(db);
  if (remindersEnabled) {
    await NotificationService.instance.rescheduleAll(repo);
  }
  await db.close();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const SoftScheduleApp(),
    ),
  );
}
