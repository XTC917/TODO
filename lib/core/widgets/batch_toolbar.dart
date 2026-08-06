import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/demo_data.dart';
import '../providers/app_providers.dart';
import '../providers/batch_providers.dart';
import '../utils/date_time_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import 'swipe_event_actions.dart';

class BatchToolbar extends ConsumerWidget {
  const BatchToolbar({
    super.key,
    required this.batchProvider,
    required this.events,
    this.onEditSingle,
  });

  final StateNotifierProvider<BatchSelectionController, BatchSelection>
      batchProvider;
  final List<Event> events;
  final VoidCallback? onEditSingle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batch = ref.watch(batchProvider);
    if (!batch.active) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final count = batch.selectedIds.length;
    final theme = Theme.of(context);

    return Material(
      elevation: 1,
      color: theme.colorScheme.surfaceContainerHighest,
      child: SizedBox(
        height: 44,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Text(
                  l10n.batchSelected(count),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Flexible(
                flex: 10,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _ToolbarButton(
                        label: l10n.delete,
                        filled: true,
                        onPressed: count == 0
                            ? null
                            : () => _deleteSelected(
                                  context,
                                  ref,
                                  batch.selectedIds,
                                ),
                      ),
                      _ToolbarButton(
                        label: l10n.changeDate,
                        onPressed: count == 0
                            ? null
                            : () =>
                                _changeDate(context, ref, batch.selectedIds),
                      ),
                      if (count == 1 && onEditSingle != null)
                        _ToolbarButton(
                          label: l10n.edit,
                          onPressed: onEditSingle,
                        ),
                      _ToolbarButton(
                        label: l10n.cancel,
                        onPressed: () =>
                            ref.read(batchProvider.notifier).cancel(),
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

  Future<void> _deleteSelected(
    BuildContext context,
    WidgetRef ref,
    Set<int> ids,
  ) async {
    final realIds = ids.where((id) => !isDemoEventId(id)).toSet();
    if (realIds.isEmpty) return;

    if (!await confirmDeleteEvent(context)) return;

    try {
      await ref.read(eventActionsProvider).batchDelete(realIds);
      ref.read(batchProvider.notifier).cancel();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveFailedRetry),
        ),
      );
    }
  }

  Future<void> _changeDate(
    BuildContext context,
    WidgetRef ref,
    Set<int> ids,
  ) async {
    final l10n = AppLocalizations.of(context);
    final selected = events.where((e) => ids.contains(e.id)).toList();
    final dated = selected
        .where((e) => e.hasDate && !isDemoEventId(e.id))
        .toList();
    if (dated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noTimeTasksCannotChangeDate)),
      );
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked == null) return;

    final key = DateTimeFormats.formatDate(picked);
    await ref.read(eventActionsProvider).batchUpdateDate(
          dated.map((e) => e.id).toSet(),
          key,
        );
    ref.read(batchProvider.notifier).cancel();
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    if (filled) {
      return Padding(
        padding: const EdgeInsets.only(left: 4),
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          child: Text(label, maxLines: 1, style: style),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
        ),
        child: Text(label, maxLines: 1, style: style),
      ),
    );
  }
}
