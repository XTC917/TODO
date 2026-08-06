import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/stats_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/statistics.dart';

Future<void> showFocusRankingSheet({
  required BuildContext context,
  required List<FocusRankingEntry> entries,
  required StatsPeriod period,
  int? initialExpandedIndex,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _FocusRankingSheet(
      entries: entries,
      period: period,
      initialExpandedIndex: initialExpandedIndex,
    ),
  );
}

class _FocusRankingSheet extends StatefulWidget {
  const _FocusRankingSheet({
    required this.entries,
    required this.period,
    this.initialExpandedIndex,
  });

  final List<FocusRankingEntry> entries;
  final StatsPeriod period;
  final int? initialExpandedIndex;

  @override
  State<_FocusRankingSheet> createState() => _FocusRankingSheetState();
}

class _FocusRankingSheetState extends State<_FocusRankingSheet> {
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    _expandedIndex = widget.initialExpandedIndex;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: maxHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l10n.statsFocusRanking,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: widget.entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = widget.entries[index];
                  final name = entry.nameKey.isEmpty
                      ? l10n.focusNoTask
                      : entry.nameKey;
                  final color = AppColors
                      .eventPalette[entry.nameKey.hashCode.abs() %
                          AppColors.eventPalette.length];
                  final expanded = _expandedIndex == index;

                  return Material(
                    color: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(
                        () => _expandedIndex = expanded ? null : index,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 4,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style:
                                            theme.textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        l10n.statsSessionsCount(
                                          entry.sessionCount,
                                        ),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  StatsFormat.durationCompact(
                                    entry.totalSeconds,
                                  ),
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Icon(
                                  expanded
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 20,
                                  color: muted,
                                ),
                              ],
                            ),
                            if (expanded) ...[
                              const SizedBox(height: 10),
                              const Divider(height: 1),
                              const SizedBox(height: 8),
                              ...entry.sessions.map(
                                (session) {
                                  final showDate =
                                      widget.period != StatsPeriod.day;
                                  final detail = l10n.statsSessionDetail(
                                    session.startTime,
                                    session.endTime,
                                    StatsFormat.durationCompact(
                                      session.durationSeconds,
                                    ),
                                  );
                                  final line = showDate
                                      ? '${session.date}  $detail'
                                      : detail;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Text(
                                      line,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        color: muted,
                                        height: 1.4,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
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
