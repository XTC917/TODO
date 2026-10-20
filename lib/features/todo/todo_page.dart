import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/batch_providers.dart';
import '../../core/providers/focus_providers.dart';
import '../../core/providers/todo_view_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/utils/todo_date_filter.dart';
import '../../core/widgets/batch_toolbar.dart';
import '../../core/widgets/compact_todo_card.dart';
import '../../core/widgets/event_detail_sheet.dart';
import '../../core/widgets/repeat_scope_dialog.dart';
import '../../core/widgets/swipe_event_actions.dart';
import '../../core/widgets/todo_filter_bar.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../schedule/event_form_page.dart';
import '../search/task_search_page.dart';

class TodoPage extends ConsumerStatefulWidget {
  const TodoPage({super.key});

  @override
  ConsumerState<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends ConsumerState<TodoPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshToday();
  }

  /// Re-resolves "today" so dynamic presets follow the local date across
  /// midnight without persisting absolute dates.
  void _refreshToday() {
    if (!mounted) return;
    final today = DateTimeFormats.dateOnly(DateTime.now());
    if (ref.read(todoTodayProvider) != today) {
      // The visible window may change, so drop any active batch selection to
      // avoid acting on tasks that are no longer visible.
      ref.read(todoBatchProvider.notifier).cancel();
      ref.read(todoTodayProvider.notifier).state = today;
    }
  }

  Future<void> _handlePreset(TodoRangePreset preset) async {
    if (preset == TodoRangePreset.custom) {
      await _pickCustomRange();
      return;
    }
    if (ref.read(todoViewStateProvider).preset == preset) return;
    ref.read(todoBatchProvider.notifier).cancel();
    await ref.read(todoViewStateProvider.notifier).selectPreset(preset);
  }

  Future<void> _pickCustomRange() async {
    final view = ref.read(todoViewStateProvider);
    final l10n = AppLocalizations.of(context);
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040, 12, 31),
      initialDateRange: _initialCustomRange(view),
      helpText: l10n.todoSelectDateRange,
    );
    if (picked == null || !mounted) return;

    ref.read(todoBatchProvider.notifier).cancel();
    await ref.read(todoViewStateProvider.notifier).setCustomRange(
          start: DateTimeFormats.formatDate(picked.start),
          end: DateTimeFormats.formatDate(picked.end),
        );
  }

  DateTimeRange _initialCustomRange(TodoViewState view) {
    final startKey = normalizeDateKey(view.customStart);
    final endKey = normalizeDateKey(view.customEnd);
    if (startKey != null && endKey != null) {
      final start = _clampPickerDate(DateTimeFormats.parseDate(startKey));
      final end = _clampPickerDate(DateTimeFormats.parseDate(endKey));
      return start.isAfter(end)
          ? DateTimeRange(start: end, end: start)
          : DateTimeRange(start: start, end: end);
    }
    final today = ref.read(todoTodayProvider);
    return DateTimeRange(
      start: today,
      end: today.add(const Duration(days: 6)),
    );
  }

  DateTime _clampPickerDate(DateTime date) {
    final first = DateTime(2020);
    final last = DateTime(2040, 12, 31);
    final day = DateTimeFormats.dateOnly(date);
    if (day.isBefore(first)) return first;
    if (day.isAfter(last)) return last;
    return day;
  }

  Future<void> _toggleSort() async {
    ref.read(todoBatchProvider.notifier).cancel();
    await ref.read(todoViewStateProvider.notifier).setDescending(
          !ref.read(todoViewStateProvider).descending,
        );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(shellTabProvider, (previous, next) {
      if (next == 1) _refreshToday();
    });

    final sectionsAsync = ref.watch(todoSectionsProvider);
    final view = ref.watch(todoViewStateProvider);
    final batch = ref.watch(todoBatchProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: batch.active
          ? null
          : AppBar(
              toolbarHeight: 44,
              titleSpacing: 20,
              title: Text(
                l10n.navTodo,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              actions: [
                Tooltip(
                  message: view.descending
                      ? l10n.todoSortDescending
                      : l10n.todoSortAscending,
                  child: TextButton.icon(
                    onPressed: _toggleSort,
                    iconAlignment: IconAlignment.end,
                    icon: Icon(
                      // Ascending flows downward, descending flows upward.
                      view.descending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded,
                      size: 16,
                    ),
                    label: Text(
                      view.descending
                          ? l10n.todoSortDescLabel
                          : l10n.todoSortAscLabel,
                    ),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(0, 36),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      textStyle: Theme.of(context).textTheme.labelLarge,
                      foregroundColor: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: TaskSearchButton(),
                ),
              ],
            ),
      body: SafeArea(
        child: Column(
          children: [
            BatchToolbar(
              batchProvider: todoBatchProvider,
              events: sectionsAsync.valueOrNull?.allVisibleTodos ?? const [],
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
            if (!batch.active)
              TodoFilterBar(
                state: view,
                onPresetSelected: _handlePreset,
                onCustomTap: _pickCustomRange,
              ),
            Expanded(
              child: sectionsAsync.when(
                data: (sections) => _TodoListBody(
                  sections: sections,
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
                  child: Text(l10n.errorGeneric('$e')),
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
    required this.sections,
    required this.batch,
    required this.onEnterBatch,
    required this.onTap,
    required this.onToggleComplete,
  });

  final TodoSections sections;
  final BatchSelection batch;
  final ValueChanged<int> onEnterBatch;
  final ValueChanged<Event> onTap;
  final void Function(Event todo, bool completed) onToggleComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    if (sections.isEmpty) {
      final showRangeEmpty = sections.isFiltered && sections.hasStoredTodos;
      return Center(
        child: Text(showRangeEmpty ? l10n.todoEmptyInRange : l10n.noTodosYet),
      );
    }

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

    return NotificationListener<ScrollNotification>(
      onNotification: (_) {
        ref.read(swipeOpenProvider.notifier).state = null;
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 100),
        children: [
          if (sections.longTermTodos.isNotEmpty) ...[
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
                      longTermExpanded
                          ? Icons.expand_more
                          : Icons.chevron_right,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.longTermTasks(sections.longTermTodos.length),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (longTermExpanded)
              ...sections.longTermTodos.map(
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
          ...sections.dateSections.map((section) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Text(
                    formatTodoSectionDate(section.dateKey, l10n),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ...section.items.map(
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
          if (sections.completedTodos.isNotEmpty) ...[
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
                      l10n.completed(sections.completedTodos.length),
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
            if (ref.watch(todoCompletedExpandedProvider))
              ...sections.completedTodos.map(
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
