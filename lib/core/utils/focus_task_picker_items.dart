import '../../models/enums.dart';
import '../../models/event.dart';
import 'date_time_formats.dart';
import 'repeat_expander.dart';

enum FocusTaskPickerSectionKind {
  todaySchedules,
  todayTodos,
  longTermTodos,
  otherDateTodos,
}

class FocusTaskPickerSection {
  const FocusTaskPickerSection({
    required this.kind,
    required this.items,
  });

  final FocusTaskPickerSectionKind kind;
  final List<Event> items;
}

/// Builds grouped task lists for the focus task picker.
class FocusTaskPickerItems {
  FocusTaskPickerItems._();

  static const _pastDays = 365;
  static const _futureDays = 365;

  static List<FocusTaskPickerSection> build(
    List<Event> allEvents, {
    required DateTime today,
  }) {
    final todayKey = DateTimeFormats.formatDate(today);
    final active = allEvents.where((e) => !e.isRepeatSkip).toList();
    final todayExpanded = RepeatExpander.expandForDate(active, today);

    final todaySchedules = todayExpanded
        .where((e) => e.isSchedule && !e.isCompleted)
        .toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final todayTodos = todayExpanded
        .where((e) => e.isTodo && !e.isNoTimeTodo && !e.isCompleted)
        .toList()
      ..sort((a, b) {
        final time = a.startTime.compareTo(b.startTime);
        return time != 0 ? time : a.title.compareTo(b.title);
      });

    final longTermTodos = active
        .where((e) => e.isNoTimeTodo && !e.isCompleted)
        .toList()
      ..sort((a, b) => a.title.compareTo(b.title));

    final otherDateTodos = _otherDateTodos(active, today, todayKey);

    return [
      FocusTaskPickerSection(
        kind: FocusTaskPickerSectionKind.todaySchedules,
        items: todaySchedules,
      ),
      FocusTaskPickerSection(
        kind: FocusTaskPickerSectionKind.todayTodos,
        items: todayTodos,
      ),
      FocusTaskPickerSection(
        kind: FocusTaskPickerSectionKind.longTermTodos,
        items: longTermTodos,
      ),
      FocusTaskPickerSection(
        kind: FocusTaskPickerSectionKind.otherDateTodos,
        items: otherDateTodos,
      ),
    ];
  }

  static List<Event> _otherDateTodos(
    List<Event> active,
    DateTime today,
    String todayKey,
  ) {
    final start = today.subtract(const Duration(days: _pastDays));
    final end = today.add(const Duration(days: _futureDays));
    final expanded = RepeatExpander.expandForRange(active, start, end);

    final candidates = <Event>[];

    for (final event in expanded) {
      if (!_isDatedTodoOnOtherDay(event, todayKey)) continue;
      candidates.add(event);
    }

    for (final event in active) {
      if (!_isDatedTodoOnOtherDay(event, todayKey)) continue;
      if (event.repeatType != RepeatType.oneTime &&
          (event.repeatGroupId != null || event.isRecurring)) {
        continue;
      }
      candidates.add(event);
    }

    final deduped = _dedupeOtherDateTodos(candidates, todayKey);
    deduped.sort((a, b) => _compareByNearestDate(a, b, todayKey));
    return deduped;
  }

  static bool _isDatedTodoOnOtherDay(Event event, String todayKey) {
    return event.isTodo &&
        !event.isNoTimeTodo &&
        !event.isCompleted &&
        event.hasDate &&
        event.date != todayKey;
  }

  static List<Event> _dedupeOtherDateTodos(
    List<Event> candidates,
    String todayKey,
  ) {
    final bestByKey = <String, Event>{};

    for (final event in candidates) {
      final key = _dedupeKey(event);
      final existing = bestByKey[key];
      if (existing == null ||
          _dayDistance(event.date, todayKey) <
              _dayDistance(existing.date, todayKey)) {
        bestByKey[key] = event;
      } else if (_dayDistance(event.date, todayKey) ==
              _dayDistance(existing.date, todayKey) &&
          event.date.compareTo(existing.date) < 0) {
        bestByKey[key] = event;
      }
    }

    return bestByKey.values.toList();
  }

  static String _dedupeKey(Event event) {
    if (event.repeatType != RepeatType.oneTime) {
      if (event.repeatGroupId != null) {
        return 'series:${event.repeatGroupId}';
      }
      return 'series:id:${event.id}';
    }
    return 'event:${event.id}';
  }

  static int _dayDistance(String dateKey, String todayKey) {
    final date = DateTime.parse(dateKey);
    final today = DateTime.parse(todayKey);
    return date.difference(today).inDays.abs();
  }

  static int _compareByNearestDate(Event a, Event b, String todayKey) {
    final distance = _dayDistance(a.date, todayKey)
        .compareTo(_dayDistance(b.date, todayKey));
    if (distance != 0) return distance;
    return a.date.compareTo(b.date);
  }
}
