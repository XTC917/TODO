import '../../core/utils/date_time_formats.dart';
import '../../core/utils/repeat_expander.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

/// Status dimension for search filtering.
enum TaskSearchStatusFilter { all, incomplete, completed }

/// Type dimension for search filtering ([Event.taskType], never guessed).
enum TaskSearchTypeFilter { all, todo, schedule }

/// Time dimension for search filtering, judged on the expanded occurrence's
/// real [DateTime], never on the recurring master's start date.
enum TaskSearchTimeFilter { all, future, past }

/// One searchable hit. [event] is the concrete occurrence as Calendar would
/// show it (virtual instance, edited override, or one-time row) — never a
/// collapsed recurring master. [targetDate] is that occurrence's own day.
class TaskSearchResult {
  const TaskSearchResult({
    required this.event,
    required this.targetDate,
    required this.occurrenceDateTime,
    required this.score,
    this.noteSnippet,
    required this.titleMatched,
    required this.noteMatched,
  });

  final Event event;
  final DateTime targetDate;
  final DateTime occurrenceDateTime;
  final double score;
  final String? noteSnippet;
  final bool titleMatched;
  final bool noteMatched;

  bool get isCompleted => event.isCompleted;

  String get targetDateKey => DateTimeFormats.formatDate(targetDate);

  /// Stable identity of one occurrence: same stored row on different days
  /// (virtual instances share the master's id) stays distinct.
  String get stableKey => '${event.id}@$targetDateKey';
}

/// Shared in-memory search over the unified event stream.
///
/// Searches title + user note only. Category, ids and other internal fields
/// are never consulted.
class TaskSearchService {
  TaskSearchService._();

  /// Search window for unbounded recurrence: one year back, one year forward.
  static const int searchWindowDays = 365;

  /// Display cap so a huge series cannot flood the list.
  static const int defaultLimit = 800;

  static List<Event>? _cachedSource;
  static String? _cachedWindowKey;
  static List<Event>? _cachedOccurrences;

  /// Every Calendar-visible occurrence that search may hit.
  ///
  /// Built with [RepeatExpander] so semantics match Calendar exactly:
  /// skip markers and deleted days produce nothing, one-time overrides and
  /// edited occurrences replace the virtual instance, per-occurrence
  /// completion comes from the concrete row.
  ///
  /// - In-window (±[searchWindowDays]): full [RepeatExpander.expandForRange].
  /// - One-time / concrete rows outside the window: included directly, so
  ///   old history and far-future tasks stay searchable.
  /// - Bounded series ([Event.seriesRepeatUntil]): occurrences outside the
  ///   window are additionally expanded, covering start → end.
  static List<Event> expandSearchableOccurrences(
    List<Event> allEvents,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final windowStart =
        today.subtract(const Duration(days: searchWindowDays));
    final windowEnd = today.add(const Duration(days: searchWindowDays));
    final windowKey =
        '${DateTimeFormats.formatDate(windowStart)}~${DateTimeFormats.formatDate(windowEnd)}';
    if (identical(allEvents, _cachedSource) &&
        windowKey == _cachedWindowKey &&
        _cachedOccurrences != null) {
      return _cachedOccurrences!;
    }

    final inWindow =
        RepeatExpander.expandForRange(allEvents, windowStart, windowEnd);
    final seen = <String>{
      for (final e in inWindow) '${e.id}@${e.date}',
    };
    final out = <Event>[...inWindow];

    // One-time rows (plain tasks, overrides, edited/completed single
    // occurrences) outside the window stay searchable at their own date.
    for (final row in allEvents) {
      if (row.isRepeatSkip) continue;
      if (!row.hasDate) continue;
      if (row.repeatType != RepeatType.oneTime) continue;
      DateTime day;
      try {
        day = DateTimeFormats.parseDate(row.date);
      } catch (_) {
        continue;
      }
      final d = DateTime(day.year, day.month, day.day);
      if (!d.isBefore(windowStart) && !d.isAfter(windowEnd)) continue;
      if (seen.add('${row.id}@${row.date}')) out.add(row);
    }

    // Bounded series: also expand the parts outside the window.
    for (final template in _recurringTemplates(allEvents)) {
      final untilKey = template.seriesRepeatUntil;
      if (untilKey == null || untilKey.isEmpty) continue;
      DateTime start;
      DateTime until;
      try {
        start = DateTimeFormats.parseDate(template.date);
        until = DateTimeFormats.parseDate(untilKey);
      } catch (_) {
        continue;
      }
      final s = DateTime(start.year, start.month, start.day);
      final u = DateTime(until.year, until.month, until.day);
      if (u.isBefore(s)) continue;
      if (s.isBefore(windowStart)) {
        final end = u.isBefore(windowStart)
            ? u
            : windowStart.subtract(const Duration(days: 1));
        _addRangeOccurrences(allEvents, s, end, seen, out);
      }
      if (u.isAfter(windowEnd)) {
        final begin = s.isAfter(windowEnd)
            ? s
            : windowEnd.add(const Duration(days: 1));
        _addRangeOccurrences(allEvents, begin, u, seen, out);
      }
    }

    _cachedSource = allEvents;
    _cachedWindowKey = windowKey;
    _cachedOccurrences = out;
    return out;
  }

