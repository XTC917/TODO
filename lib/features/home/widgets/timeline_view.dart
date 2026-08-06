import 'package:flutter/material.dart';

import '../../../models/event.dart';
import '../../../core/widgets/swipe_event_actions.dart';
import '../../../l10n/app_localizations.dart';

/// Timeline axis layout — time-first, no card chrome, distinct from Todo cards.
class TimelineView extends StatelessWidget {
  const TimelineView({
    super.key,
    required this.events,
    required this.onEventTap,
    this.onEventLongPress,
    this.onToggleComplete,
    this.onSwipeEdit,
    this.onSwipeDuplicate,
    this.onSwipeDelete,
    this.selectedIds = const {},
    this.batchActive = false,
    this.showTitle = true,
    this.emptyMessage,
    this.compact = false,
  });

  final List<Event> events;
  final ValueChanged<Event> onEventTap;
  final ValueChanged<Event>? onEventLongPress;
  final ValueChanged<Event>? onToggleComplete;
  final ValueChanged<Event>? onSwipeEdit;
  final ValueChanged<Event>? onSwipeDuplicate;
  final ValueChanged<Event>? onSwipeDelete;
  final Set<int> selectedIds;
  final bool batchActive;
  final bool showTitle;
  final String? emptyMessage;
  final bool compact;

  bool get _swipeEnabled =>
      !batchActive &&
      onSwipeEdit != null &&
      onSwipeDuplicate != null &&
      onSwipeDelete != null;

  @override
  Widget build(BuildContext context) {
    final timelineEvents = events.where((e) => e.showsInTimeline).toList()
      ..sort((a, b) => a.timelineSortKey.compareTo(b.timelineSortKey));

    if (timelineEvents.isEmpty) {
      final l10n = AppLocalizations.of(context);
      final msg = emptyMessage ?? l10n.noTimelineItems;
      return Padding(
        padding: EdgeInsets.all(compact ? 16 : 24),
        child: Center(
          child: Text(
            msg,
            textAlign: TextAlign.center,
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
    final horizontalPadding = compact ? 8.0 : 20.0;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showTitle) ...[
            Text(
              l10n.timeline,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
          ],
          ...timelineEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final done = event.isCompleted;
            final selected = selectedIds.contains(event.id);
            final isLast = index == timelineEvents.length - 1;

            final row = _TimelineAxisRow(
              event: event,
              done: done,
              selected: selected,
              batchActive: batchActive,
              primary: primary,
              showLine: !isLast,
              compact: compact,
              onTap: () => onEventTap(event),
              onLongPress: onEventLongPress == null
                  ? null
                  : () => onEventLongPress!(event),
              onToggleComplete: onToggleComplete == null
                  ? null
                  : () => onToggleComplete!(event),
            );

            if (!_swipeEnabled) return row;

            return SwipeEventActions(
              event: event,
              enabled: true,
              onEdit: () => onSwipeEdit!(event),
              onDuplicate: () => onSwipeDuplicate!(event),
              onDelete: () => onSwipeDelete!(event),
              child: row,
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
    required this.compact,
    required this.onTap,
    this.onLongPress,
    this.onToggleComplete,
  });

  final Event event;
  final bool done;
  final bool selected;
  final bool batchActive;
  final Color primary;
  final bool showLine;
  final bool compact;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted =
        theme.colorScheme.onSurface.withValues(alpha: done ? 0.38 : 0.88);
    final timeColor =
        done ? muted.withValues(alpha: 0.55) : primary.withValues(alpha: 0.95);

    return Container(
      decoration: BoxDecoration(
        color: selected ? primary.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: compact ? 46 : 52,
              child: _TimelineTimeColumn(
                event: event,
                color: timeColor,
                lineColor: timeColor.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  const SizedBox(height: 2),
                  _CompletionDot(
                    done: done,
                    selected: selected,
                    batchActive: batchActive,
                    primary: primary,
                    muted: muted,
                    onToggle: onToggleComplete,
                  ),
                  if (showLine)
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          color: theme.dividerColor.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  onLongPress: onLongPress,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding:
                        const EdgeInsets.only(top: 2, bottom: 10, right: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration:
                                done ? TextDecoration.lineThrough : null,
                            color: muted,
                            height: 1.25,
                          ),
                        ),
                        if (event.isDeadlineTodo)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              AppLocalizations.of(context).deadlineBadge,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted.withValues(alpha: 0.55),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionDot extends StatelessWidget {
  const _CompletionDot({
    required this.done,
    required this.selected,
    required this.batchActive,
    required this.primary,
    required this.muted,
    this.onToggle,
  });

  final bool done;
  final bool selected;
  final bool batchActive;
  final Color primary;
  final Color muted;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    if (batchActive) {
      return Icon(
        selected ? Icons.check_circle : Icons.radio_button_unchecked,
        size: 18,
        color: selected ? primary : muted.withValues(alpha: 0.4),
      );
    }

    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
            color: done ? muted.withValues(alpha: 0.5) : primary,
          ),
        ),
      ),
    );
  }
}

class _TimelineTimeColumn extends StatelessWidget {
  const _TimelineTimeColumn({
    required this.event,
    required this.color,
    required this.lineColor,
  });

  final Event event;
  final Color color;
  final Color lineColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.15,
          fontSize: 12,
        );

    if (event.isDeadlineTodo) {
      final time = event.endTime.isEmpty ? '--:--' : event.endTime;
      return Align(
        alignment: Alignment.centerLeft,
        child: Text(time, style: style),
      );
    }

    if (event.startTime.isEmpty || event.endTime.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(event.startTime, style: style),
        SizedBox(
          height: 16,
          child: Center(
            child: Text(
              '│',
              style: style?.copyWith(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w400,
                color: lineColor,
              ),
            ),
          ),
        ),
        Text(event.endTime, style: style),
      ],
    );
  }
}
