import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../core/theme/app_colors.dart';

class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.events,
    required this.onEventTap,
    this.onEventLongPress,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event>? onEventLongPress;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No events for this day',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
          const SizedBox(height: 12),
          ...events.map((event) {
            final startParts = event.startTime.split(':');
            final startMin =
                int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
            final showNowLine = _isToday(event.date) &&
                nowMinutes >= startMin &&
                nowMinutes <
                    int.parse(event.endTime.split(':')[0]) * 60 +
                        int.parse(event.endTime.split(':')[1]);

            return Column(
              children: [
                if (showNowLine) _NowIndicator(color: Theme.of(context).colorScheme.primary),
                _TimelineTile(
                  event: event,
                  onTap: () => onEventTap(event),
                  onLongPress: onEventLongPress == null
                      ? null
                      : () => onEventLongPress!(event),
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
    required this.onTap,
    this.onLongPress,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.fromHex(event.color);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 52,
              child: Text(
                event.startTime,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                    ),
              ),
            ),
            Container(
              width: 3,
              height: 40,
              margin: const EdgeInsets.only(right: 12, top: 2),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: event.isTodo && event.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                          color: event.isTodo && event.isCompleted
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45)
                              : null,
                        ),
                  ),
                  if (event.isTodo)
                    Text(
                      'Todo',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
