import 'package:flutter/material.dart';

import '../../models/enums.dart';
import 'parsed_task.dart';

/// Rule-based Chinese quick-add parser. Conservative: no guessed times.
class ChineseNaturalLanguageParser {
  const ChineseNaturalLanguageParser();

  static const _weekdayChar = {
    '一': DateTime.monday,
    '二': DateTime.tuesday,
    '三': DateTime.wednesday,
    '四': DateTime.thursday,
    '五': DateTime.friday,
    '六': DateTime.saturday,
    '日': DateTime.sunday,
    '天': DateTime.sunday,
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
    final eveningContext = normalized.contains('今晚') || normalized.contains('今夜');

    final explicitType = _extractExplicitTaskType(normalized, removals);
    final date = _extractDate(normalized, ref, removals);
    final range = _extractTimeRange(normalized, removals);
    final single = range == null
        ? _extractSingleTime(normalized, removals, eveningContext: eveningContext)
        : null;

    var startTime = range?.start ?? single;
    var endTime = range?.end;
    final isDeadline = _hasDeadlineHint(normalized, removals);

    if (isDeadline && startTime != null && endTime == null) {
      endTime = startTime;
      startTime = null;
    }

    final taskType = explicitType ??
        (isDeadline
            ? TaskType.todo
            : ((startTime != null || endTime != null)
                ? TaskType.schedule
                : TaskType.todo));

    final todoTimeMode = _resolveTodoTimeMode(
      taskType: taskType,
      hasDate: date != null,
      isDeadline: isDeadline,
      hasDeadlineTime: endTime != null,
      hasBlockTime: startTime != null,
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

  static const _reminderTriggers = [
    '提前',
    '之前提醒',
    '通知我',
    '叫我',
    '提醒我',
  ];

  List<int> _extractReminders(
    String text,
    List<_Span> removals, {
    required bool canSchedule,
  }) {
    if (!canSchedule) return const [];
    if (!_reminderTriggers.any(text.contains)) return const [];

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
        r'[，,]\s*(提前[^，,；;]+?(?:提醒我|通知我|叫我|提醒)?)\s*$',
      ),
      RegExp(
        r'[，,]\s*([^，,；;]+?(?:提醒我|通知我|叫我))\s*$',
      ),
      RegExp(r'(提前[^，,；;]+?(?:提醒我|通知我|叫我|提醒)?)\s*$'),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m == null) continue;
      final clause = m.group(1)!;
      if (!clause.contains('提前') &&
          !clause.contains('提醒我') &&
          !clause.contains('通知我') &&
          !clause.contains('叫我') &&
          !clause.contains('之前提醒')) {
        continue;
      }
      return _ReminderBlock(
        text: clause,
        span: _Span(m.start, m.end),
      );
    }
    return null;
  }

  List<int> _parseReminderOffsets(String clause) {
    var body = clause.trim();
    body = body.replaceFirst(RegExp(r'^提前'), '');
    body = body.replaceFirst(RegExp(r'(提醒我|通知我|叫我|提醒)$'), '');
    body = body.replaceFirst(RegExp(r'之前提醒'), '');
    body = body.trim();

    if (body.isEmpty) return const [];

    final parts = body.split(RegExp(r'[和与及、,]+'));
    final offsets = <int>{};
    for (final part in parts) {
      final seconds = _parseReminderOffsetPart(part);
      if (seconds != null && seconds > 0) offsets.add(seconds);
    }

    final list = offsets.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  int? _parseReminderOffsetPart(String part) {
    var token = part.trim().replaceFirst(RegExp(r'^提前'), '').trim();
    if (token.isEmpty) return null;

    if (token.contains('半小时')) return 30 * 60;

    final match = RegExp(
      r'(\d+|[一二三四五六七八九十两]+)\s*(分钟|分|小时|钟头|时|天|日)',
    ).firstMatch(token);
    if (match != null) {
      final amount = _parseNumberToken(match.group(1)!);
      if (amount == null || amount <= 0) return null;
      return switch (match.group(2)!) {
        '分钟' || '分' => amount * 60,
        '小时' || '钟头' || '时' => amount * 3600,
        '天' || '日' => amount * 86400,
        _ => null,
      };
    }

    return null;
  }

  int? _parseNumberToken(String token) {
    token = token.trim();
    if (token.isEmpty) return null;
    final digits = int.tryParse(token);
    if (digits != null) return digits;

    const map = {
      '零': 0,
      '一': 1,
      '二': 2,
      '两': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
    };

    if (token == '十') return 10;
    if (token == '半') return null;

    if (token.length == 2 && token.startsWith('十')) {
      return 10 + (map[token[1]] ?? 0);
    }
    if (token.length == 2 && token.endsWith('十')) {
      return (map[token[0]] ?? 0) * 10;
    }
    if (token.contains('十')) {
      final parts = token.split('十');
      final high = parts[0].isEmpty ? 1 : (map[parts[0]] ?? 0);
      final low =
          parts.length > 1 && parts[1].isNotEmpty ? (map[parts[1]] ?? 0) : 0;
      return high * 10 + low;
    }

    return map[token];
  }

  TodoTimeMode _resolveTodoTimeMode({
    required TaskType taskType,
    required bool hasDate,
    required bool isDeadline,
    required bool hasDeadlineTime,
    required bool hasBlockTime,
  }) {
    if (taskType == TaskType.schedule) return TodoTimeMode.timeBlock;
    if (isDeadline && hasDeadlineTime) return TodoTimeMode.deadline;
    if (!hasDate) return TodoTimeMode.noTime;
    if (isDeadline || hasDeadlineTime) return TodoTimeMode.deadline;
    if (hasBlockTime) return TodoTimeMode.timeBlock;
    return TodoTimeMode.deadline;
  }

  TaskType? _extractExplicitTaskType(String text, List<_Span> removals) {
    final patterns = <(RegExp, TaskType)>[
      (RegExp(r'添加(?:一个)?日程'), TaskType.schedule),
      (RegExp(r'创建日程[：:]?'), TaskType.schedule),
      (RegExp(r'添加(?:一个)?待办'), TaskType.todo),
      (RegExp(r'创建待办[：:]?'), TaskType.todo),
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
    const patterns = [
      '截止时间',
      '截至时间',
      '截至',
      '截止',
      'deadline',
      '之前要',
      '前要完成',
      '前完成',
      '最晚',
      '不晚于',
    ];
    for (final p in patterns) {
      final i = text.indexOf(p);
      if (i >= 0) {
        removals.add(_Span(i, i + p.length));
        return true;
      }
    }

    final regexes = [
      RegExp(r'(\d{1,2}[:：点时]\d{0,2}\s*之前)'),
      RegExp(r'(\d{1,2}[:：点时]\d{0,2}\s*前)(?!面)'),
      RegExp(r'前(?:要)?(?:完成|交|交稿|提交|做完|写好|弄好)'),
    ];
    for (final pattern in regexes) {
      final m = pattern.firstMatch(text);
      if (m != null) {
        removals.add(_Span(m.start, m.end));
        return true;
      }
    }
    return false;
  }

  String _normalize(String text) {
    final buffer = StringBuffer();
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '　') {
        buffer.write(' ');
        continue;
      }
      const full = '０１２３４５６７８９：－～';
      const half = '0123456789:-~';
      final idx = full.indexOf(ch);
      buffer.write(idx >= 0 ? half[idx] : ch);
    }
    return buffer.toString().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  DateTime? _extractDate(String text, DateTime ref, List<_Span> removals) {
    final patterns = <RegExp>[
      RegExp(r'下(?:周|星期)([一二三四五六日天])'),
      RegExp(r'(?:周|星期)([一二三四五六日天])'),
      RegExp(r'大后天'),
      RegExp(r'后天'),
      RegExp(r'明天|明日'),
      RegExp(r'今天|今日|今晚'),
    ];

    Match? best;
    RegExp? bestPattern;
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m == null) continue;
      if (best == null || m.start < best.start) {
        best = m;
        bestPattern = p;
      }
    }
    if (best == null || bestPattern == null) return null;

    removals.add(_Span(best.start, best.end));
    final token = best.group(0)!;

    if (token == '大后天') {
      return ref.add(const Duration(days: 3));
    }
    if (token == '后天') {
      return ref.add(const Duration(days: 2));
    }
    if (token == '明天' || token == '明日') {
      return ref.add(const Duration(days: 1));
    }
    if (token == '今天' || token == '今日' || token == '今晚') {
      return ref;
    }

    final weekdayChar = best.group(1)!;
    final target = _weekdayChar[weekdayChar];
    if (target == null) return null;

    final isNextWeek = bestPattern.pattern.startsWith('下');
    if (isNextWeek) {
      return _dateOfNextWeekday(ref, target, nextWeek: true);
    }
    return _dateOfNextWeekday(ref, target, nextWeek: false);
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
    const numPat = r'(\d{1,2}|[一二三四五六七八九十两]+)';
    final patterns = [
      RegExp(
        '(上午|下午|晚上|中午|凌晨)?\\s*$numPat(?:[:：点时]$numPat)?\\s*(?:点|点半)?'
        '\\s*(到|至|[-~—–])\\s*'
        '(上午|下午|晚上|中午|凌晨)?\\s*$numPat(?:[:：点时]$numPat)?\\s*(?:点|点半)?',
      ),
      RegExp(
        r'(\d{1,2}):(\d{2})\s*(到|至|[-~—–])\s*(\d{1,2}):(\d{2})',
      ),
    ];

    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m == null) continue;

      TimeOfDay? start;
      TimeOfDay? end;

      if (m.groupCount >= 7 && m.group(2) != null) {
        final startPeriod = m.group(1);
        final startHour = _parseNumberToken(m.group(2)!);
        final startMinute = _parseMinuteToken(m.group(3), m.group(0)!, isStart: true);
        final endPeriod = m.group(5);
        final endHour = _parseNumberToken(m.group(6)!);
        final endMinute = _parseMinuteToken(m.group(7), m.group(0)!, isStart: false);
        if (startHour == null || endHour == null) continue;
        start = _toTimeOfDay(startHour, startMinute, startPeriod, isRange: true);
        end = _toTimeOfDay(
          endHour,
          endMinute,
          endPeriod ?? startPeriod,
          isRange: true,
        );
      } else if (m.groupCount >= 5 && m.group(1) != null) {
        start = TimeOfDay(
          hour: int.parse(m.group(1)!),
          minute: int.parse(m.group(2)!),
        );
        end = TimeOfDay(
          hour: int.parse(m.group(4)!),
          minute: int.parse(m.group(5)!),
        );
      }

      if (start == null || end == null) continue;
      removals.add(_Span(m.start, m.end));
      return _TimeRange(start: start, end: end);
    }
    return null;
  }

  int _parseMinuteToken(String? raw, String matched, {required bool isStart}) {
    if (raw != null && raw.isNotEmpty) {
      return _parseNumberToken(raw) ?? 0;
    }
    final segment = isStart
        ? matched.split(RegExp(r'到|至|[-~—–]')).first
        : matched.split(RegExp(r'到|至|[-~—–]')).last;
    if (segment.contains('点半')) return 30;
    return 0;
  }

  TimeOfDay? _extractSingleTime(
    String text,
    List<_Span> removals, {
    bool eveningContext = false,
  }) {
    const numPat = r'(\d{1,2}|[一二三四五六七八九十两]+)';
    final candidates = <(Match, TimeOfDay)>[];

    for (final m in RegExp(
      '(上午|下午|晚上|中午|凌晨)\\s*的?\\s*$numPat(?:[:：点时]$numPat)?\\s*(?:点|点半)?',
    ).allMatches(text)) {
      final hour = _parseNumberToken(m.group(2)!);
      if (hour == null) continue;
      final minute = _parseMinuteToken(m.group(3), m.group(0)!, isStart: true);
      final time =
          _toTimeOfDay(hour, minute, m.group(1), isRange: false);
      if (time != null) candidates.add((m, time));
    }

    for (final m in RegExp('$numPat[:：]$numPat').allMatches(text)) {
      final hour = int.tryParse(m.group(1)!);
      final minute = int.tryParse(m.group(2)!);
      if (hour == null || minute == null) continue;
      final time = _toTimeOfDay(
        hour,
        minute,
        null,
        isRange: false,
        eveningContext: eveningContext,
      );
      if (time != null) candidates.add((m, time));
    }

    for (final m in RegExp('$numPat\\s*点(?:\\s*$numPat\\s*分)?|$numPat\\s*点半')
        .allMatches(text)) {
      final hour = _parseNumberToken(m.group(1)!);
      if (hour == null) continue;
      final minute = _parseMinuteToken(m.group(2), m.group(0)!, isStart: true);
      final time = _toTimeOfDay(
        hour,
        minute,
        null,
        isRange: false,
        eveningContext: eveningContext,
      );
      if (time != null) candidates.add((m, time));
    }

    if (candidates.isEmpty) return null;

    candidates.sort((a, b) {
      final scoreA = _timeMatchScore(text, a.$1);
      final scoreB = _timeMatchScore(text, b.$1);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      return a.$1.start.compareTo(b.$1.start);
    });

    final best = candidates.first;
    removals.add(_Span(best.$1.start, best.$1.end));
    return best.$2;
  }

  int _timeMatchScore(String text, Match match) {
    var score = match.end - match.start;
    final segment = text.substring(match.start, match.end);
    if (RegExp(r'(上午|下午|晚上|中午|凌晨)').hasMatch(segment)) {
      score += 100;
    }
    return score;
  }

  TimeOfDay? _toTimeOfDay(
    int hour,
    int minute,
    String? period, {
    required bool isRange,
    bool eveningContext = false,
  }) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;

    switch (period) {
      case '凌晨':
        if (hour == 12) hour = 0;
        break;
      case '上午':
        if (hour == 12) hour = 0;
        break;
      case '中午':
        hour = 12;
        break;
      case '下午':
        if (hour >= 1 && hour <= 11) hour += 12;
        break;
      case '晚上':
        if (hour >= 1 && hour <= 11) hour += 12;
        if (hour == 12) hour = 12;
        break;
      case null:
        if ((isRange || eveningContext) && hour >= 1 && hour <= 11) {
          hour += 12;
        }
        break;
    }

    if (hour > 23 || minute > 59) return null;
    return TimeOfDay(hour: hour, minute: minute);
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
        .replaceAll(RegExp(r'^[，,、：:\s]+'), '')
        .replaceAll(RegExp(r'[，。、；;！!？?]+$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    // Drop vague period words that were not tied to a numeric time.
    for (final word in ['上午', '下午', '晚上', '中午', '凌晨']) {
      title = title.replaceAll(word, '');
    }
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

/// Back-compat alias for tests and existing imports.
typedef NaturalLanguageParser = ChineseNaturalLanguageParser;
