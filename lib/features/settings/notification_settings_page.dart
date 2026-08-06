import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                if (!granted)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () async {
                          await AppSettings.openAppSettings(
                            type: AppSettingsType.notification,
                          );
                          ref.invalidate(notificationPermissionProvider);
                        },
                        child: Text(l10n.openNotificationSettings),
                      ),
                    ),
                  ),
                if (granted) ...[
                  FutureBuilder<int>(
                    future: NotificationService.instance.pendingCount(),
                    builder: (context, snapshot) {
                      final count = snapshot.data;
                      if (count == null) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        child: Text(
                          l10n.pendingNotifications(count),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      onPressed: () => _sendTestNotification(context, ref),
                      icon: const Icon(Icons.notifications_active),
                      label: Text(l10n.testNotificationNow),
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
                  ref.invalidate(notificationPermissionProvider);
                },
                child: Text(l10n.openNotificationSettings),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final ok = await NotificationService.instance.showTestNotification();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? l10n.testNotificationSuccess : l10n.testNotificationFailed,
        ),
      ),
    );
  }
}
