import 'package:flutter/material.dart';

import '../../models/event.dart';

/// Compact todo card — distinct from Timeline axis rows.
class CompactTodoCard extends StatelessWidget {
  const CompactTodoCard({
    super.key,
    required this.event,
    required this.completed,
    required this.onTap,
    required this.onToggle,
    this.onLongPress,
    this.selected = false,
    this.batchActive = false,
  });

  final Event event;
  final bool completed;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool batchActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final timeLabel = event.timeLabel;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.1)
                : theme.cardTheme.color,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? primary
                  : Colors.transparent,
              width: selected ? 1.5 : 0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: completed ? 0.35 : 1),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              if (batchActive)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(
                    selected
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: selected ? primary : theme.dividerColor,
                    size: 22,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: SizedBox(
                    width: 32,
                    height: 32,
                    child: Checkbox(
                      value: completed,
                      onChanged: (v) => onToggle(v ?? false),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          decoration:
                              completed ? TextDecoration.lineThrough : null,
                          color: completed
                              ? theme.colorScheme.onSurface
                                  .withValues(alpha: 0.45)
                              : null,
                        ),
                      ),
                      if (timeLabel.isNotEmpty)
                        Text(
                          timeLabel,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: completed ? 0.35 : 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
