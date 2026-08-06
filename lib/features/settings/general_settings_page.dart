import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/services/database_backup_service.dart';
import '../../core/services/notification_service.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class GeneralSettingsPage extends ConsumerWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final showSample = ref.watch(showSampleDataProvider);
    final muted =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return SettingsSubpageScaffold(
      title: l10n.settingsGeneral,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsGroup(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.auto_stories_outlined, size: 22),
                title: Text(l10n.settingsShowSampleData),
                subtitle: Text(
                  l10n.settingsShowSampleDataHint,
                  style: TextStyle(color: muted),
                ),
                value: showSample,
                onChanged: (enabled) =>
                    _onSampleDataChanged(context, ref, enabled),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.upload_file_rounded, size: 22),
                title: Text(l10n.exportDatabase),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _export(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded, size: 22),
                title: Text(l10n.importDatabase),
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () => _import(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onSampleDataChanged(
    BuildContext context,
    WidgetRef ref,
    bool enabled,
  ) async {
    if (enabled) {
      await ref.read(showSampleDataProvider.notifier).setEnabled(true);
      return;
    }

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsHideSampleDataTitle),
        content: Text(l10n.settingsHideSampleDataMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsHideSampleDataConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(showSampleDataProvider.notifier).setEnabled(false);
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

    final backup = ref.read(databaseBackupProvider);
    List<int> bytes;
    try {
      final picked = await backup.pickDatabaseBytes();
      if (picked == null) return;
      bytes = picked;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importFailed('$e'))),
      );
      return;
    }

    try {
      final db = ref.read(appDatabaseProvider);
      await db.close();
      ref.invalidate(appDatabaseProvider);
      await DatabaseBackupService.replaceDatabaseFile(bytes);
      await reopenDatabase(ref);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.importFailed('$e'))),
      );
      return;
    }

    try {
      if (ref.read(remindersEnabledProvider) &&
          await NotificationService.instance.hasPermission()) {
        await NotificationService.instance.rescheduleAll(
          ref.read(eventRepositoryProvider),
        );
      }
    } catch (e) {
      debugPrint('Reschedule after import failed (data imported): $e');
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.importSuccess)),
    );
  }
}
