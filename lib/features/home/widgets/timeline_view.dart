import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../core/theme/app_colors.dart';

/// Timeline rows: always sorted by start time, completion does not reorder.
class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.events,
    required this.onEventTap,
    this.onEventLongPress,
    this.onToggleComplete,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event>? onEventLongPress;
  final ValueChanged<Event>? onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final timelineEvents = events.where((e) => e.showsInTimeline).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    if (timelineEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No timeline items for this day',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.45),
                ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 10),
          ...timelineEvents.map((event) {
            final endParts = event.endTime.split(':');
            final endMin =
                int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
            final startParts = event.startTime.split(':');
            final startMin =
                int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
            final showNowLine = _isToday(event.date) &&
                nowMinutes >= startMin &&
                nowMinutes < endMin;
            final done = event.isTimelineDone(now);

            return Column(
              children: [
                if (showNowLine)
                  _NowIndicator(color: Theme.of(context).colorScheme.primary),
                _TimelineTile(
                  event: event,
                  done: done,
                  onTap: () => onEventTap(event),
                  onLongPress: onEventLongPress == null
                      ? null
                      : () => onEventLongPress!(event),
                  onToggle: onToggleComplete == null
                      ? null
                      : () => onToggleComplete!(event),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  bool _isToday(String date) {
    final d = DateTime.parse(date);
    final n = DateTime.now();
    return d.year == n.year && d.month == n.month && d.day == n.day;
  }
}

class _NowIndicator extends StatelessWidget {
  const _NowIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Container(height: 2, color: color.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.event,
    required this.done,
    required this.onTap,
    this.onLongPress,
    this.onToggle,
  });

  final Event event;
  final bool done;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.fromHex(event.color);
    final muted = theme.colorScheme.onSurface.withValues(alpha: done ? 0.4 : 0.85);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: done
            ? theme.colorScheme.surface.withValues(alpha: 0.5)
            : theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: done,
                    onChanged: onToggle == null ? null : (_) => onToggle!(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 36,
                  margin: const EdgeInsets.only(top: 2),
                  decoration: BoxDecoration(
                    color: done ? accent.withValues(alpha: 0.35) : accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${event.startTime} – ${event.endTime}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: muted.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        event.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: done ? TextDecoration.lineThrough : null,
                          color: muted,
                        ),
                      ),
                      if (event.isTodo)
                        Text(
                          'Todo',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary
                                .withValues(alpha: done ? 0.5 : 1),
                          ),
                        ),
                    ],
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
