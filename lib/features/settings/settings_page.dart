import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/feedback_form_url.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/focus_providers.dart';
import '../../core/utils/launch_external_url.dart';
import '../../l10n/app_localizations.dart';
import 'about_settings_page.dart';
import 'appearance_settings_page.dart';
import 'focus_settings_page.dart';
import 'general_settings_page.dart';
import 'language_settings_page.dart';
import 'notification_settings_page.dart';
import 'widget_settings_page.dart';
import 'settings_summaries.dart';
import 'widgets/settings_widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final remindersEnabled = ref.watch(remindersEnabledProvider);
    final language = ref.watch(appLanguageProvider);
    final defaultCountdown = ref.watch(defaultCountdownSecondsProvider);
    final appVersion = ref.watch(packageInfoProvider).version;

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
            const SizedBox(height: 20),
            SettingsGroup(
              children: [
                SettingsNavTile(
                  icon: Icons.palette_outlined,
                  title: l10n.settingsAppearance,
                  trailingText:
                      settingsAppearanceSummary(l10n, themeMode),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AppearanceSettingsPage(),
                    ),
                  ),
                ),
                SettingsNavTile(
                  icon: Icons.notifications_outlined,
                  title: l10n.settingsNotifications,
                  trailingText:
                      settingsNotificationsSummary(l10n, remindersEnabled),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NotificationSettingsPage(),
                    ),
                  ),
                ),
                SettingsNavTile(
                  icon: Icons.timer_outlined,
                  title: l10n.settingsFocus,
                  trailingText:
                      settingsFocusSummary(l10n, defaultCountdown),
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
                  icon: Icons.widgets_outlined,
                  title: l10n.settingsWidgets,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const WidgetSettingsPage(),
                    ),
                  ),
                ),
                SettingsNavTile(
                  icon: Icons.tune_outlined,
                  title: l10n.settingsGeneral,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const GeneralSettingsPage(),
                    ),
                  ),
                ),
                SettingsNavTile(
                  icon: Icons.feedback_outlined,
                  title: l10n.settingsFeedback,
                  onTap: () async {
                    final opened = await launchExternalUrl(
                      resolveFeedbackFormUrl(ref.read(appLanguageProvider)),
                    );
                    if (!context.mounted) return;
                    if (!opened) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(l10n.settingsFeedbackOpenFailed),
                        ),
                      );
                    }
                  },
                ),
                SettingsNavTile(
                  icon: Icons.info_outline_rounded,
                  title: l10n.settingsAbout,
                  trailingText: l10n.settingsVersionLabel(appVersion),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const AboutSettingsPage(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
