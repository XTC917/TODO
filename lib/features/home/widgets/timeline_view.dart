import 'package:flutter/material.dart';

import '../../../models/event.dart';

/// Timeline axis layout — flat, time-first, distinct from Todo cards.
class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.events,
    required this.onEventTap,
    this.onEventLongPress,
    this.onToggleComplete,
    this.selectedIds = const {},
    this.batchActive = false,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event>? onEventLongPress;
  final ValueChanged<Event>? onToggleComplete;
  final Set<int> selectedIds;
  final bool batchActive;

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

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final now = DateTime.now();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Timeline',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ...timelineEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final done = event.isTimelineDone(now);
            final selected = selectedIds.contains(event.id);
            final isLast = index == timelineEvents.length - 1;

            return _TimelineAxisRow(
              event: event,
              done: done,
              selected: selected,
              batchActive: batchActive,
              primary: primary,
              showLine: !isLast,
              onTap: () => onEventTap(event),
              onLongPress: onEventLongPress == null
                  ? null
                  : () => onEventLongPress!(event),
              onToggle: onToggleComplete == null
                  ? null
                  : () => onToggleComplete!(event),
            );
          }),
        ],
      ),
    );
  }
}

class _TimelineAxisRow extends StatelessWidget {
  const _TimelineAxisRow({
    required this.event,
    required this.done,
    required this.selected,
    required this.batchActive,
    required this.primary,
    required this.showLine,
    required this.onTap,
    this.onLongPress,
    this.onToggle,
  });

  final Event event;
  final bool done;
  final bool selected;
  final bool batchActive;
  final Color primary;
  final bool showLine;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: done ? 0.38 : 0.88);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: selected
              ? primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 72,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${event.startTime}–${event.endTime}',
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: done
                            ? muted.withValues(alpha: 0.6)
                            : primary,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    const SizedBox(height: 4),
                    if (batchActive)
                      Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: selected ? primary : muted.withValues(alpha: 0.4),
                      )
                    else
                      GestureDetector(
                        onTap: onToggle,
                        child: Icon(
                          done
                              ? Icons.check_circle
                              : Icons.circle_outlined,
                          size: 14,
                          color: done
                              ? muted.withValues(alpha: 0.5)
                              : primary,
                        ),
                      ),
                    if (showLine)
                      Expanded(
                        child: Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: theme.dividerColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration: done ? TextDecoration.lineThrough : null,
                        color: muted,
                      ),
                    ),
                    if (showLine)
                      Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 4),
                        child: Divider(
                          height: 1,
                          color: theme.dividerColor.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
