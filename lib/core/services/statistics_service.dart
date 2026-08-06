import '../../core/utils/date_time_formats.dart';
import '../../models/event.dart';
import '../../models/statistics.dart';

class StatisticsService {
  StatsPeriodRange rangeFor(StatsPeriod period, int offset) {
    final now = DateTime.now();
    switch (period) {
      case StatsPeriod.day:
        final day = DateTimeFormats.dateOnly(now.add(Duration(days: offset)));
        return StatsPeriodRange(start: day, end: day);
      case StatsPeriod.week:
        final weekStart =
            DateTimeFormats.startOfWeek(now).add(Duration(days: offset * 7));
        return StatsPeriodRange(
          start: weekStart,
          end: weekStart.add(const Duration(days: 6)),
        );
      case StatsPeriod.month:
        final month = DateTime(now.year, now.month + offset, 1);
        return StatsPeriodRange(
          start: DateTime(month.year, month.month, 1),
          end: DateTime(month.year, month.month + 1, 0),
        );
      case StatsPeriod.year:
        final year = now.year + offset;
        return StatsPeriodRange(
          start: DateTime(year, 1, 1),
          end: DateTime(year, 12, 31),
        );
    }
  }

  StatsDashboard buildDashboard({
    required StatsPeriod period,
    required StatsPeriodRange range,
    required List<Event> events,
    required List<FocusRecord> records,
  }) {
    final overview = _buildOverview(events, records);
    final ranking = _buildRanking(records);
    final chartBuckets = _buildChartBuckets(period, range, records);

    return StatsDashboard(
      overview: overview,
      ranking: ranking,
      chartBuckets: chartBuckets,
      showChart: period != StatsPeriod.day,
    );
  }

  StatsOverview _buildOverview(List<Event> events, List<FocusRecord> records) {
    final todos = events.where((e) => e.isTodo).toList(growable: false);
    final completed = todos.where((e) => e.isTodoDone()).length;
    final focusSeconds =
        records.fold<int>(0, (sum, r) => sum + r.durationSeconds);

    return StatsOverview(
      completedTodos: completed,
      totalTodos: todos.length,
      focusSeconds: focusSeconds,
    );
  }

  List<FocusRankingEntry> _buildRanking(List<FocusRecord> records) {
    final totals = <String, int>{};
    final counts = <String, int>{};
    final grouped = <String, List<FocusRecord>>{};

    for (final record in records) {
      final key = _rankingKey(record);
      totals[key] = (totals[key] ?? 0) + record.durationSeconds;
      counts[key] = (counts[key] ?? 0) + 1;
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final entries = totals.entries
        .map(
          (e) {
            final sessions = grouped[e.key]!
              ..sort((a, b) => b.startTime.compareTo(a.startTime));
            return FocusRankingEntry(
              nameKey: e.key,
              totalSeconds: e.value,
              sessionCount: counts[e.key] ?? 0,
              sessions: List<FocusRecord>.unmodifiable(sessions),
            );
          },
        )
        .toList(growable: false)
      ..sort((a, b) => b.totalSeconds.compareTo(a.totalSeconds));

    return entries;
  }

  String _rankingKey(FocusRecord record) {
    final title = record.taskTitle?.trim();
    if (title == null || title.isEmpty) return '';
    return title;
  }

  List<FocusChartBucket> _buildChartBuckets(
    StatsPeriod period,
    StatsPeriodRange range,
    List<FocusRecord> records,
  ) {
    switch (period) {
      case StatsPeriod.day:
        return const [];
      case StatsPeriod.week:
        return _weekBuckets(range, records);
      case StatsPeriod.month:
        return _monthBuckets(range, records);
      case StatsPeriod.year:
        return _yearBuckets(range, records);
    }
  }

  List<FocusChartBucket> _weekBuckets(
    StatsPeriodRange range,
    List<FocusRecord> records,
  ) {
    final buckets = <FocusChartBucket>[];
    for (var i = 0; i < 7; i++) {
      final day = range.start.add(Duration(days: i));
      final key = DateTimeFormats.formatDate(day);
      final dayRecords = records.where((r) => r.date == key);
      buckets.add(
        FocusChartBucket(
          label: DateTimeFormats.shortWeekday.format(day),
          focusSeconds: dayRecords.fold<int>(0, (s, r) => s + r.durationSeconds),
          sessionCount: dayRecords.length,
          date: day,
        ),
      );
    }
    return buckets;
  }

  List<FocusChartBucket> _monthBuckets(
    StatsPeriodRange range,
    List<FocusRecord> records,
  ) {
    final daysInMonth = range.end.day;
    final buckets = <FocusChartBucket>[];
    for (var day = 1; day <= daysInMonth; day++) {
      final date = DateTime(range.start.year, range.start.month, day);
      final key = DateTimeFormats.formatDate(date);
      final dayRecords = records.where((r) => r.date == key);
      buckets.add(
        FocusChartBucket(
          label: '$day',
          focusSeconds: dayRecords.fold<int>(0, (s, r) => s + r.durationSeconds),
          sessionCount: dayRecords.length,
          date: date,
        ),
      );
    }
    return buckets;
  }

  List<FocusChartBucket> _yearBuckets(
    StatsPeriodRange range,
    List<FocusRecord> records,
  ) {
    final buckets = <FocusChartBucket>[];
    for (var month = 1; month <= 12; month++) {
      final monthStart = DateTime(range.start.year, month, 1);
      final monthEnd = DateTime(range.start.year, month + 1, 0);
      final monthRecords = records.where((record) {
        final date = DateTimeFormats.parseDate(record.date);
        return !date.isBefore(monthStart) && !date.isAfter(monthEnd);
      });
      buckets.add(
        FocusChartBucket(
          label: DateTimeFormats.shortMonth.format(monthStart),
          focusSeconds:
              monthRecords.fold<int>(0, (s, r) => s + r.durationSeconds),
          sessionCount: monthRecords.length,
          month: month,
          date: monthStart,
        ),
      );
    }
    return buckets;
  }
}
