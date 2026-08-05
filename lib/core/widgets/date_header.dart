import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/event.dart';
import '../providers/app_providers.dart';
import '../providers/focus_providers.dart';
import '../utils/date_time_formats.dart';

/// Date display header (swipe handled by parent page).
class DateHeader extends StatelessWidget {
  const DateHeader({
    super.key,
    required this.selected,
    this.onBackToToday,
  });

  final DateTime selected;
  final VoidCallback? onBackToToday;

  @override
  Widget build(BuildContext context) {
    final isToday = DateTimeFormats.isSameDay(selected, DateTime.now());

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Padding(
        key: ValueKey(selected),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 4),
        child: Column(
          children: [
            Text(
              DateTimeFormats.formatHeader(selected),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              '← swipe anywhere to change day →',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.4),
                  ),
            ),
            if (!isToday && onBackToToday != null) ...[
              const SizedBox(height: 4),
              TextButton.icon(
                onPressed: onBackToToday,
                icon: const Icon(Icons.today_rounded, size: 16),
                label: const Text('Back to Today'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

void showEventContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Event event,
  required VoidCallback onEdit,
  required VoidCallback onDeleted,
}) {
  final canComplete = event.isTodo || event.isSchedule;

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canComplete)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: Text(
                  event.isTimelineDone(DateTime.now())
                      ? 'Mark Incomplete'
                      : 'Complete',
                ),
                onTap: () async {
                  Navigator.pop(ctx);
                  final done = event.isTimelineDone(DateTime.now());
                  await ref
                      .read(eventActionsProvider)
                      .toggleTimeline(event.id, !done);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(ctx);
                onEdit();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Duplicate'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref.read(eventActionsProvider).duplicate(event.id);
              },
            ),
            if (event.isTodo)
              ListTile(
                leading: Icon(Icons.play_circle_outline,
                    color: Theme.of(ctx).colorScheme.primary),
                title: const Text('Start Focus'),
                onTap: () {
                  Navigator.pop(ctx);
                  ref.read(focusLaunchProvider.notifier).state =
                      FocusLaunchConfig(eventId: event.id);
                  ref.read(shellTabProvider.notifier).state = 2;
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.pop(ctx);
                await _confirmDelete(context, ref, event, onDeleted);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _confirmDelete(
  BuildContext context,
  WidgetRef ref,
  Event event,
  VoidCallback onDeleted,
) async {
  if (event.repeatType != RepeatType.oneTime && event.repeatGroupId != null) {
    final scope = await showDialog<DeleteRepeatScope>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Delete recurring event'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, DeleteRepeatScope.onlyThis),
            child: const Text('Only this event'),
          ),
          SimpleDialogOption(
            onPressed: () =>
                Navigator.pop(ctx, DeleteRepeatScope.thisAndFuture),
            child: const Text('This and future events'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, DeleteRepeatScope.all),
            child: const Text('All events'),
          ),
        ],
      ),
    );
    if (scope == null) return;
    await ref.read(eventActionsProvider).deleteWithScope(event, scope);
  } else {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(eventActionsProvider).delete(event.id);
  }
  onDeleted();
}
