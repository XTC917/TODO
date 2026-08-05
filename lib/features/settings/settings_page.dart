import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);
    final isDark = themeMode == ThemeMode.dark;
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final language = ref.watch(appLanguageProvider);
    final permissionAsync = ref.watch(notificationPermissionProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text(
              l10n.settingsTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 24),
            _SectionCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ThemeButton(
                          label: l10n.themeLight,
                          selected: !isDark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.light),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ThemeButton(
                          label: l10n.themeDark,
                          selected: isDark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.dark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.accentColor,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: AccentColor.values.map((c) {
                          final selected = c == accent;
                          return GestureDetector(
                            onTap: () => ref
                                .read(accentColorProvider.notifier)
                                .setAccent(c),
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: c.seed,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                ListTile(
                  title: Text(l10n.language),
                  subtitle: Text(_languageLabel(l10n, language)),
                ),
                ...AppLanguage.values.map(
                  (lang) => RadioListTile<AppLanguage>(
                    title: Text(_languageLabel(l10n, lang)),
                    value: lang,
                    groupValue: language,
                    onChanged: (v) {
                      if (v != null) {
                        ref.read(appLanguageProvider.notifier).setLanguage(v);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    l10n.notifications,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                SwitchListTile(
                  title: Text(l10n.enableReminders),
                  value: remindersEnabled,
                  onChanged: (v) =>
                      ref.read(remindersEnabledProvider.notifier).setEnabled(v),
                ),
                const Divider(height: 1),
                permissionAsync.when(
                  data: (granted) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(
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
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _requestPermission(ref),
                                  child: Text(l10n.requestNotificationPermission),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextButton(
                                  onPressed: () async {
                                    await AppSettings.openAppSettings(
                                      type: AppSettingsType.notification,
                                    );
                                    ref.invalidate(
                                      notificationPermissionProvider,
                                    );
                                  },
                                  child: Text(l10n.openNotificationSettings),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (granted) ...[
                        FutureBuilder<int>(
                          future: NotificationService.instance.pendingCount(),
                          builder: (context, snapshot) {
                            final count = snapshot.data;
                            if (count == null) return const SizedBox.shrink();
                            return Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
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
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () => _sendTestNotification(
                                  context,
                                  ref,
                                  immediate: true,
                                ),
                                icon: const Icon(Icons.notifications_active),
                                label: Text(l10n.testNotificationNow),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () => _sendTestNotification(
                                  context,
                                  ref,
                                  immediate: false,
                                ),
                                icon: const Icon(Icons.timer_outlined),
                                label: Text(l10n.testNotificationScheduled),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  loading: () => const ListTile(
                    title: Text('…'),
                  ),
                  error: (_, __) => ListTile(
                    title: Text(l10n.notificationPermissionDenied),
                    trailing: TextButton(
                      onPressed: () => _requestPermission(ref),
                      child: Text(l10n.requestNotificationPermission),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_rounded),
                  title: Text(l10n.exportDatabase),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_rounded),
                  title: Text(l10n.importDatabase),
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: Text(l10n.about),
                  subtitle: Text(l10n.aboutSubtitle('2.0.5')),
                  onTap: () => showAboutDialog(
                    context: context,
                    applicationName: 'Soft Schedule',
                    applicationVersion: '2.0.5',
                    applicationLegalese: l10n.aboutLegalese,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _languageLabel(AppLocalizations l10n, AppLanguage language) {
    return switch (language) {
      AppLanguage.system => l10n.languageSystem,
      AppLanguage.zh => l10n.languageZh,
      AppLanguage.en => l10n.languageEn,
    };
  }

  Future<void> _requestPermission(WidgetRef ref) async {
    await NotificationService.instance.requestPermissions();
    ref.invalidate(notificationPermissionProvider);
    if (ref.read(remindersEnabledProvider) &&
        await NotificationService.instance.hasPermission()) {
      await NotificationService.instance.rescheduleAll(
        ref.read(eventRepositoryProvider),
      );
    }
  }

  Future<void> _sendTestNotification(
    BuildContext context,
    WidgetRef ref, {
    required bool immediate,
  }) async {
    final l10n = AppLocalizations.of(context);
    final ok = immediate
        ? await NotificationService.instance.showTestNotification()
        : await NotificationService.instance.scheduleTestNotification();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (immediate
                  ? l10n.testNotificationSuccess
                  : l10n.testNotificationScheduledSuccess)
              : l10n.testNotificationFailed,
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    try {
      final path = await ref.read(databaseBackupProvider).exportDatabase();
      if (!context.mounted || path == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportSuccess(path))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.exportFailed('$e'))),
      );
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.importTitle),
        content: Text(l10n.importMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.import),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(databaseBackupProvider).importDatabase();
      ref.invalidate(appDatabaseProvider);
      if (ref.read(remindersEnabledProvider) &&
          await NotificationService.instance.hasPermission()) {
        await NotificationService.instance.rescheduleAll(
          ref.read(eventRepositoryProvider),
        );
      }
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importSuccess)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importFailed('$e'))),
      );
    }
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
          : Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardTheme.color,
      borderRadius: BorderRadius.circular(22),
      child: Column(children: children),
    );
  }
}
