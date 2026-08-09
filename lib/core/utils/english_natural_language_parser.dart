import 'package:flutter/material.dart';

import '../../models/enums.dart';
import 'parsed_task.dart';

/// Rule-based English quick-add parser. Conservative: no guessed times.
class EnglishNaturalLanguageParser {
  const EnglishNaturalLanguageParser();

  static const _weekdays = {
    'monday': DateTime.monday,
    'tuesday': DateTime.tuesday,
    'wednesday': DateTime.wednesday,
    'thursday': DateTime.thursday,
    'friday': DateTime.friday,
    'saturday': DateTime.saturday,
    'sunday': DateTime.sunday,
  };

  ParsedTask parse(String input, {DateTime? reference}) {
    final ref = _dateOnly(reference ?? DateTime.now());
    final raw = input.trim();
    if (raw.isEmpty) {
      return ParsedTask(
        rawInput: raw,
        title: '',
        taskType: TaskType.todo,
        todoTimeMode: TodoTimeMode.noTime,
        reminderOffsetsSeconds: const [],
      );
    }

    final normalized = _normalize(raw);
    final removals = <_Span>[];

    final explicitType = _extractExplicitTaskType(normalized, removals);
    final date = _extractDate(normalized, ref, removals);
    final range = _extractTimeRange(normalized, removals);
    final single = range == null ? _extractSingleTime(normalized, removals) : null;

    final startTime = range?.start ?? single;
    final endTime = range?.end;
    final isDeadline = _hasDeadlineHint(normalized, removals);

    final taskType = explicitType ??
        ((startTime != null || endTime != null)
            ? TaskType.schedule
            : TaskType.todo);

    final todoTimeMode = _resolveTodoTimeMode(
      taskType: taskType,
      hasDate: date != null,
      isDeadline: isDeadline,
      hasSpecificTime: startTime != null,
    );

    final reminderOffsets = _extractReminders(
      normalized,
      removals,
      canSchedule: _canScheduleReminder(
        taskType: taskType,
        todoTimeMode: todoTimeMode,
        startTime: startTime,
        endTime: endTime,
      ),
    );

    var title = _buildTitle(normalized, removals);
    if (title.isEmpty) title = raw;

    return ParsedTask(
      rawInput: raw,
      title: title,
      date: date,
      startTime: startTime,
      endTime: endTime,
      taskType: taskType,
      todoTimeMode: todoTimeMode,
      reminderOffsetsSeconds: reminderOffsets,
    );
  }

  bool _canScheduleReminder({
    required TaskType taskType,
    required TodoTimeMode todoTimeMode,
    required TimeOfDay? startTime,
    required TimeOfDay? endTime,
  }) {
    if (taskType == TaskType.schedule && startTime != null) return true;
    if (todoTimeMode == TodoTimeMode.timeBlock && startTime != null) {
      return true;
    }
    if (todoTimeMode == TodoTimeMode.deadline &&
        (startTime != null || endTime != null)) {
      return true;
    }
    return false;
  }

  TodoTimeMode _resolveTodoTimeMode({
    required TaskType taskType,
    required bool hasDate,
    required bool isDeadline,
    required bool hasSpecificTime,
  }) {
    if (taskType == TaskType.schedule) return TodoTimeMode.timeBlock;
    if (!hasDate) return TodoTimeMode.noTime;
    if (hasSpecificTime) return TodoTimeMode.timeBlock;
    if (isDeadline) return TodoTimeMode.deadline;
    return TodoTimeMode.deadline;
  }

