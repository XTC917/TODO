import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/focus_providers.dart';
import '../../../core/widgets/date_header.dart';
import '../../../core/widgets/event_card.dart';
import '../../../models/event.dart';
import '../schedule/event_form_page.dart';
import 'widgets/timeline_view.dart';
import '../../../core/widgets/summary_card.dart';

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
        child: eventsAsync.when(
          data: (events) {
            final now = DateTime.now();
            final schedules =
                events.where((e) => e.isSchedule).toList(growable: false);
            final todos = events.where((e) => e.isTodo).toList(growable: false)
              ..sort((a, b) {
                final ac = a.isEffectivelyCompleted(now);
                final bc = b.isEffectivelyCompleted(now);
                if (ac != bc) return ac ? 1 : -1;
                return a.startTime.compareTo(b.startTime);
              });
            final pending = todos.where((e) => !e.isEffectivelyCompleted(now));
            final done = todos.where((e) => e.isEffectivelyCompleted(now));

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SwipeableDateHeader(
                    selected: selected,
                    onDateChanged: (d) =>
                        ref.read(homeSelectedDateProvider.notifier).state = d,
                  ),
                ),
                SliverToBoxAdapter(
                  child: summaryAsync.when(
                    data: (s) => SummaryCard(summary: s),
                    loading: () => const SizedBox(height: 120),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: TimelineView(
                    events: [...schedules, ...todos],
                    onEventTap: (e) => _openForm(eventId: e.id),
                    onEventLongPress: (e) => showEventContextMenu(
                      context: context,
                      ref: ref,
                      event: e,
                      onEdit: () => _openForm(eventId: e.id),
                      onDeleted: () {},
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
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
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                        child: _AnimatedTodoCard(
                          key: ValueKey('pending-${todo.id}'),
                          event: todo,
                          completed: false,
                          onTap: () => _openForm(eventId: todo.id),
                          onToggle: (v) => _toggleTodo(todo, v),
                          onLongPress: () => showEventContextMenu(
                            context: context,
                            ref: ref,
                            event: todo,
                            onEdit: () => _openForm(eventId: todo.id),
                            onDeleted: () {},
                          ),
                        ),
                      );
                    },
                    childCount: pending.length,
                  ),
                ),
                if (done.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: InkWell(
                        onTap: () {
                          ref
                              .read(completedSectionExpandedProvider.notifier)
                              .state = !ref.read(completedSectionExpandedProvider);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                ref.watch(completedSectionExpandedProvider)
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                size: 20,
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
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                            child: _AnimatedTodoCard(
                              key: ValueKey('done-${todo.id}'),
                              event: todo,
                              completed: true,
                              onTap: () => _openForm(eventId: todo.id),
                              onToggle: (v) => _toggleTodo(todo, v),
                              onLongPress: () => showEventContextMenu(
                                context: context,
                                ref: ref,
                                event: todo,
                                onEdit: () => _openForm(eventId: todo.id),
                                onDeleted: () {},
                              ),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(initialDate: selected),
        child: const Icon(Icons.add_rounded),
      ),
    );
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
      child: EventCard(
        event: widget.event,
        showCheckbox: true,
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
