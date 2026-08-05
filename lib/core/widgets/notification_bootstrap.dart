import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import '../services/notification_service.dart';
import '../../models/reminder_config.dart';

/// Requests notification permission after the first frame, then reschedules.
/// Also re-registers alarms when the app returns to foreground.
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap>
    with WidgetsBindingObserver {
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
      _reschedule();
    }
  }

  Future<void> _bootstrap() async {
    NotificationService.instance.notificationTimeUntilStartBuilder =
        (offsetSeconds) {
      final l10n = ref.read(appLocalizationsProvider);
      return formatNotificationTimeUntilStart(l10n, offsetSeconds);
    };
    await _reschedule();
  }

  Future<void> _reschedule() async {
    if (!ref.read(remindersEnabledProvider)) return;

    await NotificationService.instance.requestPermissions();
    if (!mounted) return;

    ref.invalidate(notificationPermissionProvider);

    if (await NotificationService.instance.hasPermission()) {
      await NotificationService.instance.rescheduleAll(
        ref.read(eventRepositoryProvider),
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