  TaskType? _extractExplicitTaskType(String text, List<_Span> removals) {
    final patterns = <(RegExp, TaskType)>[
      (
        RegExp(r'\badd a schedule\b', caseSensitive: false),
        TaskType.schedule,
      ),
      (
        RegExp(r'\bcreate a schedule\b', caseSensitive: false),
        TaskType.schedule,
      ),
      (
        RegExp(r'\badd a todo\b', caseSensitive: false),
        TaskType.todo,
      ),
      (
        RegExp(r'\bcreate a todo\b', caseSensitive: false),
        TaskType.todo,
      ),
    ];

    Match? best;
    TaskType? type;
    for (final (pattern, taskType) in patterns) {
      final m = pattern.firstMatch(text);
      if (m == null) continue;
      if (best == null || m.start < best.start) {
        best = m;
        type = taskType;
      }
    }
    if (best == null || type == null) return null;
    removals.add(_Span(best.start, best.end));
    return type;
  }

  bool _hasDeadlineHint(String text, List<_Span> removals) {
    const patterns = ['deadline', 'due by', 'due on'];
    final lower = text.toLowerCase();
    for (final p in patterns) {
      final i = lower.indexOf(p);
      if (i >= 0) {
        removals.add(_Span(i, i + p.length));
        return true;
      }
    }
    return false;
  }

  String _normalize(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _extractDate(String text, DateTime ref, List<_Span> removals) {
    final patterns = <RegExp>[
      RegExp(
        r'\bnext\s+(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        caseSensitive: false,
      ),
      RegExp(
        r'\b(monday|tuesday|wednesday|thursday|friday|saturday|sunday)\b',
        caseSensitive: false,
      ),
      RegExp(r'\bday after tomorrow\b', caseSensitive: false),
      RegExp(r'\btomorrow\b', caseSensitive: false),
      RegExp(r'\btonight\b', caseSensitive: false),
      RegExp(r'\btoday\b', caseSensitive: false),
    ];

    Match? best;
    RegExp? bestPattern;
    for (final p in patterns) {
      for (final m in p.allMatches(text)) {
        if (best == null || m.start < best.start) {
          best = m;
          bestPattern = p;
        }
      }
    }
    if (best == null || bestPattern == null) return null;

    removals.add(_Span(best.start, best.end));
    final token = best.group(0)!;
    final tokenLower = token.toLowerCase();

    if (tokenLower == 'day after tomorrow') {
      return ref.add(const Duration(days: 2));
    }
    if (tokenLower == 'tomorrow') {
      return ref.add(const Duration(days: 1));
    }
    if (tokenLower == 'today' || tokenLower == 'tonight') {
      return ref;
    }

    final weekdayName = best.group(1)!.toLowerCase();
    final target = _weekdays[weekdayName];
    if (target == null) return null;

    final isNextWeek = bestPattern.pattern.contains('next');
    return _dateOfNextWeekday(ref, target, nextWeek: isNextWeek);
  }

  DateTime _dateOfNextWeekday(
    DateTime ref,
    int targetWeekday, {
    required bool nextWeek,
  }) {
    if (nextWeek) {
      final startOfWeek = ref.subtract(Duration(days: ref.weekday - 1));
      final startOfNextWeek = startOfWeek.add(const Duration(days: 7));
      return startOfNextWeek.add(Duration(days: targetWeekday - 1));
    }
    final delta = (targetWeekday - ref.weekday + 7) % 7;
    return ref.add(Duration(days: delta));
  }

  _TimeRange? _extractTimeRange(String text, List<_Span> removals) {
    final patterns = <(RegExp, bool)>[
      (
        RegExp(
          r'\bfrom\s+(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s+to\s+'
          r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
          caseSensitive: false,
        ),
        true,
      ),
      (
        RegExp(
          r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\s+to\s+'
          r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
          caseSensitive: false,
        ),
        true,
      ),
      (
        RegExp(
          r'\b(\d{1,2})(?::(\d{2}))?\s*(?:to|-)\s*'
          r'(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
          caseSensitive: false,
        ),
        false,
      ),
    ];

    Match? best;
    _TimeRange? bestRange;

    for (final (pattern, bothMeridiem) in patterns) {
      for (final m in pattern.allMatches(text)) {
        final range = bothMeridiem
            ? _rangeWithMeridiem(m)
            : _rangeWithSharedMeridiem(m);
        if (range == null) continue;
        if (best == null || m.end - m.start > best.end - best.start) {
          best = m;
          bestRange = range;
        }
      }
    }

    if (best == null || bestRange == null) return null;
    removals.add(_Span(best.start, best.end));
    return bestRange;
  }

  _TimeRange? _rangeWithMeridiem(Match m) {
    final startMeridiem = (m.group(3) ?? m.group(6))?.toLowerCase();
    final start = _clockTime(
      hour: int.parse(m.group(1)!),
      minute: int.tryParse(m.group(2) ?? '') ?? 0,
      meridiem: startMeridiem,
    );
    final end = _clockTime(
      hour: int.parse(m.group(4)!),
      minute: int.tryParse(m.group(5) ?? '') ?? 0,
      meridiem: m.group(6)?.toLowerCase(),
    );
    if (start == null || end == null) return null;
    return _TimeRange(start: start, end: end);
  }

  _TimeRange? _rangeWithSharedMeridiem(Match m) {
    final meridiem = m.group(5)?.toLowerCase();
    final start = _clockTime(
      hour: int.parse(m.group(1)!),
      minute: int.tryParse(m.group(2) ?? '') ?? 0,
      meridiem: meridiem,
    );
    final end = _clockTime(
      hour: int.parse(m.group(3)!),
      minute: int.tryParse(m.group(4) ?? '') ?? 0,
      meridiem: meridiem,
    );
    if (start == null || end == null) return null;
    return _TimeRange(start: start, end: end);
  }

  TimeOfDay? _extractSingleTime(String text, List<_Span> removals) {
    final candidates = <(Match, TimeOfDay)>[];

    for (final m in RegExp(
      r'\b(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b',
      caseSensitive: false,
    ).allMatches(text)) {
      final time = _clockTime(
        hour: int.parse(m.group(1)!),
        minute: int.tryParse(m.group(2) ?? '') ?? 0,
        meridiem: m.group(3)?.toLowerCase(),
      );
      if (time != null) candidates.add((m, time));
    }

    for (final m in RegExp(r'\b(\d{1,2}):(\d{2})\b').allMatches(text)) {
      final hour = int.parse(m.group(1)!);
      final minute = int.parse(m.group(2)!);
      final time = _clockTime(hour: hour, minute: minute);
      if (time != null) candidates.add((m, time));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final len = (b.$1.end - b.$1.start).compareTo(a.$1.end - a.$1.start);
      if (len != 0) return len;
      return a.$1.start.compareTo(b.$1.start);
    });

    final best = candidates.first;
    removals.add(_Span(best.$1.start, best.$1.end));
    return best.$2;
  }

