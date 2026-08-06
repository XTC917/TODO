import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/stats_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/statistics.dart';
import 'focus_ranking_sheet.dart';

class FocusRankingCard extends StatelessWidget {
  const FocusRankingCard({
    super.key,
    required this.entries,
    required this.period,
    this.maxItems = 3,
    this.compact = false,
  });

  final List<FocusRankingEntry> entries;
  final StatsPeriod period;
  final int maxItems;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final top = entries.take(maxItems).toList(growable: false);
    final maxSeconds = top.isEmpty
        ? 1
        : top.map((e) => e.totalSeconds).reduce((a, b) => a > b ? a : b);
    final rowGap = compact ? 7.0 : 14.0;
    final showViewAll = entries.length > maxItems;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          compact ? 12 : 16,
          20,
          compact ? 10 : 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.statsFocusRanking,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: compact ? 6 : 12),
            Expanded(
              child: top.isEmpty
                  ? Center(
                      child: Text(
                        l10n.statsRankingEmpty,
                        style:
                            theme.textTheme.bodyMedium?.copyWith(color: muted),
                      ),
                    )
                  : SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var i = 0; i < top.length; i++) ...[
                            if (i > 0) SizedBox(height: rowGap),
                            _RankingRow(
                              name: _displayName(l10n, top[i].nameKey),
                              durationLabel: StatsFormat.durationCompact(
                                top[i].totalSeconds,
                              ),
                              ratio: top[i].totalSeconds / maxSeconds,
                              color: _colorForName(top[i].nameKey, i),
                              muted: muted,
                              compact: compact,
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            if (showViewAll)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.only(top: 4),
                    minimumSize: Size.zero,
                  ),
                  onPressed: () => showFocusRankingSheet(
                    context: context,
                    entries: entries,
                    period: period,
                  ),
                  child: Text(l10n.statsViewAll),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _displayName(AppLocalizations l10n, String nameKey) {
    if (nameKey.isEmpty) return l10n.focusNoTask;
    return nameKey;
  }

  static Color _colorForName(String nameKey, int fallbackIndex) {
    final palette = AppColors.eventPalette;
    if (nameKey.isEmpty) {
      return palette[fallbackIndex % palette.length];
    }
    return palette[nameKey.hashCode.abs() % palette.length];
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.name,
    required this.durationLabel,
    required this.ratio,
    required this.color,
    required this.muted,
    this.compact = false,
  });

  final String name;
  final String durationLabel;
  final double ratio;
  final Color color;
  final Color muted;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (compact
                        ? theme.textTheme.bodySmall
                        : theme.textTheme.bodyMedium)
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              durationLabel,
              style: (compact
                      ? theme.textTheme.labelMedium
                      : theme.textTheme.labelLarge)
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        SizedBox(height: compact ? 3 : 6),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth * ratio.clamp(0.08, 1.0);
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: width),
              duration: const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              builder: (context, animatedWidth, _) {
                return Container(
                  height: compact ? 7 : 10,
                  width: animatedWidth,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(compact ? 4 : 5),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
