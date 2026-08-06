import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/statistics_providers.dart';
import '../../l10n/app_localizations.dart';
import '../../models/statistics.dart';
import 'widgets/focus_bar_chart.dart';
import 'widgets/focus_ranking_card.dart';
import 'widgets/overview_card.dart';
import 'widgets/stats_period_label.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final period = ref.watch(statsPeriodProvider);
    final offset = ref.watch(statsPeriodOffsetProvider);
    final query = StatsQuery(period: period, offset: offset);
    final dashboard = ref.watch(statsDashboardProvider(query));
    final locale = Localizations.localeOf(context);
    final periodLabel = statsPeriodLabel(l10n, period, offset, locale);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.statsTitle,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 14),
              SegmentedButton<StatsPeriod>(
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                  selectedBackgroundColor:
                      scheme.onSurface.withValues(alpha: 0.12),
                  selectedForegroundColor: scheme.onSurface,
                  foregroundColor: scheme.onSurface.withValues(alpha: 0.5),
                ),
                segments: [
                  ButtonSegment(
                    value: StatsPeriod.day,
                    label: Text(l10n.statsDay),
                  ),
                  ButtonSegment(
                    value: StatsPeriod.week,
                    label: Text(l10n.statsWeek),
                  ),
                  ButtonSegment(
                    value: StatsPeriod.month,
                    label: Text(l10n.statsMonth),
                  ),
                  ButtonSegment(
                    value: StatsPeriod.year,
                    label: Text(l10n.statsYear),
                  ),
                ],
                selected: {period},
                onSelectionChanged: (selection) {
                  ref.read(statsPeriodProvider.notifier).state =
                      selection.first;
                  ref.read(statsPeriodOffsetProvider.notifier).state = 0;
                },
              ),
              const SizedBox(height: 12),
              Text(
                periodLabel,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _StatsSwipeArea(
                  onSwipePrevious: () {
                    ref.read(statsPeriodOffsetProvider.notifier).state =
                        offset - 1;
                  },
                  onSwipeNext: () {
                    ref.read(statsPeriodOffsetProvider.notifier).state =
                        offset + 1;
                  },
                  child: dashboard.when(
                    data: (data) => AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        final offsetAnim = Tween<Offset>(
                          begin: const Offset(0.04, 0),
                          end: Offset.zero,
                        ).animate(animation);
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: offsetAnim,
                            child: child,
                          ),
                        );
                      },
                      child: _StatsBody(
                        key: ValueKey('$period-$offset'),
                        period: period,
                        dashboard: data,
                      ),
                    ),
                    loading: () => const Center(
                      child: CircularProgressIndicator.adaptive(),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Only horizontal swipes change the stats period offset.
class _StatsSwipeArea extends StatelessWidget {
  const _StatsSwipeArea({
    required this.onSwipePrevious,
    required this.onSwipeNext,
    required this.child,
  });

  final VoidCallback onSwipePrevious;
  final VoidCallback onSwipeNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanEnd: (details) {
        final velocity = details.velocity.pixelsPerSecond;
        if (velocity.dx.abs() <= velocity.dy.abs()) return;
        if (velocity.dx > 180) {
          onSwipePrevious();
        } else if (velocity.dx < -180) {
          onSwipeNext();
        }
      },
      child: child,
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({
    super.key,
    required this.period,
    required this.dashboard,
  });

  final StatsPeriod period;
  final StatsDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    if (period == StatsPeriod.day) {
      if (isLandscape) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: OverviewCard(overview: dashboard.overview),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 6,
              child: FocusRankingCard(
                entries: dashboard.ranking,
                period: period,
              ),
            ),
          ],
        );
      }
      return Column(
        children: [
          Expanded(
            flex: 4,
            child: OverviewCard(overview: dashboard.overview),
          ),
          const SizedBox(height: 12),
          Expanded(
            flex: 6,
            child: FocusRankingCard(
              entries: dashboard.ranking,
              period: period,
            ),
          ),
        ],
      );
    }

    final chartTitle = period == StatsPeriod.year
        ? l10n.statsMonthlyFocus
        : l10n.statsDailyFocus;
    final chart = FocusBarChart(
      title: chartTitle,
      buckets: dashboard.chartBuckets,
      period: period,
    );

    if (isLandscape) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: Column(
              children: [
                Expanded(
                  child: OverviewCard(
                    overview: dashboard.overview,
                    compact: true,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: FocusRankingCard(
                    entries: dashboard.ranking,
                    period: period,
                    maxItems: 5,
                    compact: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(flex: 6, child: chart),
        ],
      );
    }

    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: OverviewCard(
                  overview: dashboard.overview,
                  compact: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 6,
                child: FocusRankingCard(
                  entries: dashboard.ranking,
                  period: period,
                  maxItems: 5,
                  compact: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Expanded(child: chart),
      ],
    );
  }
}
