import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import '../reminder/reminder_log.dart';
import '../services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reminder_config.dart';

/// Wires reminder init, permissions, and full reschedule on app startup.
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap>
    with WidgetsBindingObserver {
  bool _startupDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onStartup());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationPermissionProvider);
      // Do NOT reschedule on resume — cancelAll()+reschedule races with
      // background and can wipe AlarmManager entries before they are rewritten.
      NotificationService.instance.refreshBackgroundPermissions();
    }
  }

  Future<void> _onStartup() async {
    if (!mounted || _startupDone) return;
    _startupDone = true;

    reminderLog('NotificationBootstrap startup');

    await NotificationService.instance.initialize();

    NotificationService.instance.remindersEnabled =
        ref.read(remindersEnabledProvider);
    NotificationService.instance.setBodyBuilder((offsetSeconds) {
      final language = ref.read(appLanguageProvider);
      final l10n = lookupAppLocalizations(resolveAppLocale(language));
      return formatNotificationTimeUntilStart(l10n, offsetSeconds);
    });

    await _runStartupFlow();
  }

  Future<void> _runStartupFlow() async {
    if (!mounted || !ref.read(remindersEnabledProvider)) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final prompted = prefs.getBool(notificationPermissionPromptedKey) ?? false;

    if (!prompted) {
      await NotificationService.instance.requestPermissionsWhenReady(
        force: true,
      );
      await prefs.setBool(notificationPermissionPromptedKey, true);
    } else {
      await NotificationService.instance.refreshBackgroundPermissions();
    }

    if (!mounted || !ref.read(remindersEnabledProvider)) return;
    ref.invalidate(notificationPermissionProvider);
    await NotificationService.instance.rescheduleAll(
      ref.read(eventRepositoryProvider),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
