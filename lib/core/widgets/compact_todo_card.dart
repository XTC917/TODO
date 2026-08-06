import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../providers/l10n_providers.dart';
import '../utils/event_display.dart';

/// Compact todo card — distinct from Timeline axis rows.
class CompactTodoCard extends ConsumerWidget {
  const CompactTodoCard({
    super.key,
    required this.event,
    required this.completed,
    required this.onTap,
    this.onToggle,
    this.onLongPress,
    this.selected = false,
    this.batchActive = false,
  });

  final Event event;
  final bool completed;
  final VoidCallback onTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onLongPress;
  final bool selected;
  final bool batchActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final l10n = ref.watch(appLocalizationsProvider);
    final timeLabel = eventTimeLabel(event, l10n);

    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
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
              color: selected ? primary : Colors.transparent,
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
                      onChanged: onToggle == null
                          ? null
                          : (v) => onToggle!(v ?? false),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            timeLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: completed ? 0.35 : 0.5,
                              ),
                            ),
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
