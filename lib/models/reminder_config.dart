import 'dart:convert';

import '../l10n/app_localizations.dart';

/// Sentinel used only in the reminder picker UI for the "Custom…" row.
const kReminderCustomPicker = -1;

/// Max reminders per event (also caps notification id suffix).
const kMaxRemindersPerEvent = 20;

/// Default reminder offsets in seconds before the due/start time.
class ReminderPresets {
  ReminderPresets._();

  static const List<int?> selectableValues = [
    0,
    5 * 60,
    10 * 60,
    15 * 60,
    20 * 60,
    30 * 60,
    60 * 60,
    2 * 60 * 60,
    24 * 60 * 60,
    kReminderCustomPicker,
  ];

  static bool hasReminder(List<int> offsets) => offsets.isNotEmpty;

  static Duration? toDuration(int offsetSeconds) =>
      Duration(seconds: offsetSeconds);

  /// Maps legacy enum storage strings to seconds (schema v3 → v4 migration).
  static int? fromLegacyStorage(String value) {
    return switch (value) {
      'none' => null,
      'atTime' => 0,
      'min5' => 5 * 60,
      'min10' => 10 * 60,
      'min15' => 15 * 60,
      'min30' => 30 * 60,
      'hour1' => 60 * 60,
      _ => null,
    };
  }
}

List<int> decodeReminderOffsets({
  String? json,
  int? legacySingleOffset,
}) {
  if (json != null && json.isNotEmpty) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded
            .whereType<num>()
            .map((n) => n.toInt())
            .where((n) => n >= 0)
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
      }
    } catch (_) {}
  }
  if (legacySingleOffset != null) return [legacySingleOffset];
  return const [];
}

String? encodeReminderOffsets(List<int> offsets) {
  if (offsets.isEmpty) return null;
  final unique = offsets.toSet().toList()..sort((a, b) => b.compareTo(a));
  return jsonEncode(unique);
}

int notificationIdForEvent(int eventId, int index) => eventId * 100 + index;

/// Human-readable relative reminder label for UI.
String formatReminderOffset(AppLocalizations l10n, int? offsetSeconds) {
  if (offsetSeconds == null) return l10n.reminderNone;
  if (offsetSeconds == 0) return l10n.reminderAtDueTime;

  if (offsetSeconds % (24 * 60 * 60) == 0) {
    final days = offsetSeconds ~/ (24 * 60 * 60);
    return l10n.reminderDaysBeforeDue(days);
  }
  if (offsetSeconds % (60 * 60) == 0) {
    final hours = offsetSeconds ~/ (60 * 60);
    return l10n.reminderHoursBeforeDue(hours);
  }
  if (offsetSeconds % 60 == 0) {
    final minutes = offsetSeconds ~/ 60;
    return l10n.reminderMinutesBeforeDue(minutes);
  }
  return l10n.reminderMinutesBeforeDue((offsetSeconds / 60).round());
}

String formatReminderOffsetsSummary(AppLocalizations l10n, List<int> offsets) {
  if (offsets.isEmpty) return l10n.reminderNone;
  final sorted = [...offsets]..sort((a, b) => b.compareTo(a));
  return sorted.map((o) => formatReminderOffset(l10n, o)).join(' · ');
}

/// Countdown until anchor time, e.g. "2 hours 15 minutes".
String formatDurationUntil(AppLocalizations l10n, Duration duration) {
  if (duration.isNegative || duration.inSeconds <= 0) {
    return l10n.timeUntilStartNow;
  }

  final days = duration.inDays;
  var remainder = duration - Duration(days: days);
  final hours = remainder.inHours;
  remainder -= Duration(hours: hours);
  final minutes = remainder.inMinutes;

  if (days > 0) {
    if (hours > 0) return l10n.timeUntilStartDaysHours(days, hours);
    return l10n.timeUntilStartDays(days);
  }
  if (hours > 0) {
    if (minutes > 0) return l10n.timeUntilStartHoursMinutes(hours, minutes);
    return l10n.timeUntilStartHours(hours);
  }
  if (minutes > 0) return l10n.timeUntilStartMinutes(minutes);
  return l10n.timeUntilStartNow;
}

/// Notification body suffix: time remaining until event start at fire time.
String formatNotificationTimeUntilStart(AppLocalizations l10n, int offsetSeconds) {
  if (offsetSeconds <= 0) return l10n.timeUntilStartNow;
  return formatDurationUntil(l10n, Duration(seconds: offsetSeconds));
}
