import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/batch_providers.dart';
import '../../core/widgets/batch_toolbar.dart';
import '../../core/widgets/compact_todo_card.dart';
import '../../core/widgets/event_detail_sheet.dart';
import '../../core/widgets/repeat_scope_dialog.dart';
import '../../core/widgets/swipe_event_actions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../schedule/event_form_page.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(allTodosProvider);
    final batch = ref.watch(todoBatchProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BatchToolbar(
              batchProvider: todoBatchProvider,
              events: todosAsync.valueOrNull ?? const [],
              onEditSingle: batch.selectedIds.length == 1
                  ? () {
                      final id = batch.selectedIds.first;
                      ref.read(todoBatchProvider.notifier).cancel();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventFormPage(eventId: id),
                        ),
                      );
                    }
                  : null,
            ),
            Expanded(
              child: todosAsync.when(
                data: (todos) => _TodoListBody(
                  todos: todos,
                  batch: batch,
                  onEnterBatch: (id) {
                    ref.read(todoBatchProvider.notifier).enterWith(id);
                  },
                  onTap: (todo) {
                    if (batch.active) {
                      ref.read(todoBatchProvider.notifier).toggle(todo.id);
                    } else {
                      showEventDetailSheet(
                        context: context,
                        ref: ref,
                        event: todo,
                      );
                    }
                  },
                  onToggleComplete: (todo, v) {
                    ref.read(eventActionsProvider).toggleOccurrence(todo, v);
                  },
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(
                  child: Text(AppLocalizations.of(context).errorGeneric('$e')),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: batch.active
          ? null
          : FloatingActionButton(
              onPressed: () {
                final selected = ref.read(homeSelectedDateProvider);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EventFormPage(initialDate: selected),
                  ),
                );
              },
              child: const Icon(Icons.add_rounded),
            ),
    );
  }
}

class _TodoListBody extends ConsumerWidget {
  const _TodoListBody({
    required this.todos,
    required this.batch,
    required this.onEnterBatch,
    required this.onTap,
    required this.onToggleComplete,
  });

  final List<Event> todos;
  final BatchSelection batch;
  final ValueChanged<int> onEnterBatch;
  final ValueChanged<Event> onTap;
  final void Function(Event todo, bool completed) onToggleComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (todos.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noTodosYet));
    }

    final pendingTimed =
        todos.where((t) => !t.isNoTimeTodo && !t.isCompleted).toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final pendingNoTime =
        todos.where((t) => t.isNoTimeTodo && !t.isCompleted).toList();
    final completed = todos.where((t) => t.isCompleted).toList();

    final grouped = <String, List<Event>>{};
    for (final t in pendingTimed) {
      if (!t.hasDate) continue;
      grouped.putIfAbsent(t.date, () => []).add(t);
    }
    final dates = grouped.keys.toList()..sort();
    final longTermExpanded = ref.watch(longTermTasksExpandedProvider);

    Widget wrapSwipe(Event todo, Widget child) {
      return SwipeEventActions(
        event: todo,
        enabled: !batch.active,
        onEdit: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => EventFormPage(
              eventId: todo.id,
              editingOccurrence: todo,
            ),
          ),
        ),
        onDuplicate: () =>
            ref.read(eventActionsProvider).duplicate(todo.id),
        onDelete: () async {
          final scope = await pickDeleteScope(context, event: todo);
          if (scope == null) return;
          try {
            await ref.read(eventActionsProvider).deleteWithScope(todo, scope);
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(AppLocalizations.of(context).saveFailedRetry),
              ),
            );
          }
        },
        child: child,
      );
    }

    final l10n = AppLocalizations.of(context);

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        ref.read(swipeOpenProvider.notifier).state = null;
        return false;
      },
      child: ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
      children: [
        if (pendingNoTime.isNotEmpty) ...[
          InkWell(
            onTap: () {
              ref
                  .read(longTermTasksExpandedProvider.notifier)
                  .setExpanded(!longTermExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Row(
                children: [
                  Icon(
                    longTermExpanded ? Icons.expand_more : Icons.chevron_right,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l10n.longTermTasks(pendingNoTime.length),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (longTermExpanded)
            ...pendingNoTime.map(
              (todo) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: wrapSwipe(
                  todo,
                  CompactTodoCard(
                    event: todo,
                    completed: false,
                    batchActive: batch.active,
                    selected: batch.selectedIds.contains(todo.id),
                    onTap: () => onTap(todo),
                    onLongPress: () => onEnterBatch(todo.id),
                    onToggle: (v) => onToggleComplete(todo, v),
                  ),
                ),
              ),
            ),
        ],
        ...dates.map((dateKey) {
          final items = grouped[dateKey]!
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  formatTodoSectionDate(dateKey, l10n),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ...items.map(
                (todo) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: wrapSwipe(
                    todo,
                    CompactTodoCard(
                      event: todo,
                      completed: false,
                      batchActive: batch.active,
                      selected: batch.selectedIds.contains(todo.id),
                      onTap: () => onTap(todo),
                      onLongPress: () => onEnterBatch(todo.id),
                      onToggle: (v) => onToggleComplete(todo, v),
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
        if (completed.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: InkWell(
              onTap: () {
                ref.read(todoCompletedExpandedProvider.notifier).state =
                    !ref.read(todoCompletedExpandedProvider);
              },
              child: Row(
                children: [
                  Icon(
                    ref.watch(todoCompletedExpandedProvider)
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    l10n.completed(completed.length),
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
          if (ref.watch(todoCompletedExpandedProvider))
            ...completed.map(
              (todo) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                child: wrapSwipe(
                  todo,
                  CompactTodoCard(
                    event: todo,
                    completed: true,
                    batchActive: batch.active,
                    selected: batch.selectedIds.contains(todo.id),
                    onTap: () => onTap(todo),
                    onLongPress: () => onEnterBatch(todo.id),
                    onToggle: (v) => onToggleComplete(todo, v),
                  ),
                ),
              ),
            ),
        ],
      ],
    ),
    );
  }
}
