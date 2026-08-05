import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers/app_providers.dart';
import '../../core/providers/batch_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/widgets/batch_toolbar.dart';
import '../../core/widgets/compact_todo_card.dart';
import '../../core/widgets/event_detail_sheet.dart';
import '../../core/widgets/swipe_event_actions.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../home/widgets/timeline_view.dart';
import '../schedule/event_form_page.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(themeModeProvider);
    ref.watch(accentColorProvider);

    final selected = ref.watch(calendarSelectedDateProvider);
    final focused = ref.watch(calendarFocusedMonthProvider);
    final markedAsync = ref.watch(eventDatesInMonthProvider(focused));
    final eventsAsync = ref.watch(eventsForDateProvider(selected));
    final marked = markedAsync.valueOrNull ?? <String>{};
    final batch = ref.watch(calendarBatchProvider);
    final dateKey = DateTimeFormats.formatDate(selected);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final calendarKey = ValueKey('${theme.brightness}-${scheme.primary}');
    final l10n = AppLocalizations.of(context);
    final landscape = MediaQuery.sizeOf(context).width >
        MediaQuery.sizeOf(context).height;

    Widget buildCalendar({required bool compact}) {
      return Padding(
        padding: EdgeInsets.fromLTRB(compact ? 8 : 12, 4, compact ? 8 : 12, 0),
        child: TableCalendar(
          key: calendarKey,
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2040, 12, 31),
          focusedDay: focused,
          selectedDayPredicate: (day) =>
              DateTimeFormats.isSameDay(day, selected),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.monday,
          rowHeight: compact ? 28 : 38,
          daysOfWeekHeight: compact ? 20 : 26,
          headerStyle: HeaderStyle(
            titleCentered: true,
            formatButtonVisible: false,
            titleTextStyle: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                  fontSize: compact ? 12 : null,
                ) ??
                TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                  fontSize: compact ? 12 : 14,
                ),
            leftChevronIcon: Icon(
              Icons.chevron_left,
              color: scheme.onSurface,
              size: compact ? 20 : 24,
            ),
            rightChevronIcon: Icon(
              Icons.chevron_right,
              color: scheme.onSurface,
              size: compact ? 20 : 24,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: EdgeInsets.all(compact ? 1 : 2),
            markerSize: compact ? 3 : 4,
            markersAnchor: 1.05,
            defaultTextStyle: TextStyle(
              color: scheme.onSurface,
              fontSize: compact ? 11 : 13,
            ),
            weekendTextStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.65),
              fontSize: compact ? 11 : 13,
            ),
            outsideTextStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.35),
              fontSize: compact ? 11 : 13,
            ),
            todayDecoration: BoxDecoration(
              color: scheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: compact ? 11 : 13,
            ),
            selectedDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            selectedTextStyle: TextStyle(
              color: scheme.onPrimary,
              fontWeight: FontWeight.w700,
              fontSize: compact ? 11 : 13,
            ),
            markerDecoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: compact ? 10 : 11,
            ),
            weekendStyle: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.55),
              fontSize: compact ? 10 : 11,
            ),
          ),
          eventLoader: (day) {
            final key = DateTimeFormats.formatDate(day);
            return marked.contains(key) ? const [1] : const [];
          },
          onDaySelected: (day, focusedDay) {
            ref.read(calendarSelectedDateProvider.notifier).state =
                DateTimeFormats.dateOnly(day);
            ref.read(calendarFocusedMonthProvider.notifier).state =
                DateTime(focusedDay.year, focusedDay.month);
            ref.read(homeSelectedDateProvider.notifier).state =
                DateTimeFormats.dateOnly(day);
          },
          onPageChanged: (focusedDay) {
            ref.read(calendarFocusedMonthProvider.notifier).state =
                DateTime(focusedDay.year, focusedDay.month);
          },
        ),
      );
    }

    Widget dateHeader({EdgeInsetsGeometry? padding}) {
      return Padding(
        padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            DateTimeFormats.formatSectionDate(selected, l10n),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    Widget buildEventsPanel(List<Event> events) {
      final timeline = TimelineView(
        events: events,
        compact: true,
        batchActive: batch.active,
        selectedIds: batch.selectedIds,
        onEventTap: (e) => _onItemTap(context, ref, e, batch),
        onEventLongPress: (e) =>
            ref.read(calendarBatchProvider.notifier).enterWith(e.id),
        onToggleComplete: batch.active
            ? null
            : (e) => ref
                .read(eventActionsProvider)
                .toggleTimeline(e.id, !e.isCompleted),
        onSwipeEdit: (e) => _editEvent(context, e),
        onSwipeDuplicate: (e) =>
            ref.read(eventActionsProvider).duplicate(e.id),
        onSwipeDelete: (e) => _deleteEvent(context, ref, e),
      );
      final todoPanel = _CalendarTodoPanel(
        events: events,
        dateKey: dateKey,
        batch: batch,
        onItemTap: (e) => _onItemTap(context, ref, e, batch),
        onEnterBatch: (id) =>
            ref.read(calendarBatchProvider.notifier).enterWith(id),
        onToggleTodo: (id, v) =>
            ref.read(eventActionsProvider).toggleTodo(id, v),
        onSwipeEdit: (e) => _editEvent(context, e),
        onSwipeDuplicate: (e) =>
            ref.read(eventActionsProvider).duplicate(e.id),
        onSwipeDelete: (e) => _deleteEvent(context, ref, e),
      );

      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  right: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [timeline],
              ),
            ),
          ),
          Expanded(child: todoPanel),
        ],
      );
    }

    final batchToolbar = BatchToolbar(
      batchProvider: calendarBatchProvider,
      events: eventsAsync.valueOrNull ?? const [],
      onEditSingle: batch.selectedIds.length == 1
          ? () {
              final id = batch.selectedIds.first;
              ref.read(calendarBatchProvider.notifier).cancel();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => EventFormPage(eventId: id),
                ),
              );
            }
          : null,
    );

    final eventsBody = eventsAsync.when(
      data: (events) => buildEventsPanel(events),
      loading: () =>
          const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => Center(child: Text(l10n.errorGeneric('$e'))),
    );

    if (landscape) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              batchToolbar,
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: SingleChildScrollView(
                        child: buildCalendar(compact: true),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      color: theme.dividerColor.withValues(alpha: 0.5),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          dateHeader(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                          ),
                          Expanded(child: eventsBody),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            batchToolbar,
            buildCalendar(compact: false),
            Divider(
              height: 1,
              color: theme.dividerColor.withValues(alpha: 0.5),
            ),
            dateHeader(),
            Expanded(child: eventsBody),
          ],
        ),
      ),
    );
  }

  void _onItemTap(
    BuildContext context,
    WidgetRef ref,
    Event event,
    BatchSelection batch,
  ) {
    if (batch.active) {
      ref.read(calendarBatchProvider.notifier).toggle(event.id);
      return;
    }
    showEventDetailSheet(context: context, ref: ref, event: event);
  }

  void _editEvent(BuildContext context, Event event) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventFormPage(eventId: event.id)),
    );
  }

  Future<void> _deleteEvent(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    if (!await confirmDeleteEvent(context)) return;
    await ref.read(eventActionsProvider).delete(event.id);
  }
}