  TimeOfDay? _clockTime({
    required int hour,
    required int minute,
    String? meridiem,
    String? fallbackMeridiem,
  }) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    final period = meridiem ?? fallbackMeridiem;
    if (period == 'am') {
      if (hour == 12) hour = 0;
    } else if (period == 'pm') {
      if (hour >= 1 && hour <= 11) hour += 12;
    }
    if (hour > 23) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static const _reminderTriggers = ['remind me', 'notify me', 'alert me'];

  List<int> _extractReminders(
    String text,
    List<_Span> removals, {
    required bool canSchedule,
  }) {
    if (!canSchedule) return const [];
    final lower = text.toLowerCase();
    if (!_reminderTriggers.any(lower.contains)) return const [];

    final block = _findReminderBlock(text);
    if (block == null) return const [];

    final offsets = _parseReminderOffsets(block.text);
    if (offsets.isEmpty) return const [];

    removals.add(block.span);
    return offsets;
  }

  _ReminderBlock? _findReminderBlock(String text) {
    final patterns = [
      RegExp(
        r',\s*((?:remind|notify|alert)\s+me\b.+?\bbefore)\.?\s*$',
        caseSensitive: false,
      ),
      RegExp(
        r'\s((?:remind|notify|alert)\s+me\b.+?\bbefore)\.?\s*$',
        caseSensitive: false,
      ),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m == null) continue;
      return _ReminderBlock(text: m.group(1)!, span: _Span(m.start, m.end));
    }
    return null;
  }

  List<int> _parseReminderOffsets(String clause) {
    var body = clause.trim();
    body = body.replaceFirst(
      RegExp(r'^(?:remind|notify|alert)\s+me\s+', caseSensitive: false),
      '',
    );
    body = body.replaceFirst(
      RegExp(r'\s+before\.?$', caseSensitive: false),
      '',
    );
    body = body.trim();
    if (body.isEmpty) return const [];

    final parts = body.split(RegExp(r'\s+and\s+|,\s*', caseSensitive: false));
    final offsets = <int>{};
    for (final part in parts) {
      final seconds = _parseReminderOffsetPart(part);
      if (seconds != null && seconds > 0) offsets.add(seconds);
    }
    return offsets.toList()..sort((a, b) => b.compareTo(a));
  }

  int? _parseReminderOffsetPart(String part) {
    final token = part.trim().toLowerCase();
    if (token.isEmpty) return null;

    if (token.contains('half an hour') || token.contains('half hour')) {
      return 30 * 60;
    }

    final match = RegExp(
      r'(\d+|one|two|three|four|five|six|seven|eight|nine|ten|eleven|twelve|'
      r'fifteen|twenty|thirty|forty|forty-five|forty five|'
      r'fifty|sixty)\s*(minutes?|mins?|hours?|hrs?|days?)',
      caseSensitive: false,
    ).firstMatch(token);
    if (match != null) {
      final amount = _parseEnglishNumber(match.group(1)!);
      if (amount == null || amount <= 0) return null;
      final unit = match.group(2)!;
      if (unit.startsWith('min')) return amount * 60;
      if (unit.startsWith('hour') || unit.startsWith('hr')) {
        return amount * 3600;
      }
      if (unit.startsWith('day')) return amount * 86400;
    }
    return null;
  }

  int? _parseEnglishNumber(String token) {
    token = token.trim().toLowerCase();
    final digits = int.tryParse(token);
    if (digits != null) return digits;
    const words = {
      'one': 1,
      'two': 2,
      'three': 3,
      'four': 4,
      'five': 5,
      'six': 6,
      'seven': 7,
      'eight': 8,
      'nine': 9,
      'ten': 10,
      'eleven': 11,
      'twelve': 12,
      'fifteen': 15,
      'twenty': 20,
      'thirty': 30,
      'forty': 40,
      'forty-five': 45,
      'forty five': 45,
      'fifty': 50,
      'sixty': 60,
    };
    return words[token];
  }

  String _buildTitle(String text, List<_Span> removals) {
    removals.sort((a, b) => a.start.compareTo(b.start));
    final merged = <_Span>[];
    for (final s in removals) {
      if (merged.isEmpty || s.start > merged.last.end) {
        merged.add(s);
      } else if (s.end > merged.last.end) {
        merged[merged.length - 1] = _Span(merged.last.start, s.end);
      }
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final s in merged) {
      if (s.start > cursor) buffer.write(text.substring(cursor, s.start));
      cursor = s.end;
    }
    if (cursor < text.length) buffer.write(text.substring(cursor));

    var title = buffer
        .toString()
        .replaceAll(RegExp(r'^[,\s]+'), '')
        .replaceAll(RegExp(r'[,\s]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    for (final word in [' at ', ' from ', ' on ']) {
      if (title.endsWith(word.trim())) {
        title = title.substring(0, title.length - word.trim().length).trim();
      }
    }
    title = title.replaceAll(
      RegExp(r'^(?:for|on|at)\s*,?\s*', caseSensitive: false),
      '',
    );
    title = title.replaceAll(RegExp(r'[,.!?]+$'), '');
    return title.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;
}

class _TimeRange {
  const _TimeRange({required this.start, required this.end});
  final TimeOfDay start;
  final TimeOfDay end;
}

class _ReminderBlock {
  const _ReminderBlock({required this.text, required this.span});
  final String text;
  final _Span span;
}
