import '../../l10n/app_localizations.dart';
import '../../models/focus_session.dart';

/// Formats focus countdown/stopwatch display for the focus page clock.
class FocusDisplayFormatter {
  FocusDisplayFormatter._();

  static String formatClock(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String formatDurationLabel(
    AppLocalizations l10n,
    int totalSeconds,
    FocusDurationDisplayMode mode,
  ) {
    if (totalSeconds <= 0) return formatClock(0);
    final totalMinutes = (totalSeconds / 60).round();
    if (mode == FocusDurationDisplayMode.minute) {
      return l10n.focusDurationMinutesOnly(totalMinutes);
    }
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    if (hours > 0 && minutes > 0) {
      return l10n.focusDurationHoursMinutes(hours, minutes);
    }
    if (hours > 0) return l10n.focusDurationHours(hours);
    return l10n.focusDurationMinutesOnly(minutes);
  }

  static String formatChipLabel(
    AppLocalizations l10n,
    int totalSeconds,
    FocusDurationDisplayMode mode,
  ) {
    return formatDurationLabel(l10n, totalSeconds, mode);
  }
}
