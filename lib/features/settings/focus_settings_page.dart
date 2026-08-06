import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/focus_providers.dart';
import '../../l10n/app_localizations.dart';
import 'settings_summaries.dart';
import 'widgets/settings_widgets.dart';

class FocusSettingsPage extends ConsumerWidget {
  const FocusSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final presets = ref.watch(focusPresetsProvider);
    final defaultCountdown = ref.watch(defaultCountdownSecondsProvider);
    final displayMode = ref.watch(focusDisplayModeProvider);
    final keepAwake = ref.watch(focusKeepAwakeProvider);
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return SettingsSubpageScaffold(
      title: l10n.settingsFocus,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsDefaultCountdown,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          SettingsGroup(
            children: presets
                .map(
                  (seconds) => RadioListTile<int>(
                    title: Text(l10n.focusMinutes(seconds ~/ 60)),
                    value: seconds,
                    groupValue: defaultCountdown,
                    onChanged: (value) {
                      if (value != null) {
                        ref
                            .read(defaultCountdownSecondsProvider.notifier)
                            .setDefault(value);
                        ref.read(selectedCountdownSecondsProvider.notifier)
                            .state = value;
                      }
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          SettingsGroup(
            children: [
              ListTile(
                leading: const Icon(Icons.schedule_outlined, size: 22),
                title: Text(l10n.settingsDefaultDisplayMode),
                subtitle: Text(
                  settingsDisplayModeSummary(l10n, displayMode),
                  style: TextStyle(color: muted),
                ),
                trailing: Switch(
                  value: displayMode == FocusDurationDisplayMode.minute,
                  onChanged: (_) => ref
                      .read(focusDisplayModeProvider.notifier)
                      .toggle(),
                ),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.light_mode_outlined, size: 22),
                title: Text(l10n.settingsKeepScreenAwake),
                subtitle: Text(
                  l10n.settingsKeepScreenAwakeHint,
                  style: TextStyle(color: muted),
                ),
                value: keepAwake,
                onChanged: (v) => ref
                    .read(focusKeepAwakeProvider.notifier)
                    .setEnabled(v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.settingsImmersiveModeHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: muted,
                    height: 1.4,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
