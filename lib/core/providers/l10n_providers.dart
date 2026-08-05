import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'app_providers.dart';

Locale resolveAppLocale(AppLanguage language) {
  return switch (language) {
    AppLanguage.zh => const Locale('zh'),
    AppLanguage.en => const Locale('en'),
    AppLanguage.ko => const Locale('ko'),
    AppLanguage.system => _deviceLocale(),
  };
}

Locale _deviceLocale() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return switch (code) {
    'zh' => const Locale('zh'),
    'ko' => const Locale('ko'),
    _ => const Locale('en'),
  };
}

/// Localizations tied to [appLanguageProvider], not only InheritedWidget.
final appLocalizationsProvider = Provider<AppLocalizations>((ref) {
  final language = ref.watch(appLanguageProvider);
  return lookupAppLocalizations(resolveAppLocale(language));
});
