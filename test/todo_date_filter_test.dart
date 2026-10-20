import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/todo_date_filter.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

const _today = '2026-10-20';

Event _todo(
  int id, {
  String date = '',
  String startTime = '09:00',
  bool completed = false,
  TodoTimeMode mode = TodoTimeMode.timeBlock,
  String? title,
}) {
  return Event(
    id: id,
    title: title ?? 'todo-$id',
    date: date,
    startTime: startTime,
    endTime: startTime,
    color: '#000000',
    taskType: TaskType.todo,
    todoTimeMode: mode,
    isCompleted: completed,
    repeatType: RepeatType.oneTime,
    focusedSeconds: 0,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

Event _longTerm(int id, {bool completed = false}) => _todo(
      id,
      mode: TodoTimeMode.noTime,
      completed: completed,
    );

DateTime _date(String key) => DateTime.parse(key);

void main() {
  group('resolveTodoDateWindow', () {
    test('all preset has no window', () {
      expect(
        resolveTodoDateWindow(const TodoViewState(), _date(_today)),
        isNull,
      );
    });

    test('today covers exactly today', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(preset: TodoRangePreset.today),
        _date(_today),
      );
      expect(window, const TodoDateWindow(startKey: _today, endKey: _today));
    });

    test('next 7 days includes today and the following 6 days', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(preset: TodoRangePreset.next7),
        _date(_today),
      );
      expect(
        window,
        const TodoDateWindow(startKey: '2026-10-20', endKey: '2026-10-26'),
      );
    });

    test('next 30 days includes today and the following 29 days', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(preset: TodoRangePreset.next30),
        _date(_today),
      );
      expect(
        window,
        const TodoDateWindow(startKey: '2026-10-20', endKey: '2026-11-18'),
      );
    });

    test('next 7 days crosses a year boundary', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(preset: TodoRangePreset.next7),
        _date('2026-12-29'),
      );
      expect(
        window,
        const TodoDateWindow(startKey: '2026-12-29', endKey: '2027-01-04'),
      );
    });

    test('next 7 days crosses leap day', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(preset: TodoRangePreset.next7),
        _date('2024-02-26'),
      );
      expect(
        window,
        const TodoDateWindow(startKey: '2024-02-26', endKey: '2024-03-03'),
      );
    });

    test('custom range includes both boundaries', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(
          preset: TodoRangePreset.custom,
          customStart: '2026-01-31',
          customEnd: '2026-02-01',
        ),
        _date(_today),
      );
      expect(window!.contains('2026-01-31'), isTrue);
      expect(window.contains('2026-02-01'), isTrue);
      expect(window.contains('2026-01-30'), isFalse);
      expect(window.contains('2026-02-02'), isFalse);
    });

    test('custom range with reversed dates is normalized', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(
          preset: TodoRangePreset.custom,
          customStart: '2026-02-01',
          customEnd: '2026-01-31',
        ),
        _date(_today),
      );
      expect(
        window,
        const TodoDateWindow(startKey: '2026-01-31', endKey: '2026-02-01'),
      );
    });

    test('invalid custom dates fall back to all', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(
          preset: TodoRangePreset.custom,
          customStart: '2026-02-30',
          customEnd: '2026-13-01',
        ),
        _date(_today),
      );
      expect(window, isNull);
    });

    test('dynamic presets ignore stored absolute dates', () {
      final window = resolveTodoDateWindow(
        const TodoViewState(
          preset: TodoRangePreset.today,
          customStart: '2020-01-01',
          customEnd: '2020-01-02',
        ),
        _date(_today),
      );
      expect(window, const TodoDateWindow(startKey: _today, endKey: _today));
    });
  });

  group('buildTodoSections filtering', () {
    final todos = <Event>[
      _todo(1, date: '2026-10-19'), // overdue
      _todo(2, date: '2026-10-20'),
      _todo(3, date: '2026-10-21'),
      _todo(4, date: '2026-10-26'),
      _todo(5, date: '2026-10-27'),
      _todo(6, date: '2026-11-18'),
      _todo(7, date: '2026-11-19'),
      _longTerm(8),
      _todo(9, date: '2026-10-01', completed: true),
      _longTerm(10, completed: true),
      _todo(11, date: '2026-10-20', title: kRepeatSkipMarker),
    ];

    List<String> sectionDates(TodoSections sections) =>
        sections.dateSections.map((s) => s.dateKey).toList();

    test('today excludes overdue and future days', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(preset: TodoRangePreset.today),
        today: _date(_today),
      );
      expect(sectionDates(sections), ['2026-10-20']);
      expect(sections.dateSections.single.items.map((e) => e.id), [2]);
    });

    test('next 7 days uses an inclusive 7-day window', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(preset: TodoRangePreset.next7),
        today: _date(_today),
      );
      expect(sectionDates(sections), ['2026-10-20', '2026-10-21', '2026-10-26']);
    });

    test('next 30 days uses an inclusive 30-day window', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(preset: TodoRangePreset.next30),
        today: _date(_today),
      );
      expect(sectionDates(sections).last, '2026-11-18');
      expect(sectionDates(sections), isNot(contains('2026-11-19')));
    });

    test('all includes overdue and all completed dates', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(),
        today: _date(_today),
      );
      expect(sectionDates(sections).first, '2026-10-19');
      expect(sectionDates(sections), contains('2026-11-19'));
      expect(sections.isFiltered, isFalse);
      expect(sections.completedTodos.map((e) => e.id), containsAll([9, 10]));
    });

    test('custom range only includes the chosen boundaries', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(
          preset: TodoRangePreset.custom,
          customStart: '2026-10-19',
          customEnd: '2026-10-20',
        ),
        today: _date(_today),
      );
      expect(sectionDates(sections), ['2026-10-19', '2026-10-20']);
    });

    test('long-term tasks stay visible under every preset', () {
      for (final preset in TodoRangePreset.values) {
        if (preset == TodoRangePreset.custom) continue;
        final sections = buildTodoSections(
          todos,
          view: TodoViewState(preset: preset),
          today: _date(_today),
        );
        expect(
          sections.longTermTodos.map((e) => e.id),
          [8],
          reason: 'preset $preset',
        );
      }
    });

    test('completed tasks follow the window but undated ones stay', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(preset: TodoRangePreset.today),
        today: _date(_today),
      );
      expect(sections.completedTodos.map((e) => e.id), [10]);
    });

    test('repeat skip markers are never rendered', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(),
        today: _date(_today),
      );
      final allVisible = sections.allVisibleTodos.map((e) => e.id);
      expect(allVisible, isNot(contains(11)));
      expect(
        sectionDates(sections),
        isNot(contains(kRepeatSkipMarker)),
      );
    });

    test('empty projection reports stored state for empty messaging', () {
      final filteredEmpty = buildTodoSections(
        [_todo(1, date: '2027-01-01')],
        view: const TodoViewState(preset: TodoRangePreset.today),
        today: _date(_today),
      );
      expect(filteredEmpty.isEmpty, isTrue);
      expect(filteredEmpty.hasStoredTodos, isTrue);
      expect(filteredEmpty.isFiltered, isTrue);

      final trulyEmpty = buildTodoSections(
        const [],
        view: const TodoViewState(),
        today: _date(_today),
      );
      expect(trulyEmpty.isEmpty, isTrue);
      expect(trulyEmpty.hasStoredTodos, isFalse);
    });
  });

  group('buildTodoSections sorting', () {
    final todos = <Event>[
      _todo(1, date: '2026-10-21', startTime: '08:00'),
      _todo(2, date: '2026-10-21', startTime: '10:00'),
      _todo(3, date: '2026-10-20', startTime: '09:00'),
      _todo(4, date: '2026-10-22', startTime: '09:00'),
      _todo(5, date: '2026-10-22', startTime: '09:00'),
      _longTerm(6),
      _longTerm(7),
      _todo(8, date: '2026-10-01', completed: true),
      _todo(9, date: '2026-10-25', startTime: '12:00', completed: true),
      _longTerm(10, completed: true),
    ];

    test('ascending sorts dates and in-group times ascending', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(),
        today: _date(_today),
      );
      expect(
        sections.dateSections.map((s) => s.dateKey).toList(),
        ['2026-10-20', '2026-10-21', '2026-10-22'],
      );
      expect(
        sections.dateSections[1].items.map((e) => e.id).toList(),
        [1, 2],
      );
      expect(
        sections.completedTodos.map((e) => e.id).toList(),
        [8, 9, 10],
      );
    });

    test('descending reverses dates, in-group times and completed dates', () {
      final sections = buildTodoSections(
        todos,
        view: const TodoViewState(descending: true),
        today: _date(_today),
      );
      expect(
        sections.dateSections.map((s) => s.dateKey).toList(),
        ['2026-10-22', '2026-10-21', '2026-10-20'],
      );
      expect(
        sections.dateSections[1].items.map((e) => e.id).toList(),
        [2, 1],
      );
      expect(
        sections.completedTodos.map((e) => e.id).toList(),
        [9, 8, 10],
      );
    });

    test('equal date and time keep a deterministic order across rebuilds', () {
      List<int> order({required bool descending}) => buildTodoSections(
            todos,
            view: TodoViewState(descending: descending),
            today: _date(_today),
          ).dateSections
              .firstWhere((s) => s.dateKey == '2026-10-22')
              .items
              .map((e) => e.id)
              .toList();

      expect(order(descending: false), order(descending: false));
      expect(order(descending: true), order(descending: true));
      expect(order(descending: false), [4, 5]);
    });

    test('long-term order is independent of the sort direction', () {
      final asc = buildTodoSections(
        todos,
        view: const TodoViewState(),
        today: _date(_today),
      );
      final desc = buildTodoSections(
        todos,
        view: const TodoViewState(descending: true),
        today: _date(_today),
      );
      expect(asc.longTermTodos.map((e) => e.id).toList(), [6, 7]);
      expect(desc.longTermTodos.map((e) => e.id).toList(), [6, 7]);
    });
  });
}
