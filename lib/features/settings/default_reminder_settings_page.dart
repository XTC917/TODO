import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reminder_config.dart';
import 'widgets/settings_widgets.dart';

/// Sentinel radio value for "no reminder"; preset offsets use their seconds.
const _noReminderValue = -2;

class DefaultReminderSettingsPage extends ConsumerWidget {
  const DefaultReminderSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final offsets = ref.watch(defaultReminderOffsetsProvider);
    final selectedValue = offsets.isEmpty ? _noReminderValue : offsets.first;
    final presetValues = ReminderPresets.selectableValues
        .whereType<int>()
        .where((value) => value != kReminderCustomPicker)
        .toList();

    return SettingsSubpageScaffold(
      title: l10n.settingsDefaultReminder,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.settingsDefaultReminderHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SettingsGroup(
            children: [
              RadioListTile<int>(
                title: Text(l10n.reminderNone),
                value: _noReminderValue,
                groupValue: selectedValue,
                onChanged: (value) {
                  if (value != null) {
                    ref
                        .read(defaultReminderOffsetsProvider.notifier)
                        .setOffsets(const []);
                  }
                },
              ),
              ...presetValues.map(
                (offset) => RadioListTile<int>(
                  title: Text(formatReminderOffset(l10n, offset)),
                  value: offset,
                  groupValue: selectedValue,
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(defaultReminderOffsetsProvider.notifier)
                          .setOffsets([value]);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
