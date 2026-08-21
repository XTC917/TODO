import '../../models/enums.dart';
import '../../models/event.dart';
import 'date_time_formats.dart';

/// Expands recurring master events into virtual instances for display.
class RepeatExpander {
  RepeatExpander._();

  static List<Event> expandForDate(List<Event> all, DateTime date) {
    final key = DateTimeFormats.formatDate(date);
    final result = <Event>[];

    for (final event in all) {
      if (event.isRepeatSkip) continue;
      if (event.date != key) continue;

      final groupId = event.repeatGroupId;
      if (groupId != null &&
          event.repeatType != RepeatType.oneTime &&
          _hasSkipOnDate(all, groupId, key)) {
        continue;
      }
      if (groupId != null &&
          event.repeatType != RepeatType.oneTime &&
          _hasOneTimeOverrideOnDate(all, groupId, key)) {
        continue;
      }
      result.add(event);
    }

    // Only the series master may generate virtual instances.
    for (final template in _seriesTemplatesByGroup(all).values) {
      if (template.isRepeatSkip || template.date == key) continue;
      if (_hasSkipOnDate(all, template.repeatGroupId!, key)) continue;
      if (_occursOn(template, date) &&
          !_hasConcreteInstance(all, template, key)) {
        result.add(_virtualOccurrence(template, key));
      }
    }

    // Legacy rows: recurring master without a repeat group id.
    for (final event in all) {
      if (event.isRepeatSkip || event.repeatGroupId != null) continue;
      if (event.repeatType == RepeatType.oneTime || event.date == key) continue;
      if (_occursOn(event, date)) {
        result.add(_virtualOccurrence(event, key));
      }
    }

    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
  }

  static Map<String, Event> _seriesTemplatesByGroup(List<Event> all) {
    final grouped = <String, List<Event>>{};
    for (final event in all) {
      final groupId = event.repeatGroupId;
      if (groupId == null) continue;
      grouped.putIfAbsent(groupId, () => []).add(event);
    }

    final templates = <String, Event>{};
    for (final entry in grouped.entries) {
      final masters = entry.value
          .where((row) => row.repeatType != RepeatType.oneTime)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (masters.isEmpty) continue;
      templates[entry.key] = masters.first;
    }
    return templates;
  }

  static bool _hasSkipOnDate(List<Event> all, String groupId, String dateKey) {
    return all.any(
      (e) =>
          e.isRepeatSkip &&
          e.repeatGroupId == groupId &&
          e.date == dateKey,
    );
  }

  static bool _hasOneTimeOverrideOnDate(
    List<Event> all,
    String groupId,
    String dateKey,
  ) {
    return all.any(
      (e) =>
          !e.isRepeatSkip &&
          e.repeatGroupId == groupId &&
          e.date == dateKey &&
          e.repeatType == RepeatType.oneTime,
    );
  }

  static List<Event> expandForRange(
    List<Event> all,
    DateTime start,
    DateTime end,
  ) {
    final result = <Event>[];
    var cursor = DateTimeFormats.dateOnly(start);
    final last = DateTimeFormats.dateOnly(end);
    while (!cursor.isAfter(last)) {
      result.addAll(expandForDate(all, cursor));
      cursor = cursor.add(const Duration(days: 1));
    }
    return result;
  }

