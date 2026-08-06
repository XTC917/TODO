import 'package:flutter/foundation.dart';

import 'event.dart';

enum StatsPeriod { day, week, month, year }

@immutable
class StatsPeriodRange {
  const StatsPeriodRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

@immutable
class StatsOverview {
  const StatsOverview({
    required this.completedTodos,
    required this.totalTodos,
    required this.focusSeconds,
  });

  final int completedTodos;
  final int totalTodos;
  final int focusSeconds;

  int get pendingTodos => totalTodos - completedTodos;
}

@immutable
class FocusRankingEntry {
  const FocusRankingEntry({
    required this.nameKey,
    required this.totalSeconds,
    required this.sessionCount,
    required this.sessions,
  });

  /// Raw merged title key; empty string means untitled sessions.
  final String nameKey;
  final int totalSeconds;
  final int sessionCount;
  final List<FocusRecord> sessions;
}

@immutable
class FocusChartBucket {
  const FocusChartBucket({
    required this.label,
    required this.focusSeconds,
    required this.sessionCount,
    this.date,
    this.month,
  });

  final String label;
  final int focusSeconds;
  final int sessionCount;
  final DateTime? date;
  final int? month;
}

@immutable
class StatsDashboard {
  const StatsDashboard({
    required this.overview,
    required this.ranking,
    required this.chartBuckets,
    required this.showChart,
  });

  final StatsOverview overview;
  final List<FocusRankingEntry> ranking;
  final List<FocusChartBucket> chartBuckets;
  final bool showChart;
}

@immutable
class StatsQuery {
  const StatsQuery({required this.period, required this.offset});

  final StatsPeriod period;
  final int offset;

  @override
  bool operator ==(Object other) {
    return other is StatsQuery &&
        other.period == period &&
        other.offset == offset;
  }

  @override
  int get hashCode => Object.hash(period, offset);
}
