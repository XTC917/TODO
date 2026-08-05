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
      if (event.date == key) {
        result.add(event);
        continue;
      }
      if (event.repeatType != RepeatType.oneTime &&
          occursOnDraft(event, date) &&
          !_hasConcreteInstance(all, event, key)) {
        result.add(event.copyWith(date: key));
      }
    }

    result.sort((a, b) => a.startTime.compareTo(b.startTime));
    return result;
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

  static bool occursOn(EventDraft draft, DateTime date) =>
      occursOnDraft(
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

  static bool occursOnDraft(Event master, DateTime date) {
    final masterDate = DateTime.parse(master.date);
    if (date.isBefore(DateTime(masterDate.year, masterDate.month, masterDate.day))) {
      return false;
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
}
