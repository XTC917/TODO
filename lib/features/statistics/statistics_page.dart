import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';

enum StatsRange { day, week }

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage> {
  StatsRange _range = StatsRange.day;

  @override
  Widget build(BuildContext context) {
    final today = DateTimeFormats.dateOnly(DateTime.now());
    final summary = ref.watch(daySummaryProvider(today));
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              l10n.statsTitle,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<StatsRange>(
              segments: [
                ButtonSegment(value: StatsRange.day, label: Text(l10n.statsDay)),
                ButtonSegment(
                  value: StatsRange.week,
                  label: Text(l10n.statsWeek),
                ),
              ],
              selected: {_range},
              onSelectionChanged: (s) => setState(() => _range = s.first),
            ),
            const SizedBox(height: 20),
            summary.when(
              data: (s) => _TodayCard(summary: s),
              loading: () => const CircularProgressIndicator.adaptive(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),
            Text(
              _range == StatsRange.day
                  ? l10n.statsDailyFocus
                  : l10n.statsWeeklyFocus,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _FocusChart(range: _range),
            ),
            const SizedBox(height: 24),
            Text(
              _range == StatsRange.day
                  ? l10n.statsDailyTodo
                  : l10n.statsWeeklyTodo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: _TodoChart(range: _range),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.today,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )),
            const SizedBox(height: 12),
            Text(l10n.statsFocusLabel(
              DateTimeFormats.formatDuration(summary.focusSeconds),
            )),
            Text(l10n.statsTasksLabel(
              summary.todoCompleted,
              summary.todoTotal,
            )),
            Text(l10n.statsProgressLabel(
              (summary.progress * 100).round(),
            )),
          ],
        ),
      ),
    );
  }
}

class _FocusChart extends ConsumerWidget {
  const _FocusChart({required this.range});

  final StatsRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final start = range == StatsRange.day
        ? now.subtract(const Duration(days: 6))
        : DateTimeFormats.startOfWeek(now).subtract(const Duration(days: 21));
    final end = now;
    final focusRepo = ref.watch(focusRepositoryProvider);

    return StreamBuilder(
      stream: focusRepo.watchInRange(
        DateTimeFormats.formatDate(start),
        DateTimeFormats.formatDate(end),
      ),
      builder: (context, snapshot) {
        final records = snapshot.data ?? [];
        final buckets = <String, int>{};

        if (range == StatsRange.day) {
          for (var i = 0; i < 7; i++) {
            final d = now.subtract(Duration(days: 6 - i));
            buckets[DateTimeFormats.formatDate(d)] = 0;
          }
          for (final r in records) {
            buckets[r.date] = (buckets[r.date] ?? 0) + r.durationSeconds;
          }
        } else {
          for (var i = 0; i < 4; i++) {
            final w = DateTimeFormats.startOfWeek(
              now.subtract(Duration(days: (3 - i) * 7)),
            );
            buckets['W${i + 1}'] = 0;
            for (final r in records) {
              final rd = DateTime.parse(r.date);
              final ws = DateTimeFormats.startOfWeek(rd);
              if (ws == w) {
                buckets['W${i + 1}'] =
                    (buckets['W${i + 1}'] ?? 0) + r.durationSeconds;
              }
            }
          }
        }

        final keys = buckets.keys.toList();
        final spots = <BarChartGroupData>[];
        for (var i = 0; i < keys.length; i++) {
          spots.add(
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (buckets[keys[i]]! / 60).toDouble(),
                  color: Theme.of(context).colorScheme.primary,
                  width: 16,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          );
        }

        return BarChart(
          BarChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(
                    range == StatsRange.day
                        ? DateTimeFormats.formatMonthDay(
                            DateTime.parse(keys[v.toInt()]),
                          )
                        : keys[v.toInt()],
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: spots,
          ),
        );
      },
    );
  }
}

class _TodoChart extends ConsumerWidget {
  const _TodoChart({required this.range});

  final StatsRange range;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final repo = ref.watch(eventRepositoryProvider);
    final start = range == StatsRange.day
        ? now.subtract(const Duration(days: 6))
        : DateTimeFormats.startOfWeek(now).subtract(const Duration(days: 21));

    return StreamBuilder(
      stream: repo.watchInRange(
        DateTimeFormats.formatDate(start),
        DateTimeFormats.formatDate(now),
      ),
      builder: (context, snapshot) {
        final events = (snapshot.data ?? []).where((e) => e.isTodo).toList();
        final buckets = <String, double>{};

        if (range == StatsRange.day) {
          for (var i = 0; i < 7; i++) {
            final d = now.subtract(Duration(days: 6 - i));
            buckets[DateTimeFormats.formatDate(d)] = 0;
          }
          for (final key in buckets.keys) {
            final dayTodos =
                events.where((e) => e.date == key).toList(growable: false);
            if (dayTodos.isEmpty) continue;
            final done = dayTodos.where((e) => e.isCompleted).length;
            buckets[key] = done / dayTodos.length;
          }
        } else {
          for (var i = 0; i < 4; i++) {
            buckets['W${i + 1}'] = 0;
          }
        }

        final keys = buckets.keys.toList();
        return LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (v, _) => Text(
                    range == StatsRange.day && v.toInt() < keys.length
                        ? DateTimeFormats.formatMonthDay(
                            DateTime.parse(keys[v.toInt()]),
                          )
                        : keys[v.toInt()],
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 32),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < keys.length; i++)
                    FlSpot(i.toDouble(), buckets[keys[i]]! * 100),
                ],
                isCurved: true,
                color: Theme.of(context).colorScheme.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        );
      },
    );
  }
}
