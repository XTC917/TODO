import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import '../services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reminder_config.dart';

/// Initializes notification scheduling after the first frame.
/// Requests notification permission once on cold start, then reschedules.
/// Returning from background only reschedules — never re-requests permission.
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap>
    with WidgetsBindingObserver {
  bool _startupPermissionFlowStarted = false;
  Future<void>? _workInFlight;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
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
      _rescheduleOnly();
    }
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    try {
      await NotificationService.instance.initialize();
    } catch (e, st) {
      debugPrint('Notification init in bootstrap failed: $e\n$st');
    }

    NotificationService.instance.notificationTimeUntilStartBuilder =
        (offsetSeconds) {
      final language = ref.read(appLanguageProvider);
      final l10n = lookupAppLocalizations(resolveAppLocale(language));
      return formatNotificationTimeUntilStart(l10n, offsetSeconds);
    };

    await _runStartupPermissionFlow();
  }

  /// First launch: always prompt once, then reschedule if granted.
  Future<void> _runStartupPermissionFlow() async {
    if (!mounted || _startupPermissionFlowStarted) return;
    if (!ref.read(remindersEnabledProvider)) return;

    _startupPermissionFlowStarted = true;
    _workInFlight ??= _doStartupPermissionFlow();
    try {
      await _workInFlight;
    } finally {
      _workInFlight = null;
    }
  }

  Future<void> _doStartupPermissionFlow() async {
    if (!mounted || !ref.read(remindersEnabledProvider)) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final alreadyPrompted =
        prefs.getBool(notificationPermissionPromptedKey) ?? false;

    if (!alreadyPrompted) {
      if (!mounted) return;
      await NotificationService.instance.requestPermissionsWhenReady(
        force: true,
      );
      await prefs.setBool(notificationPermissionPromptedKey, true);
    }

    if (!mounted) return;
    await _rescheduleIfGranted();
  }

  /// Foreground resume: sync alarms only, never show permission dialog again.
  Future<void> _rescheduleOnly() async {
    if (!mounted || !ref.read(remindersEnabledProvider)) return;
    if (_workInFlight != null) return;

    _workInFlight ??= _rescheduleIfGranted();
    try {
      await _workInFlight;
    } finally {
      _workInFlight = null;
    }
  }

  Future<void> _rescheduleIfGranted() async {
    if (!mounted || !ref.read(remindersEnabledProvider)) return;

    if (!mounted) return;
    ref.invalidate(notificationPermissionProvider);

    await NotificationService.instance.rescheduleAll(
      ref.read(eventRepositoryProvider),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
