import 'package:flutter/material.dart';

import '../../../core/utils/stats_format.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/statistics.dart';

class OverviewCard extends StatelessWidget {
  const OverviewCard({
    super.key,
    required this.overview,
    this.compact = false,
  });

  final StatsOverview overview;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.statsOverview,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (compact) ...[
              _MetricBlock(
                label: l10n.statsCompleted,
                value: '${overview.completedTodos}',
                muted: muted,
              ),
              const SizedBox(height: 10),
              _MetricBlock(
                label: l10n.statsPending,
                value: '${overview.pendingTodos}',
                muted: muted,
              ),
              const SizedBox(height: 10),
              _MetricBlock(
                label: l10n.statsFocusTime,
                value: StatsFormat.durationCompact(overview.focusSeconds),
                muted: muted,
                emphasize: true,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: _MetricBlock(
                      label: l10n.statsCompleted,
                      value: '${overview.completedTodos}',
                      muted: muted,
                    ),
                  ),
                  Expanded(
                    child: _MetricBlock(
                      label: l10n.statsPending,
                      value: '${overview.pendingTodos}',
                      muted: muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _MetricBlock(
                label: l10n.statsFocusTime,
                value: StatsFormat.durationCompact(overview.focusSeconds),
                muted: muted,
                emphasize: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.label,
    required this.value,
    required this.muted,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final Color muted;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium?.copyWith(color: muted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: (emphasize
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.titleLarge)
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
