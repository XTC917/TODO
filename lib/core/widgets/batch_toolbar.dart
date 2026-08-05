import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../providers/batch_providers.dart';
import '../utils/date_time_formats.dart';
import '../../models/event.dart';

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

    final count = batch.selectedIds.length;

    return Material(
      elevation: 1,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Selected $count',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(batchProvider.notifier).cancel(),
              child: const Text('Cancel'),
            ),
            if (count == 1 && onEditSingle != null)
              TextButton(onPressed: onEditSingle, child: const Text('Edit')),
            TextButton(
              onPressed: count == 0
                  ? null
                  : () => _changeDate(context, ref, batch.selectedIds),
              child: const Text('Change date'),
            ),
            FilledButton(
              onPressed: count == 0
                  ? null
                  : () => _deleteSelected(ref, batch.selectedIds),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteSelected(WidgetRef ref, Set<int> ids) async {
    await ref.read(eventActionsProvider).batchDelete(ids);
    ref.read(batchProvider.notifier).cancel();
  }

  Future<void> _changeDate(
    BuildContext context,
    WidgetRef ref,
    Set<int> ids,
  ) async {
    final selected = events.where((e) => ids.contains(e.id)).toList();
    final dated = selected.where((e) => e.hasDate).toList();
    if (dated.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No-time tasks cannot change date.')),
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
