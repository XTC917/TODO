import 'package:flutter/material.dart';

import '../../core/providers/app_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/focus_session.dart';

String settingsAppearanceSummary(AppLocalizations l10n, ThemeMode mode) {
  return mode == ThemeMode.dark ? l10n.themeDark : l10n.themeLight;
}

String settingsNotificationsSummary(AppLocalizations l10n, bool enabled) {
  return enabled ? l10n.settingsStatusEnabled : l10n.settingsStatusDisabled;
}

String settingsFocusSummary(AppLocalizations l10n, int defaultSeconds) {
  final minutes = defaultSeconds ~/ 60;
  return l10n.focusMinutes(minutes);
}

String settingsLanguageSummary(AppLocalizations l10n, AppLanguage language) {
  return switch (language) {
    AppLanguage.system => l10n.languageSystem,
    AppLanguage.zh => l10n.languageZh,
    AppLanguage.en => l10n.languageEn,
    AppLanguage.ko => l10n.languageKo,
  };
}

String settingsDisplayModeSummary(
  AppLocalizations l10n,
  FocusDurationDisplayMode mode,
) {
  return mode == FocusDurationDisplayMode.hour
      ? l10n.settingsDisplayModeHour
      : l10n.settingsDisplayModeMinute;
}

String languageLabel(AppLocalizations l10n, AppLanguage language) {
  return settingsLanguageSummary(l10n, language);
}