  static void _addRangeOccurrences(
    List<Event> allEvents,
    DateTime start,
    DateTime end,
    Set<String> seen,
    List<Event> out,
  ) {
    if (end.isBefore(start)) return;
    for (final e in RepeatExpander.expandForRange(allEvents, start, end)) {
      if (seen.add('${e.id}@${e.date}')) out.add(e);
    }
  }

  /// Recurring series definitions: grouped masters (earliest non-one-time
  /// row per group) plus legacy recurring rows without a group id.
  static List<Event> _recurringTemplates(List<Event> allEvents) {
    final grouped = <String, List<Event>>{};
    for (final e in allEvents) {
      final groupId = e.repeatGroupId;
      if (groupId == null) continue;
      grouped.putIfAbsent(groupId, () => []).add(e);
    }
    final templates = <Event>[];
    for (final rows in grouped.values) {
      final masters = rows
          .where((r) => r.repeatType != RepeatType.oneTime)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
      if (masters.isNotEmpty) templates.add(masters.first);
    }
    for (final e in allEvents) {
      if (e.repeatGroupId == null &&
          e.repeatType != RepeatType.oneTime &&
          !e.isRepeatSkip) {
        templates.add(e);
      }
    }
    return templates;
  }

  /// Real DateTime an occurrence happens at.
  ///
  /// Deadline todos use their deadline time, everything else its start time.
  /// Time-less dated rows fall back to end of day so today's date-only task
  /// counts as future until the day passes.
  static DateTime occurrenceDateTime(Event occurrence, DateTime now) {
    DateTime day;
    try {
      day = DateTimeFormats.parseDate(occurrence.date);
    } catch (_) {
      return now;
    }
    day = DateTime(day.year, day.month, day.day);
    final String time = occurrence.isDeadlineTodo
        ? occurrence.endTime
        : (occurrence.startTime.isNotEmpty
            ? occurrence.startTime
            : occurrence.endTime);
    if (time.isEmpty) {
      return DateTime(day.year, day.month, day.day, 23, 59, 59);
    }
    try {
      final parts = time.split(':');
      return DateTime(
        day.year,
        day.month,
        day.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    } catch (_) {
      return DateTime(day.year, day.month, day.day, 23, 59, 59);
    }
  }

  /// Searches expanded occurrences for [query].
  ///
  /// - Case-insensitive for English, direct character matching for Chinese.
  /// - Single-character queries work (substring match).
  /// - Filters apply to in-memory occurrences; SQLite is never re-queried.
  /// - Rows without a date cannot be located in Calendar and are skipped.
  /// - Hidden skip markers and blank titles are skipped.
  static List<TaskSearchResult> search(
    List<Event> allEvents,
    String query, {
    DateTime? now,
    TaskSearchStatusFilter status = TaskSearchStatusFilter.all,
    TaskSearchTypeFilter type = TaskSearchTypeFilter.all,
    TaskSearchTimeFilter time = TaskSearchTimeFilter.all,
    int limit = defaultLimit,
  }) {
    final q = query.trim();
    if (q.isEmpty) return const [];
    final current = now ?? DateTime.now();
    final occurrences = expandSearchableOccurrences(allEvents, current);
    final results = <TaskSearchResult>[];

    for (final occurrence in occurrences) {
      if (occurrence.isRepeatSkip) continue;
      if (occurrence.title.trim().isEmpty) continue;
      if (!occurrence.hasDate) continue;

      if (type == TaskSearchTypeFilter.todo && !occurrence.isTodo) continue;
      if (type == TaskSearchTypeFilter.schedule && !occurrence.isSchedule) {
        continue;
      }
      if (status == TaskSearchStatusFilter.completed &&
          !occurrence.isCompleted) {
        continue;
      }
      if (status == TaskSearchStatusFilter.incomplete &&
          occurrence.isCompleted) {
        continue;
      }

      final titleScore = _scoreTitle(occurrence.title, q);
      final note = occurrence.userNote;
      final noteScore =
          (note == null || note.isEmpty) ? null : _scoreNote(note, q);
      if (titleScore == null && noteScore == null) continue;

      final total = (titleScore ?? 0) +
          (noteScore ?? 0) * (titleScore != null ? 0.2 : 1.0);
      final dateTime = occurrenceDateTime(occurrence, current);
      final isFuture = !dateTime.isBefore(current);
      if (time == TaskSearchTimeFilter.future && !isFuture) continue;
      if (time == TaskSearchTimeFilter.past && isFuture) continue;

      DateTime target;
      try {
        target = DateTimeFormats.parseDate(occurrence.date);
      } catch (_) {
        continue;
      }
      results.add(
        TaskSearchResult(
          event: occurrence,
          targetDate: DateTime(target.year, target.month, target.day),
          occurrenceDateTime: dateTime,
          score: total,
          noteSnippet: note == null || note.isEmpty
              ? null
              : _buildSnippet(note, q, noteMatched: noteScore != null),
          titleMatched: titleScore != null,
          noteMatched: noteScore != null,
        ),
      );
    }

    results.sort((a, b) => _compare(a, b, current));

    if (results.length > limit) return results.sublist(0, limit);
    return results;
  }

  /// 1. relevance DESC
  /// 2. absolute distance from now ASC (real DateTime, not day strings)
  /// 3. on exact ties: future before past
  /// 4. actual occurrence time
  /// 5. stable key (deterministic)
  static int _compare(TaskSearchResult a, TaskSearchResult b, DateTime now) {
    final scoreCmp = b.score.compareTo(a.score);
    if (scoreCmp != 0) return scoreCmp;
    final da = a.occurrenceDateTime.difference(now).abs();
    final db = b.occurrenceDateTime.difference(now).abs();
    final distCmp = da.compareTo(db);
    if (distCmp != 0) return distCmp;
    final aFuture = !a.occurrenceDateTime.isBefore(now);
    final bFuture = !b.occurrenceDateTime.isBefore(now);
    if (aFuture != bFuture) return aFuture ? -1 : 1;
    final timeCmp = a.occurrenceDateTime.compareTo(b.occurrenceDateTime);
    if (timeCmp != 0) return timeCmp;
    return a.stableKey.compareTo(b.stableKey);
  }

  // --- scoring (unchanged) ---

  static double? _scoreTitle(String title, String query) {
    final t = title.toLowerCase();
    final q = query.toLowerCase();
    if (t == q) return 1000;
    if (t.startsWith(q)) return 800;
    if (t.contains(q)) return 600;
    final longest = _longestQuerySubstring(q, t);
    if (longest >= 2) return 200 + 100 * (longest / q.length);
    if (longest == 1) return 120;
    if (_isSubsequence(q, t)) {
      final ratio = q.length / t.length.clamp(1, 100000);
      return 100 + 20 * ratio;
    }
    return null;
  }

  static double? _scoreNote(String note, String query) {
    final n = note.toLowerCase();
    final q = query.toLowerCase();
    if (n.contains(q)) return n.startsWith(q) ? 70 : 60;
    final longest = _longestQuerySubstring(q, n);
    if (longest >= 2) return 30 + 10 * (longest / q.length);
    if (_isSubsequence(q, n)) return 20;
    return null;
  }

  /// Length of the longest substring of [query] that appears in [text].
  static int _longestQuerySubstring(String query, String text) {
    if (query.isEmpty || text.isEmpty) return 0;
    for (var len = query.length; len >= 1; len--) {
      for (var i = 0; i + len <= query.length; i++) {
        if (text.contains(query.substring(i, i + len))) return len;
      }
    }
    return 0;
  }

  /// Whether every character of [query] appears in [text] in order.
  static bool _isSubsequence(String query, String text) {
    if (query.isEmpty) return false;
    if (query.length == 1) return text.contains(query);
    var qi = 0;
    for (var ti = 0; ti < text.length && qi < query.length; ti++) {
      if (text[ti] == query[qi]) qi++;
    }
    return qi == query.length;
  }

  static String? _buildSnippet(
    String note,
    String query, {
    required bool noteMatched,
  }) {
    if (!noteMatched) return null;
    final q = query.trim();
    if (q.isEmpty) return null;
    const before = 18;
    const after = 32;
    const maxLead = 60;
    final idx = note.toLowerCase().indexOf(q.toLowerCase());
    if (idx < 0) {
      if (note.length <= maxLead) return note;
      return '${note.substring(0, maxLead)}…';
    }
    var start = (idx - before).clamp(0, note.length);
    var end = (idx + q.length + after).clamp(0, note.length);
    // Prefer not to cut a word/segment awkwardly short at the edges.
    if (start > 0 && start + 6 > idx) start = idx;
    if (end < note.length && end < idx + q.length + 6) {
      end = (idx + q.length + 6).clamp(0, note.length);
    }
    var snippet = note.substring(start, end);
    if (start > 0) snippet = '…$snippet';
    if (end < note.length) snippet = '$snippet…';
    return snippet;
  }
}
