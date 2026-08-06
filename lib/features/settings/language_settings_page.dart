import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/l10n_providers.dart';
import '../../core/services/initial_data_seeder.dart';
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
                onChanged: (value) async {
                  if (value == null) return;
                  await ref.read(appLanguageProvider.notifier).setLanguage(value);
                  try {
                    await InitialDataSeeder.syncOnboardingLanguage(
                      repo: ref.read(eventRepositoryProvider),
                      l10n: lookupAppLocalizations(resolveAppLocale(value)),
                    );
                  } catch (e, st) {
                    debugPrint('Initial data language sync failed: $e\n$st');
                  }
                },
              ),
            )
            .toList(),
      ),
    );
  }
}
