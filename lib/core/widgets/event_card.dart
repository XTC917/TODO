import 'package:flutter/material.dart';

import '../../models/event.dart';
import '../data/demo_data.dart';
import '../theme/app_colors.dart';
import 'demo_sample_badge.dart';

class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.onLongPress,
    this.showCheckbox = false,
    this.completed = false,
    this.onToggle,
  });

  final Event event;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool showCheckbox;
  final bool completed;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = AppColors.fromHex(event.color);
    final hasNote = event.note != null && event.note!.isNotEmpty;

    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(22),
                    ),
                  ),
                ),
                if (showCheckbox) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Checkbox(
                      value: completed,
                      onChanged: onToggle == null
                          ? null
                          : (v) => onToggle!(v ?? false),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${event.startTime} - ${event.endTime}',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: completed ? 0.35 : 0.55),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            if (isDemoEventId(event.id)) ...[
                              const DemoSampleBadge(),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                event.title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  decoration: completed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: completed
                                      ? theme.colorScheme.onSurface
                                          .withValues(alpha: 0.45)
                                      : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (hasNote) ...[
                          const SizedBox(height: 6),
                          Text(
                            event.note!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                        if (event.isTodo && event.focusedSeconds > 0) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Focused: ${_formatFocus(event.focusedSeconds)}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFocus(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$h h $m min';
    return '$m min';
  }
}
