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

String reminderTypeLabel(AppLocalizations l10n, ReminderType type) {
  return switch (type) {
    ReminderType.none => l10n.reminderNone,
    ReminderType.atTime => l10n.reminderAtTime,
    ReminderType.min5 => l10n.reminderMin5,
    ReminderType.min10 => l10n.reminderMin10,
    ReminderType.min15 => l10n.reminderMin15,
    ReminderType.min30 => l10n.reminderMin30,
    ReminderType.hour1 => l10n.reminderHour1,
  };
}

String focusModeLabel(AppLocalizations l10n, FocusMode mode) {
  return switch (mode) {
    FocusMode.pomodoro => l10n.focusPomodoro,
    FocusMode.stopwatch => l10n.focusStopwatch,
  };
}
