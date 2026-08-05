import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/focus_providers.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/compact_todo_card.dart';
import '../../../core/widgets/date_header.dart';
import '../../../core/widgets/day_info_bar.dart';
import '../../../models/event.dart';
import '../schedule/event_form_page.dart';
import 'widgets/timeline_view.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(homeSelectedDateProvider);
    final eventsAsync = ref.watch(eventsForDateProvider(selected));
    final summaryAsync = ref.watch(daySummaryProvider(selected));

    return Scaffold(
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            final velocity = details.primaryVelocity ?? 0;
            if (velocity < -200) {
              ref.read(homeSelectedDateProvider.notifier).state =
                  selected.add(const Duration(days: 1));
            } else if (velocity > 200) {
              ref.read(homeSelectedDateProvider.notifier).state =
                  selected.subtract(const Duration(days: 1));
            }
          },
          child: eventsAsync.when(
            data: (events) {
              final todos = events.where((e) => e.showsInTodoList).toList()
                ..sort((a, b) {
                  if (a.isCompleted != b.isCompleted) {
                    return a.isCompleted ? 1 : -1;
                  }
                  return a.startTime.compareTo(b.startTime);
                });
              final pending =
                  todos.where((e) => !e.isCompleted).toList(growable: false);
              final done =
                  todos.where((e) => e.isCompleted).toList(growable: false);

              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: DateHeader(
                      selected: selected,
                      onBackToToday: () {
                        ref.read(homeSelectedDateProvider.notifier).state =
                            DateTimeFormats.dateOnly(DateTime.now());
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: summaryAsync.when(
                      data: (s) => DayInfoBar(summary: s),
                      loading: () => const SizedBox(height: 40),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: TimelineView(
                      events: events,
                      onEventTap: (e) => _openForm(eventId: e.id),
                      onEventLongPress: (e) => _showMenu(e),
                      onToggleComplete: (e) => _toggleTimeline(e),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        "Today's Todo",
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final todo = pending.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                          child: _AnimatedTodoCard(
                            key: ValueKey('pending-${todo.id}'),
                            event: todo,
                            completed: false,
                            onTap: () => _openForm(eventId: todo.id),
                            onToggle: (v) => _toggleTodo(todo, v),
                            onLongPress: () => _showMenu(todo),
                          ),
                        );
                      },
                      childCount: pending.length,
                    ),
                  ),
                  if (done.isNotEmpty) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: InkWell(
                          onTap: () {
                            ref
                                .read(completedSectionExpandedProvider.notifier)
                                .state =
                                !ref.read(completedSectionExpandedProvider);
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                Icon(
                                  ref.watch(completedSectionExpandedProvider)
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Completed (${done.length})',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (ref.watch(completedSectionExpandedProvider))
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final todo = done.elementAt(index);
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
                              child: _AnimatedTodoCard(
                                key: ValueKey('done-${todo.id}'),
                                event: todo,
                                completed: true,
                                onTap: () => _openForm(eventId: todo.id),
                                onToggle: (v) => _toggleTodo(todo, v),
                                onLongPress: () => _showMenu(todo),
                              ),
                            );
                          },
                          childCount: done.length,
                        ),
                      ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ],
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator.adaptive()),
            error: (e, _) => Center(child: Text('Load failed: $e')),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(initialDate: selected),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  void _showMenu(Event event) {
    showEventContextMenu(
      context: context,
      ref: ref,
      event: event,
      onEdit: () => _openForm(eventId: event.id),
      onDeleted: () {},
    );
  }

  Future<void> _toggleTimeline(Event event) async {
    final done = event.isTimelineDone(DateTime.now());
    await ref
        .read(eventActionsProvider)
        .toggleTimeline(event.id, !done);
  }

  Future<void> _toggleTodo(Event todo, bool completed) async {
    await ref.read(eventActionsProvider).toggleTodo(todo.id, completed);
  }

  Future<void> _openForm({int? eventId, DateTime? initialDate}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventFormPage(
          eventId: eventId,
          initialDate: initialDate,
        ),
      ),
    );
  }
}

class _AnimatedTodoCard extends StatefulWidget {
  const _AnimatedTodoCard({
    super.key,
    required this.event,
    required this.completed,
    required this.onTap,
    required this.onToggle,
    this.onLongPress,
  });

  final Event event;
  final bool completed;
  final VoidCallback onTap;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onLongPress;

  @override
  State<_AnimatedTodoCard> createState() => _AnimatedTodoCardState();
}

class _AnimatedTodoCardState extends State<_AnimatedTodoCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: CompactTodoCard(
        event: widget.event,
        completed: widget.completed,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        onToggle: (v) {
          _controller.forward().then((_) => _controller.reverse());
          widget.onToggle(v);
        },
      ),
    );
  }
}
