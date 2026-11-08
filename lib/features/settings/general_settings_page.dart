import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/focus_providers.dart';
import '../../l10n/app_localizations.dart';
import 'data_settings_page.dart';
import 'default_reminder_settings_page.dart';
import 'focus_settings_page.dart';
import 'language_settings_page.dart';
import 'settings_summaries.dart';
import 'widgets/settings_widgets.dart';

class GeneralSettingsPage extends ConsumerWidget {
  const GeneralSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(appLanguageProvider);
    final defaultCountdown = ref.watch(defaultCountdownSecondsProvider);
    final defaultReminderOffsets = ref.watch(defaultReminderOffsetsProvider);

    return SettingsSubpageScaffold(
      title: l10n.settingsGeneral,
      body: SettingsGroup(
        children: [
          SettingsNavTile(
            icon: Icons.timer_outlined,
            title: l10n.settingsFocus,
            trailingText: settingsFocusSummary(l10n, defaultCountdown),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const FocusSettingsPage(),
              ),
            ),
          ),
          SettingsNavTile(
            icon: Icons.language_outlined,
            title: l10n.settingsLanguage,
            trailingText: settingsLanguageSummary(l10n, language),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const LanguageSettingsPage(),
              ),
            ),
          ),
          SettingsNavTile(
            icon: Icons.notifications_active_outlined,
            title: l10n.settingsDefaultReminder,
            trailingText:
                settingsDefaultReminderSummary(l10n, defaultReminderOffsets),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DefaultReminderSettingsPage(),
              ),
            ),
          ),
          SettingsNavTile(
            icon: Icons.import_export_rounded,
            title: l10n.settingsDataBackup,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const DataSettingsPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
