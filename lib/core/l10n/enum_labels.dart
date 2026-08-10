import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';

String repeatTypeLabel(AppLocalizations l10n, RepeatType type) {
  return switch (type) {
    RepeatType.oneTime => l10n.repeatOneTime,
    RepeatType.daily => l10n.repeatDaily,
    RepeatType.weekly => l10n.repeatWeekly,
    RepeatType.monthly => l10n.repeatMonthly,
  };
}

String focusModeLabel(AppLocalizations l10n, FocusMode mode) {
  return switch (mode) {
    FocusMode.pomodoro => l10n.focusPomodoro,
    FocusMode.stopwatch => l10n.focusStopwatch,
  };
}

String focusEnforcementLabel(
  AppLocalizations l10n,
  FocusEnforcementMode mode,
) {
  return switch (mode) {
    FocusEnforcementMode.normal => l10n.focusEnforcementNormal,
    FocusEnforcementMode.strict => l10n.focusEnforcementStrict,
  };
}
