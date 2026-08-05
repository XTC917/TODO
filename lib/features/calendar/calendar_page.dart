import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/widgets/event_card.dart';
import '../schedule/event_form_page.dart';

class CalendarPage extends ConsumerWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(calendarSelectedDateProvider);
    final focused = ref.watch(calendarFocusedMonthProvider);
    final markedAsync = ref.watch(eventDatesInMonthProvider(focused));
    final eventsAsync = ref.watch(eventsForDateProvider(selected));
    final marked = markedAsync.valueOrNull ?? <String>{};

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2040, 12, 31),
                focusedDay: focused,
                selectedDayPredicate: (day) =>
                    DateTimeFormats.isSameDay(day, selected),
                calendarFormat: CalendarFormat.month,
                startingDayOfWeek: StartingDayOfWeek.monday,
                headerStyle: const HeaderStyle(
                  titleCentered: true,
                  formatButtonVisible: false,
                ),
                calendarStyle: const CalendarStyle(
                  outsideDaysVisible: false,
                  markerSize: 5,
                  markersAnchor: 1.1,
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
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  DateTimeFormats.formatDate(selected),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
            Expanded(
              child: eventsAsync.when(
                data: (events) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return EventCard(
                      event: event,
                      showCheckbox: event.isTodo,
                      completed: event.isCompleted,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventFormPage(eventId: event.id),
                        ),
                      ),
                      onToggle: event.isTodo
                          ? (v) => ref
                              .read(eventActionsProvider)
                              .toggleTodo(event.id, v)
                          : null,
                    );
                  },
                ),
                loading: () =>
                    const Center(child: CircularProgressIndicator.adaptive()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
