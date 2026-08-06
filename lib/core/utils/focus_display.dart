import '../../l10n/app_localizations.dart';
import '../../models/focus_session.dart';

/// Formats focus countdown/stopwatch display for the focus page clock.
class FocusDisplayFormatter {
  FocusDisplayFormatter._();

  /// Hour mode clock: always HH:MM:SS (e.g. 01:30:00, 00:30:00).
  static String formatHourModeClock(int totalSeconds) {
    final clamped = totalSeconds.clamp(0, 359999);
    final h = clamped ~/ 3600;
    final m = (clamped % 3600) ~/ 60;
    final s = clamped % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  /// Minute mode clock: total minutes and seconds (e.g. 90:00, 30:00).
  static String formatMinuteModeClock(int totalSeconds) {
    final clamped = totalSeconds.clamp(0, 359999);
    final totalMinutes = clamped ~/ 60;
    final s = clamped % 60;
    return '$totalMinutes:${s.toString().padLeft(2, '0')}';
  }

  /// Main timer — numeric clock, toggles between hour/minute modes.
  static String formatMainDisplay(
    int totalSeconds,
    FocusDurationDisplayMode mode,
  ) {
    if (mode == FocusDurationDisplayMode.minute) {
      return formatMinuteModeClock(totalSeconds);
    }
    return formatHourModeClock(totalSeconds);
  }

  static String formatDurationLabel(
    AppLocalizations l10n,
    int totalSeconds,
    FocusDurationDisplayMode mode,
  ) {
    if (totalSeconds <= 0) {
      return l10n.focusDurationMinutesOnly(0);
    }
    if (mode == FocusDurationDisplayMode.minute) {
      return l10n.focusDurationMinutesOnly(totalSeconds ~/ 60);
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
