import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import 'settings_summaries.dart';
import 'widgets/settings_widgets.dart';

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(appLanguageProvider);

    return SettingsSubpageScaffold(
      title: l10n.settingsLanguage,
      body: SettingsGroup(
        children: AppLanguage.values
            .map(
              (lang) => RadioListTile<AppLanguage>(
                title: Text(languageLabel(l10n, lang)),
                value: lang,
                groupValue: language,
                onChanged: (value) {
                  if (value != null) {
                    ref.read(appLanguageProvider.notifier).setLanguage(value);
                  }
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
