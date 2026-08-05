import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/focus_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/widgets/compact_todo_card.dart';
import '../../core/widgets/date_header.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../schedule/event_form_page.dart';

class TodoPage extends ConsumerWidget {
  const TodoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(allTodosProvider);

    return Scaffold(
      body: SafeArea(
        child: todosAsync.when(
          data: (todos) {
            final grouped = <String, List<Event>>{};
            for (final t in todos) {
              grouped.putIfAbsent(t.date, () => []).add(t);
            }
            final dates = grouped.keys.toList()..sort();

            if (dates.isEmpty) {
              return const Center(child: Text('No todos yet'));
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(0, 16, 0, 100),
              itemCount: dates.length,
              itemBuilder: (context, index) {
                final dateKey = dates[index];
                final items = grouped[dateKey]!
                  ..sort((a, b) {
                    if (a.isCompleted != b.isCompleted) {
                      return a.isCompleted ? 1 : -1;
                    }
                    return a.startTime.compareTo(b.startTime);
                  });
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                      child: Text(
                        DateTimeFormats.formatMonthDay(
                          DateTime.parse(dateKey),
                        ),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    ...items.map(
                      (todo) => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        child: CompactTodoCard(
                          event: todo,
                          completed: todo.isCompleted,
                          onTap: () {
                            ref.read(homeSelectedDateProvider.notifier).state =
                                DateTimeFormats.parseDate(todo.date);
                            ref.read(shellTabProvider.notifier).state = 0;
                          },
                          onLongPress: () => showEventContextMenu(
                            context: context,
                            ref: ref,
                            event: todo,
                            onEdit: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventFormPage(eventId: todo.id),
                              ),
                            ),
                            onDeleted: () {},
                          ),
                          onToggle: (v) => ref
                              .read(eventActionsProvider)
                              .toggleTodo(todo.id, v),
                        ),
                      ),
                    ),
                    const Divider(height: 24),
                  ],
                );
              },
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator.adaptive()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const EventFormPage(forceTaskType: TaskType.todo),
          ),
        ),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
