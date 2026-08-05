import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/batch_providers.dart';
import '../../core/widgets/batch_toolbar.dart';
import '../../core/widgets/compact_todo_card.dart';
import '../../core/widgets/event_detail_sheet.dart';
import '../../models/enums.dart';
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
                  onEnterBatch: (id) =>
                      ref.read(todoBatchProvider.notifier).enterWith(id),
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
                  onToggleComplete: (id, v) =>
                      ref.read(eventActionsProvider).toggleTodo(id, v),
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: batch.active
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      const EventFormPage(forceTaskType: TaskType.todo),
                ),
              ),
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
  final void Function(int id, bool completed) onToggleComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (todos.isEmpty) {
      return const Center(child: Text('No todos yet'));
    }

    final pendingTimed = todos
        .where((t) => !t.isNoTimeTodo && !t.isCompleted)
        .toList();
    final pendingNoTime =
        todos.where((t) => t.isNoTimeTodo && !t.isCompleted).toList();
    final completed = todos.where((t) => t.isCompleted).toList();

    final grouped = <String, List<Event>>{};
    for (final t in pendingTimed) {
      if (!t.hasDate) continue;
      grouped.putIfAbsent(t.date, () => []).add(t);
    }
    final dates = grouped.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
      children: [
        ...dates.map((dateKey) {
          final items = grouped[dateKey]!
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  formatTodoSectionDate(dateKey),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              ...items.map(
                (todo) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
                  child: CompactTodoCard(
                    event: todo,
                    completed: false,
                    batchActive: batch.active,
                    selected: batch.selectedIds.contains(todo.id),
                    onTap: () => onTap(todo),
                    onLongPress: () => onEnterBatch(todo.id),
                    onToggle: (v) => onToggleComplete(todo.id, v),
                  ),
                ),
              ),
            ],
          );
        }),
        if (pendingNoTime.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'No-time tasks',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ...pendingNoTime.map(
            (todo) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
              child: CompactTodoCard(
                event: todo,
                completed: false,
                batchActive: batch.active,
                selected: batch.selectedIds.contains(todo.id),
                onTap: () => onTap(todo),
                onLongPress: () => onEnterBatch(todo.id),
                onToggle: (v) => onToggleComplete(todo.id, v),
              ),
            ),
          ),
        ],
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
                    'Completed (${completed.length})',
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
                child: CompactTodoCard(
                  event: todo,
                  completed: true,
                  batchActive: batch.active,
                  selected: batch.selectedIds.contains(todo.id),
                  onTap: () => onTap(todo),
                  onLongPress: () => onEnterBatch(todo.id),
                  onToggle: (v) => onToggleComplete(todo.id, v),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
