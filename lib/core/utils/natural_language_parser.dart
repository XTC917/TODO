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
    var working = normalized;

    final note = _extractNote(working, removals);
    if (note != null) {
      working = _maskSpan(working, note.span);
    }
    final eveningContext = working.contains('今晚') || working.contains('今夜');

    final explicitType = _extractExplicitTaskType(working, removals);
    final dateMatch = _extractDate(working, ref);
    if (dateMatch != null) {
      removals.add(dateMatch.span);
      working = _maskSpan(working, dateMatch.span);
    }
    final date = dateMatch?.date;
    final range = _extractTimeRange(working, removals);
    final single = range == null
        ? _extractSingleTime(working, removals, eveningContext: eveningContext)
        : null;

    var startTime = range?.start ?? single;
    var endTime = range?.end;
    final isDeadline = _hasDeadlineHint(working, removals);

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
      working,
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
      note: note?.text,
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
    if (!_reminderTriggers.any(text.contains)) return const [];

    final blocks = _findReminderBlocks(text);
    if (blocks.isEmpty) return const [];

    final offsets = <int>{};
    for (final block in blocks) {
      final parsed = _parseReminderOffsets(block.text);
      if (parsed.isEmpty) continue;
      removals.add(block.span);
      if (canSchedule) offsets.addAll(parsed);
    }

    if (!canSchedule || offsets.isEmpty) return const [];
    final list = offsets.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  List<_ReminderBlock> _findReminderBlocks(String text) {
    final blocks = <_ReminderBlock>[];
    final pattern = RegExp(
      r'提前[^，,；;。!?！？]*?(?:提醒我|通知我|叫我|提醒|$)',
    );
    for (final m in pattern.allMatches(text)) {
      final clause = m.group(0)!.trim();
      if (!clause.startsWith('提前')) continue;
      blocks.add(_ReminderBlock(
        text: clause,
        span: _Span(m.start, m.start + clause.length),
      ));
    }
    return blocks;
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
    token =
        token.replaceFirst(RegExp(r'(?:提醒我|通知我|叫我|提醒|之前|前)\s*$'), '').trim();
    if (token.isEmpty) return null;

    if (RegExp(r'^半\s*小时$').hasMatch(token)) return 30 * 60;

    final match = RegExp(
      r'^(\d+|[一二三四五六七八九十两]+)\s*(分钟|分|小时|钟头|时|天|日)',
    ).firstMatch(token);
    if (match != null) {
      final rest = token.substring(match.end).trim();
      if (rest.isNotEmpty) return null;
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
    if (isDeadline || hasDeadlineTime) return TodoTimeMode.deadline;
    if (hasBlockTime) return TodoTimeMode.timeBlock;
    if (!hasDate) return TodoTimeMode.noTime;
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

  _NoteResult? _extractNote(String text, List<_Span> removals) {
    final patterns = <RegExp>[
      RegExp(r'(?:备注|说明|注释)\s*(?:一下)?\s*[:：]?\s*([^，,；;。!?！？]+)'),
      RegExp(r'\bnote(?:s)?\s*[:：]\s*([^,;.!?]+)', caseSensitive: false),
    ];

    Match? best;
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      if (best == null || match.start < best.start) best = match;
    }
    if (best == null) return null;

    var note = (best.group(1) ?? '').trim();
    note = note.replaceFirst(RegExp(r'^(?:在|于)\s*'), '').trim();
    note = note.replaceFirst(RegExp(r'^(?:地点|位置)\s*[:：]?\s*(?:在)?\s*'), '');
    if (note.isEmpty) return null;

    final span = _Span(best.start, best.end);
    removals.add(span);
    return _NoteResult(note, span);
  }

  String _maskSpan(String text, _Span span) {
    final length = span.end - span.start;
    if (length <= 0) return text;
    return text.replaceRange(span.start, span.end, ' ' * length);
  }

  _DateMatch? _extractDate(String text, DateTime ref) {
    final absolute = _extractAbsoluteDate(text, ref);
    if (absolute != null) return absolute;

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

    final span = _Span(best.start, best.end);
    final token = best.group(0)!;

    if (token == '大后天') {
      return _DateMatch(ref.add(const Duration(days: 3)), span);
    }
    if (token == '后天') {
      return _DateMatch(ref.add(const Duration(days: 2)), span);
    }
    if (token == '明天' || token == '明日') {
      return _DateMatch(ref.add(const Duration(days: 1)), span);
    }
    if (token == '今天' || token == '今日' || token == '今晚') {
      return _DateMatch(ref, span);
    }

    final weekdayChar = best.group(1)!;
    final target = _weekdayChar[weekdayChar];
    if (target == null) return null;

    final isNextWeek = bestPattern.pattern.startsWith('下');
    if (isNextWeek) {
      return _DateMatch(
        _dateOfNextWeekday(ref, target, nextWeek: true),
        span,
      );
    }
    return _DateMatch(
      _dateOfNextWeekday(ref, target, nextWeek: false),
      span,
    );
  }

  _DateMatch? _extractAbsoluteDate(String text, DateTime ref) {
    final candidates = <_DateCandidate>[];

    void addFullYearMatches(RegExp pattern, int priority) {
      for (final m in pattern.allMatches(text)) {
        final year = int.tryParse(m.group(1)!);
        final month = int.tryParse(m.group(2)!);
        final day = int.tryParse(m.group(3)!);
        if (year == null || month == null || day == null) continue;
        final date = _buildDate(
          year: year,
          month: month,
          day: day,
          ref: ref,
          allowYearInference: false,
        );
        if (date != null) {
          candidates.add(_DateCandidate(date, _Span(m.start, m.end), priority));
        }
      }
    }

    addFullYearMatches(
      RegExp(r'(\d{4})\s*[-/.]\s*(\d{1,2})\s*[-/.]\s*(\d{1,2})'),
      0,
    );
    addFullYearMatches(
      RegExp(r'(\d{4})\s*年\s*(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]?'),
      0,
    );

    for (final m
        in RegExp(r'(\d{1,2})\s*月\s*(\d{1,2})\s*[日号]?').allMatches(text)) {
      final month = int.tryParse(m.group(1)!);
      final day = int.tryParse(m.group(2)!);
      if (month == null || day == null) continue;
      final date = _buildDate(
        year: ref.year,
        month: month,
        day: day,
        ref: ref,
        allowYearInference: true,
      );
      if (date != null) {
        candidates.add(_DateCandidate(date, _Span(m.start, m.end), 1));
      }
    }

    for (final m in RegExp(r'下个月\s*(\d{1,2})\s*[日号]?').allMatches(text)) {
      final day = int.tryParse(m.group(1)!);
      if (day == null) continue;
      var year = ref.year;
      var month = ref.month + 1;
      if (month > 12) {
        month = 1;
        year++;
      }
      final date = _buildDate(
        year: year,
        month: month,
        day: day,
        ref: ref,
        allowYearInference: false,
      );
      if (date != null) {
        candidates.add(_DateCandidate(date, _Span(m.start, m.end), 2));
      }
    }

    for (final m
        in RegExp(r'(\d{1,2})\s*([./-])\s*(\d{1,2})').allMatches(text)) {
      final month = int.tryParse(m.group(1)!);
      final day = int.tryParse(m.group(3)!);
      final separator = m.group(2)!;
      if (month == null || day == null) continue;
      if (!_isShortNumericDateContext(
        text,
        m,
        separator,
        month: month,
        day: day,
      )) {
        continue;
      }
      final date = _buildDate(
        year: ref.year,
        month: month,
        day: day,
        ref: ref,
        allowYearInference: true,
      );
      if (date != null) {
        candidates.add(_DateCandidate(date, _Span(m.start, m.end), 3));
      }
    }

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) {
      final byStart = a.span.start.compareTo(b.span.start);
      if (byStart != 0) return byStart;
      return a.priority.compareTo(b.priority);
    });
    final best = candidates.first;
    return _DateMatch(best.date, best.span);
  }

  bool _isShortNumericDateContext(
    String text,
    Match match,
    String separator, {
    required int month,
    required int day,
  }) {
    final before = match.start > 0 ? text[match.start - 1] : '';
    final after = match.end < text.length ? text[match.end] : '';

    if (_isAsciiDigit(before) || _isAsciiDigit(after)) return false;
    const boundaryChars = '-/.:：';
    if ((before.isNotEmpty && boundaryChars.contains(before)) ||
        (after.isNotEmpty && boundaryChars.contains(after))) {
      return false;
    }
    if (after == '点' || after == '时' || after == '分') return false;

    final suffixEnd = match.end + 3 < text.length ? match.end + 3 : text.length;
    final suffix = text.substring(match.end, suffixEnd);
    if (RegExp(r'^(?:小时|分钟|分|天|日|个|元|块|公里|km|kg|%|％)').hasMatch(suffix)) {
      return false;
    }

    final prefixStart = match.start > 3 ? match.start - 3 : 0;
    final prefix = text.substring(prefixStart, match.start);
    if (RegExp(r'(?:上午|下午|晚上|中午|凌晨)\s*$').hasMatch(prefix)) {
      return false;
    }

    // Hyphen is also a time-range separator. Only treat it as a date when at
    // least one component is unambiguously date-like (e.g. 11-1, 3-15), so
    // that "下午3-5" keeps its existing time-range meaning.
    if (separator == '-' && month < 10 && day < 10) return false;

    return true;
  }

  bool _isAsciiDigit(String char) {
    if (char.isEmpty) return false;
    final code = char.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  DateTime? _buildDate({
    required int year,
    required int month,
    required int day,
    required DateTime ref,
    required bool allowYearInference,
  }) {
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;

    if (!allowYearInference) {
      final date = DateTime(year, month, day);
      return date.month == month && date.day == day ? date : null;
    }

    var date = DateTime(ref.year, month, day);
    if (date.month != month || date.day != day) return null;
    if (date.isBefore(ref)) {
      final next = DateTime(ref.year + 1, month, day);
      if (next.month == month && next.day == day) date = next;
    }
    return date;
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
        final startMinute =
            _parseMinuteToken(m.group(3), m.group(0)!, isStart: true);
        final endPeriod = m.group(5);
        final endHour = _parseNumberToken(m.group(6)!);
        final endMinute =
            _parseMinuteToken(m.group(7), m.group(0)!, isStart: false);
        if (startHour == null || endHour == null) continue;
        start =
            _toTimeOfDay(startHour, startMinute, startPeriod, isRange: true);
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
      final time = _toTimeOfDay(hour, minute, m.group(1), isRange: false);
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
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    title = title.replaceAll(RegExp(r'^(?:在|于)\s*'), '');
    // "上英语课" is more useful to the user as "英语课"; keep "上课"/"上班".
    title = title.replaceFirst(RegExp(r'^上(?=.{2,}课$)'), '');
    return title.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

class _Span {
  const _Span(this.start, this.end);
  final int start;
  final int end;
}

class _DateMatch {
  const _DateMatch(this.date, this.span);
  final DateTime date;
  final _Span span;
}

class _DateCandidate {
  const _DateCandidate(this.date, this.span, this.priority);
  final DateTime date;
  final _Span span;
  final int priority;
}

class _NoteResult {
  const _NoteResult(this.text, this.span);
  final String text;
  final _Span span;
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
