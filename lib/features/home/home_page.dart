import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/batch_providers.dart';
import '../../../core/providers/focus_providers.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/widgets/batch_toolbar.dart';
import '../../../core/widgets/compact_todo_card.dart';
import '../../../core/widgets/date_header.dart';
import '../../../core/widgets/day_info_bar.dart';
import '../../../core/widgets/event_detail_sheet.dart';
import '../../../core/widgets/swipe_event_actions.dart';
import '../../../l10n/app_localizations.dart';
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
    final batch = ref.watch(homeBatchProvider);
    final dateKey = DateTimeFormats.formatDate(selected);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BatchToolbar(
              batchProvider: homeBatchProvider,
              events: eventsAsync.valueOrNull ?? const [],
              onEditSingle: batch.selectedIds.length == 1
                  ? () {
                      final id = batch.selectedIds.first;
                      ref.read(homeBatchProvider.notifier).cancel();
                      _openForm(eventId: id);
                    }
                  : null,
            ),
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: batch.active
                    ? null
                    : (details) {
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
                    final todos = events
                        .where((e) => e.showsOnHomeDate(dateKey))
                        .toList()
                      ..sort((a, b) => a.startTime.compareTo(b.startTime));
                    final pending =
                        todos.where((e) => !e.isCompleted).toList();
                    final done =
                        todos.where((e) => e.isCompleted).toList();

                    final l10n = AppLocalizations.of(context);

                    return CustomScrollView(
                      slivers: [
                        SliverToBoxAdapter(
                          child: DateHeader(
                            selected: selected,
                            onBackToToday: () {
                              ref
                                  .read(homeSelectedDateProvider.notifier)
                                  .state = DateTimeFormats.dateOnly(
                                DateTime.now(),
                              );
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
                            emptyMessage: l10n.noTimelineItems,
                            batchActive: batch.active,
                            selectedIds: batch.selectedIds,
                            onEventTap: (e) => _onTimelineTap(e),
                            onEventLongPress: (e) => _enterBatch(e.id),
                            onToggleComplete: batch.active
                                ? null
                                : (e) => _toggleTimelineComplete(e),
                            onSwipeEdit: (e) => _openForm(eventId: e.id),
                            onSwipeDuplicate: (e) => ref
                                .read(eventActionsProvider)
                                .duplicate(e.id),
                            onSwipeDelete: (e) => _deleteEvent(e),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 20)),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              l10n.todaysTodo,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final todo = pending[index];
                              return Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(20, 6, 20, 0),
                                child: SwipeEventActions(
                                  event: todo,
                                  enabled: !batch.active,
                                  onEdit: () => _openForm(eventId: todo.id),
                                  onDuplicate: () => ref
                                      .read(eventActionsProvider)
                                      .duplicate(todo.id),
                                  onDelete: () => _deleteEvent(todo),
                                  child: CompactTodoCard(
                                    key: ValueKey('pending-${todo.id}'),
                                    event: todo,
                                    completed: false,
                                    batchActive: batch.active,
                                    selected:
                                        batch.selectedIds.contains(todo.id),
                                    onTap: () => _onTodoTap(todo),
                                    onLongPress: () => _enterBatch(todo.id),
                                    onToggle: (v) => ref
                                        .read(eventActionsProvider)
                                        .toggleTodo(todo.id, v),
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
                              padding:
                                  const EdgeInsets.fromLTRB(20, 12, 20, 0),
                              child: InkWell(
                                onTap: () {
                                  ref
                                      .read(completedSectionExpandedProvider
                                          .notifier)
                                      .state = !ref.read(
                                    completedSectionExpandedProvider,
                                  );
                                },
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: Row(
                                    children: [
                                      Icon(
                                        ref.watch(
                                                completedSectionExpandedProvider)
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.completed(done.length),
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                            ),
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
                                  final todo = done[index];
                                  return Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        20, 6, 20, 0),
                                    child: SwipeEventActions(
                                      event: todo,
                                      enabled: !batch.active,
                                      onEdit: () => _openForm(eventId: todo.id),
                                      onDuplicate: () => ref
                                          .read(eventActionsProvider)
                                          .duplicate(todo.id),
                                      onDelete: () => _deleteEvent(todo),
                                      child: CompactTodoCard(
                                        key: ValueKey('done-${todo.id}'),
                                        event: todo,
                                        completed: true,
                                        batchActive: batch.active,
                                        selected: batch.selectedIds
                                            .contains(todo.id),
                                        onTap: () => _onTodoTap(todo),
                                        onLongPress: () =>
                                            _enterBatch(todo.id),
                                        onToggle: (v) => ref
                                            .read(eventActionsProvider)
                                            .toggleTodo(todo.id, v),
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
                  loading: () => const Center(
                    child: CircularProgressIndicator.adaptive(),
                  ),
                  error: (e, _) => Center(
                    child: Text(
                      AppLocalizations.of(context).loadFailed('$e'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: batch.active
          ? null
          : FloatingActionButton(
              onPressed: () => _openForm(initialDate: selected),
              child: const Icon(Icons.add_rounded),
            ),
    );
  }

  void _enterBatch(int id) {
    ref.read(homeBatchProvider.notifier).enterWith(id);
  }

  void _onTimelineTap(Event event) {
    final batch = ref.read(homeBatchProvider);
    if (batch.active) {
      ref.read(homeBatchProvider.notifier).toggle(event.id);
      return;
    }
    showEventDetailSheet(context: context, ref: ref, event: event);
  }

  void _onTodoTap(Event todo) {
    final batch = ref.read(homeBatchProvider);
    if (batch.active) {
      ref.read(homeBatchProvider.notifier).toggle(todo.id);
      return;
    }
    showEventDetailSheet(context: context, ref: ref, event: todo);
  }

  Future<void> _toggleTimelineComplete(Event event) async {
    await ref
        .read(eventActionsProvider)
        .toggleTimeline(event.id, !event.isCompleted);
  }

  Future<void> _deleteEvent(Event event) async {
    if (!await confirmDeleteEvent(context)) return;
    await ref.read(eventActionsProvider).delete(event.id);
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
