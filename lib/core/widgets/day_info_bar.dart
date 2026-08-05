import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../utils/date_time_formats.dart';

/// Compact one-line summary bar for the home page header.
class DayInfoBar extends StatelessWidget {
  const DayInfoBar({super.key, required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focus = summary.focusSeconds > 0
        ? ' · Focus ${DateTimeFormats.formatDuration(summary.focusSeconds)}'
        : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          '${summary.scheduleTotal} schedules · '
          '${summary.todoTotal} todos · '
          'done ${summary.todoCompleted}$focus',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