  static bool occursOnDraft(EventDraft draft, DateTime date) {
    return occursOn(
      Event(
        id: 0,
        title: draft.title,
        date: draft.date,
        startTime: draft.startTime,
        endTime: draft.endTime,
        color: draft.color,
        taskType: draft.taskType,
        todoTimeMode: draft.todoTimeMode,
        isCompleted: false,
        repeatType: draft.repeatType,
        reminderOffsetsSeconds: const [],
        focusedSeconds: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      date,
    );
  }

  static bool occursOn(Event master, DateTime date) => _occursOn(master, date);

  /// Next occurrence that still has a reminder in the future, or null.
  static Event? reminderSource(
    Event event,
    List<Event> seriesOrAll, {
    DateTime? from,
  }) {
    final sources = reminderSources(event, seriesOrAll, from: from);
    return sources.isEmpty ? null : sources.first;
  }

  /// Upcoming occurrences to pre-schedule as one-shot alarms.
  ///
  /// Recurring masters skip dates that already have a one-time override or a
  /// skip marker, and skip occurrences whose reminder time has already passed.
  static List<Event> reminderSources(
    Event event,
    List<Event> seriesOrAll, {
    DateTime? from,
    int? limit,
  }) {
    if (event.isRepeatSkip) return const [];
    final now = from ?? DateTime.now();
    if (!event.isRecurring) {
      return _hasFutureReminderTrigger(event, now) ? [event] : const [];
    }

    final max = limit ?? _lookaheadFor(event);
    final groupId = event.repeatGroupId!;
    final today = DateTime(now.year, now.month, now.day);
    final seriesStart = DateTime.parse(event.date);
    final seriesStartDay =
        DateTime(seriesStart.year, seriesStart.month, seriesStart.day);
    var day = today.isBefore(seriesStartDay) ? seriesStartDay : today;
    final result = <Event>[];

    for (var i = 0; i < 800 && result.length < max; i++) {
      final candidate = day.add(Duration(days: i));
      if (!_occursOn(event, candidate)) continue;
      final key = DateTimeFormats.formatDate(candidate);
      if (_hasSkipOnDate(seriesOrAll, groupId, key)) continue;
      if (_hasOneTimeOverrideOnDate(seriesOrAll, groupId, key)) continue;
      final sourced = event.copyWith(
        date: key,
        isCompleted: false,
        clearCompletedAt: true,
        note: event.userNote,
        clearRepeatUntil: true,
      );
      if (!_hasFutureReminderTrigger(sourced, now)) continue;
      result.add(sourced);
    }
    return result;
  }

  static int _lookaheadFor(Event event) {
    return switch (event.repeatType) {
      RepeatType.daily => 21,
      RepeatType.weekly => 12,
      RepeatType.monthly => 6,
      RepeatType.oneTime => 1,
    };
  }

  static bool _hasFutureReminderTrigger(Event event, DateTime now) {
    final anchor = event.reminderAnchorDateTime;
    if (anchor == null) return false;
    if (event.reminderOffsetsSeconds.isEmpty) return false;
    for (final seconds in event.reminderOffsetsSeconds) {
      if (anchor.subtract(Duration(seconds: seconds)).isAfter(now)) {
        return true;
      }
    }
    return false;
  }

  static bool _occursOn(Event master, DateTime date) {
    final masterDate = DateTime.parse(master.date);
    final day = DateTime(date.year, date.month, date.day);
    final startDay = DateTime(masterDate.year, masterDate.month, masterDate.day);
    if (day.isBefore(startDay)) {
      return false;
    }
    final untilKey = master.seriesRepeatUntil;
    if (untilKey != null && untilKey.isNotEmpty) {
      final until = DateTime.parse(untilKey);
      final untilDay = DateTime(until.year, until.month, until.day);
      if (day.isAfter(untilDay)) {
        return false;
      }
    }

    return switch (master.repeatType) {
      RepeatType.oneTime => false,
      RepeatType.daily => true,
      RepeatType.weekly => masterDate.weekday == date.weekday,
      RepeatType.monthly => masterDate.day == date.day,
    };
  }

  static bool _hasConcreteInstance(
    List<Event> all,
    Event master,
    String dateKey,
  ) {
    if (master.repeatGroupId == null) return false;
    return all.any(
      (e) => e.repeatGroupId == master.repeatGroupId && e.date == dateKey,
    );
  }

  /// Virtual rows must not inherit completion or internal series metadata.
  static Event _virtualOccurrence(Event template, String dateKey) {
    return template.copyWith(
      date: dateKey,
      isCompleted: false,
      clearCompletedAt: true,
      note: template.userNote,
      clearRepeatUntil: true,
    );
  }
}
