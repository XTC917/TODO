import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/settings_widgets.dart';

class AboutSettingsPage extends ConsumerWidget {
  const AboutSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appVersion = ref.watch(packageInfoProvider).version;
    final muted = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.55);

    return SettingsSubpageScaffold(
      title: l10n.settingsAbout,
      body: SettingsGroup(
        children: [
          ListTile(
            leading: const Icon(Icons.apps_rounded, size: 22),
            title: Text(l10n.settingsAppName),
            subtitle: Text(l10n.appTitle),
          ),
          ListTile(
            leading: const Icon(Icons.new_releases_outlined, size: 22),
            title: Text(l10n.settingsVersion),
            subtitle: Text(appVersion),
          ),
          if (AppConfig.githubUrl.isNotEmpty)
            ListTile(
              leading: const Icon(Icons.code_outlined, size: 22),
              title: Text(l10n.settingsGitHub),
              subtitle: Text(
                AppConfig.githubUrl,
                style: TextStyle(color: muted),
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () {
                Clipboard.setData(ClipboardData(text: AppConfig.githubUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.settingsGitHubCopied)),
                );
              },
            ),
          ListTile(
            leading: const Icon(Icons.article_outlined, size: 22),
            title: Text(l10n.settingsLicenses),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: appVersion,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined, size: 22),
            title: Text(l10n.settingsPrivacyPolicy),
            subtitle: Text(
              l10n.aboutLegalese,
              style: TextStyle(color: muted),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, size: 22),
            title: Text(l10n.about),
            trailing: const Icon(Icons.chevron_right, size: 20),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: l10n.appTitle,
              applicationVersion: appVersion,
              applicationLegalese: l10n.aboutLegalese,
            ),
          ),
        ],
      ),
    );
  }
}
