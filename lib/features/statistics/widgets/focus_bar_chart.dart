import 'package:flutter/material.dart';

import '../../../core/utils/date_time_formats.dart';
import '../../../core/utils/stats_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/statistics.dart';

class FocusBarChart extends StatefulWidget {
  const FocusBarChart({
    super.key,
    required this.title,
    required this.buckets,
    this.period,
  });

  final String title;
  final List<FocusChartBucket> buckets;
  final StatsPeriod? period;

  @override
  State<FocusBarChart> createState() => _FocusBarChartState();
}

class _FocusBarChartState extends State<FocusBarChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant FocusBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.buckets != widget.buckets) {
      _selectedIndex = null;
    }
  }

  Color _barColor(int seconds, int min, int max, ColorScheme scheme) {
    if (max <= 0) {
      return scheme.primary.withValues(alpha: 0.2);
    }
    if (max == min) return scheme.primary;
    final t = (seconds - min) / (max - min);
    return Color.lerp(
      scheme.primary.withValues(alpha: 0.28),
      scheme.primary,
      t.clamp(0.0, 1.0),
    )!;
  }

  String _bucketTitle(AppLocalizations l10n, FocusChartBucket bucket) {
    if (bucket.date == null) return bucket.label;
    return switch (widget.period) {
      StatsPeriod.week => DateTimeFormats.formatWeekday(bucket.date!),
      StatsPeriod.month => DateTimeFormats.formatMonthDay(bucket.date!),
      StatsPeriod.year => DateTimeFormats.shortMonth.format(bucket.date!),
      _ => bucket.label,
    };
  }

  String _xLabel(int index, FocusChartBucket bucket) {
    if (widget.period == StatsPeriod.month) {
      return index.isEven ? bucket.label : '';
    }
    return bucket.label;
  }

  Widget _buildXLabel(
    int index,
    FocusChartBucket bucket, {
    required Color muted,
  }) {
    final label = _xLabel(index, bucket);
    if (label.isEmpty) return const SizedBox.shrink();

    final text = Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: widget.period == StatsPeriod.month ? 9 : 10,
            color: muted,
            height: 1,
          ),
    );

    if (widget.period == StatsPeriod.month) {
      return Center(
        child: OverflowBox(
          maxWidth: 28,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: text,
          ),
        ),
      );
    }

    return Center(child: text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final values = widget.buckets.map((b) => b.focusSeconds).toList();
    final rawMax =
        values.isEmpty ? 0 : values.reduce((a, b) => a > b ? a : b);
    final minValue =
        values.isEmpty ? 0 : values.reduce((a, b) => a < b ? a : b);
    const yAxisWidth = 34.0;
    const xLabelHeight = 16.0;
    const xGap = 4.0;
    final selected = _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < widget.buckets.length
        ? widget.buckets[_selectedIndex!]
        : null;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final plotHeight = (constraints.maxHeight -
                          (widget.period == StatsPeriod.month ? 18.0 : xLabelHeight) -
                          xGap)
                      .clamp(48.0, constraints.maxHeight);
                  final scaleMax = StatsFormat.chartScaleMax(rawMax);
                  final yTicks = StatsFormat.yAxisTicks(
                    rawMax,
                    plotHeight: plotHeight,
                  );
                  const minLabelGap = 18.0;
                  final visibleTicks = <int>[];
                  double? lastTop;
                  for (final tick in yTicks) {
                    final top = plotHeight * (1 - tick / scaleMax);
                    if (lastTop == null ||
                        (top - lastTop).abs() >= minLabelGap ||
                        tick == 0) {
                      visibleTicks.add(tick);
                      lastTop = top;
                    }
                  }

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = null),
                    child: Column(
                      children: [
                        SizedBox(
                          height: plotHeight,
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(
                                    width: yAxisWidth,
                                    child: Stack(
                                      clipBehavior: Clip.hardEdge,
                                      children: [
                                        for (final tick in visibleTicks)
                                          Positioned(
                                            left: 0,
                                            right: 0,
                                            top: (plotHeight *
                                                        (1 -
                                                            tick / scaleMax) -
                                                    5)
                                                .clamp(0.0, plotHeight - 12),
                                            child: Text(
                                              StatsFormat.durationCompact(
                                                tick,
                                              ),
                                              textAlign: TextAlign.right,
                                              maxLines: 1,
                                              overflow: TextOverflow.clip,
                                              style: theme.textTheme.labelSmall
                                                  ?.copyWith(
                                                fontSize: 9,
                                                color: muted,
                                                height: 1,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        for (var i = 0;
                                            i < widget.buckets.length;
                                            i++)
                                          Expanded(
                                            child: _BarColumn(
                                              bucket: widget.buckets[i],
                                              maxValue: scaleMax,
                                              plotHeight: plotHeight,
                                              color: _barColor(
                                                widget.buckets[i]
                                                    .focusSeconds,
                                                minValue,
                                                rawMax,
                                                theme.colorScheme,
                                              ),
                                              selected: _selectedIndex == i,
                                              onTap: () {
                                                setState(
                                                  () => _selectedIndex = i,
                                                );
                                              },
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (selected != null && _selectedIndex != null)
                                _InfoCardOverlay(
                                  index: _selectedIndex!,
                                  count: widget.buckets.length,
                                  plotWidth:
                                      constraints.maxWidth - yAxisWidth,
                                  leftInset: yAxisWidth,
                                  plotHeight: plotHeight,
                                  title: _bucketTitle(l10n, selected),
                                  focusLabel: StatsFormat.durationCompact(
                                    selected.focusSeconds,
                                  ),
                                  sessionsLabel: l10n.statsSessionsCount(
                                    selected.sessionCount,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: xGap),
                        SizedBox(
                          height: widget.period == StatsPeriod.month
                              ? 18.0
                              : xLabelHeight,
                          child: Row(
                            children: [
                              SizedBox(width: yAxisWidth),
                              Expanded(
                                child: Row(
                                  children: [
                                    for (var i = 0;
                                        i < widget.buckets.length;
                                        i++)
                                      Expanded(
                                        child: _buildXLabel(
                                          i,
                                          widget.buckets[i],
                                          muted: muted,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  const _BarColumn({
    required this.bucket,
    required this.maxValue,
    required this.plotHeight,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final FocusChartBucket bucket;
  final int maxValue;
  final double plotHeight;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ratio = bucket.focusSeconds / maxValue;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 360),
            curve: Curves.easeOutCubic,
            builder: (context, animatedRatio, _) {
              final height = bucket.focusSeconds <= 0
                  ? 2.0
                  : (plotHeight * animatedRatio).clamp(2.0, plotHeight);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: height,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                  border: selected
                      ? Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.35),
                          width: 1,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _InfoCardOverlay extends StatelessWidget {
  const _InfoCardOverlay({
    required this.index,
    required this.count,
    required this.plotWidth,
    required this.leftInset,
    required this.plotHeight,
    required this.title,
    required this.focusLabel,
    required this.sessionsLabel,
  });

  final int index;
  final int count;
  final double plotWidth;
  final double leftInset;
  final double plotHeight;
  final String title;
  final String focusLabel;
  final String sessionsLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    const cardWidth = 140.0;
    final slotWidth = plotWidth / count;
    var left = slotWidth * index + slotWidth / 2 - cardWidth / 2;
    left = left.clamp(0.0, plotWidth - cardWidth);

    return Positioned(
      left: leftInset + left,
      top: 4,
      child: Material(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: SizedBox(
            width: cardWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.statsFocus,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 10,
                  ),
                ),
                Text(
                  focusLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  sessionsLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
