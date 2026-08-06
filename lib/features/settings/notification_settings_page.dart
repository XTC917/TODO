import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class NotificationSettingsPage extends ConsumerStatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  ConsumerState<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState
    extends ConsumerState<NotificationSettingsPage>
    with WidgetsBindingObserver {
  bool _sendingTest = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.invalidate(notificationPermissionProvider);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(notificationPermissionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);

    return SettingsSubpageScaffold(
      title: l10n.settingsNotifications,
      body: SettingsGroup(
        children: [
          SwitchListTile(
            title: Text(l10n.enableReminders),
            value: remindersEnabled,
            onChanged: (v) =>
                ref.read(remindersEnabledProvider.notifier).setEnabled(v),
          ),
          permissionAsync.when(
            data: (granted) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  leading: const Icon(Icons.security_outlined, size: 22),
                  title: Text(l10n.settingsNotificationPermission),
                  subtitle: Text(
                    granted
                        ? l10n.notificationPermissionGranted
                        : l10n.notificationPermissionDenied,
                  ),
                  trailing: granted
                      ? Icon(
                          Icons.check_circle_outline,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
                if (!granted) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => _requestPermission(context),
                        child: Text(l10n.requestNotificationPermission),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await AppSettings.openAppSettings(
                            type: AppSettingsType.notification,
                          );
                          if (!mounted) return;
                          await refreshNotificationPermission(ref);
                          await _rescheduleIfEnabled(ref);
                        },
                        child: Text(l10n.openNotificationSettings),
                      ),
                    ),
                  ),
                ],
                if (granted || remindersEnabled) ...[
                  FutureBuilder<bool>(
                    future: NotificationService.instance.canScheduleExactAlarms(),
                    builder: (context, snapshot) {
                      if (snapshot.data != false) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          l10n.exactAlarmPermissionHint,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                        ),
                      );
                    },
                  ),
                  if (granted)
                    FutureBuilder<int>(
                      future: NotificationService.instance.pendingCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data;
                        if (count == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          child: Text(
                            l10n.pendingNotifications(count),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        );
                      },
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      l10n.reminderSetupHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: OutlinedButton.icon(
                      onPressed: _sendingTest || !remindersEnabled
                          ? null
                          : () => _sendTestNotification(context),
                      icon: _sendingTest
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.notifications_active),
                      label: Text(
                        _sendingTest
                            ? l10n.testNotificationSending
                            : l10n.testNotificationNow,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            loading: () => const ListTile(title: Text('…')),
            error: (_, __) => ListTile(
              title: Text(l10n.notificationPermissionDenied),
              trailing: TextButton(
                onPressed: () async {
                  await AppSettings.openAppSettings(
                    type: AppSettingsType.notification,
                  );
                  if (!mounted) return;
                  await refreshNotificationPermission(ref);
                },
                child: Text(l10n.openNotificationSettings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPermission(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final granted = await NotificationService.instance.requestPermissionsWhenReady(
      force: true,
    );
    if (!mounted) return;
    await refreshNotificationPermission(ref);
    if (granted) {
      await _rescheduleIfEnabled(ref);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          granted
              ? l10n.notificationPermissionGranted
              : l10n.testNotificationFailed,
        ),
      ),
    );
  }

  Future<void> _rescheduleIfEnabled(WidgetRef ref) async {
    if (!ref.read(remindersEnabledProvider)) return;
    await NotificationService.instance.rescheduleAll(
      ref.read(eventRepositoryProvider),
    );
  }

  Future<void> _sendTestNotification(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _sendingTest = true);
    TestNotificationResult result;
    try {
      result = await NotificationService.instance.showTestNotification();
    } finally {
      if (mounted) setState(() => _sendingTest = false);
    }
    if (!mounted) return;
    if (result == TestNotificationResult.success) {
      await _rescheduleIfEnabled(ref);
    }
    final message = switch (result) {
      TestNotificationResult.success => l10n.testNotificationSuccess,
      TestNotificationResult.permissionDenied => l10n.testNotificationFailed,
      TestNotificationResult.notInitialized => l10n.testNotificationInitFailed,
      TestNotificationResult.timedOut => l10n.testNotificationTimedOut,
      TestNotificationResult.showFailed => l10n.testNotificationFailed,
    };
    messenger.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