class _CalendarTodoPanel extends StatelessWidget {
  const _CalendarTodoPanel({
    required this.events,
    required this.dateKey,
    required this.batch,
    required this.onItemTap,
    required this.onEnterBatch,
    required this.onToggleTodo,
    required this.onSwipeEdit,
    required this.onSwipeDuplicate,
    required this.onSwipeDelete,
  });

  final List<Event> events;
  final String dateKey;
  final BatchSelection batch;
  final ValueChanged<Event> onItemTap;
  final ValueChanged<int> onEnterBatch;
  final void Function(int id, bool completed) onToggleTodo;
  final ValueChanged<Event> onSwipeEdit;
  final ValueChanged<Event> onSwipeDuplicate;
  final Future<void> Function(Event event) onSwipeDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final todos = events.where((e) => e.showsOnHomeDate(dateKey)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final pending = todos.where((e) => !e.isCompleted).toList();
    final done = todos.where((e) => e.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 12),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            l10n.todoSection,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (pending.isEmpty && done.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                l10n.noTodos,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.45),
                    ),
              ),
            ),
          ),
        ...pending.map(
          (todo) => SwipeEventActions(
            event: todo,
            enabled: !batch.active,
            onEdit: () => onSwipeEdit(todo),
            onDuplicate: () => onSwipeDuplicate(todo),
            onDelete: () => onSwipeDelete(todo),
            child: CompactTodoCard(
              event: todo,
              completed: false,
              batchActive: batch.active,
              selected: batch.selectedIds.contains(todo.id),
              onTap: () => onItemTap(todo),
              onLongPress: () => onEnterBatch(todo.id),
              onToggle: (v) => onToggleTodo(todo.id, v),
            ),
          ),
        ),
        if (done.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
            child: Text(
              l10n.completed(done.length),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          ...done.map(
            (todo) => SwipeEventActions(
              event: todo,
              enabled: !batch.active,
              onEdit: () => onSwipeEdit(todo),
              onDuplicate: () => onSwipeDuplicate(todo),
              onDelete: () => onSwipeDelete(todo),
              child: CompactTodoCard(
                event: todo,
                completed: true,
                batchActive: batch.active,
                selected: batch.selectedIds.contains(todo.id),
                onTap: () => onItemTap(todo),
                onLongPress: () => onEnterBatch(todo.id),
                onToggle: (v) => onToggleTodo(todo.id, v),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
