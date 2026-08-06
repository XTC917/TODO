import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import '../services/notification_service.dart';
import '../../models/reminder_config.dart';

/// Initializes notification scheduling after the first frame.
/// Re-registers alarms when the app returns to foreground (without re-requesting permission).
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap>
    with WidgetsBindingObserver {
  bool _initialPermissionRequested = false;
  Future<void>? _rescheduleInFlight;

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
      _reschedule(requestPermissionIfNeeded: false);
    }
  }

  Future<void> _bootstrap() async {
    if (!mounted) return;

    NotificationService.instance.notificationTimeUntilStartBuilder =
        (offsetSeconds) {
      final l10n = ref.read(appLocalizationsProvider);
      return formatNotificationTimeUntilStart(l10n, offsetSeconds);
    };

    await _reschedule(requestPermissionIfNeeded: true);
  }

  Future<void> _reschedule({required bool requestPermissionIfNeeded}) async {
    if (!mounted || !ref.read(remindersEnabledProvider)) return;

    _rescheduleInFlight ??=
        _doReschedule(requestPermissionIfNeeded: requestPermissionIfNeeded);
    try {
      await _rescheduleInFlight;
    } finally {
      _rescheduleInFlight = null;
    }
  }

  Future<void> _doReschedule({required bool requestPermissionIfNeeded}) async {
    if (!mounted || !ref.read(remindersEnabledProvider)) return;

    if (requestPermissionIfNeeded && !_initialPermissionRequested) {
      _initialPermissionRequested = true;
      if (!await NotificationService.instance.hasPermission()) {
        if (!mounted) return;
        await NotificationService.instance.requestPermissions();
      }
    } else if (!await NotificationService.instance.hasPermission()) {
      return;
    }

    if (!mounted) return;
    ref.invalidate(notificationPermissionProvider);

    if (!await NotificationService.instance.hasPermission()) return;
    if (!mounted) return;

    await NotificationService.instance.rescheduleAll(
      ref.read(eventRepositoryProvider),
    );
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
