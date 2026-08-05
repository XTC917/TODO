import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../services/notification_service.dart';

/// Requests notification permission after the first frame, then reschedules.
class NotificationBootstrap extends ConsumerStatefulWidget {
  const NotificationBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationBootstrap> createState() =>
      _NotificationBootstrapState();
}

class _NotificationBootstrapState extends ConsumerState<NotificationBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
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
