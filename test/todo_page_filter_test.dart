import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/providers/app_providers.dart';
import 'package:soft_schedule/core/providers/todo_view_providers.dart';
import 'package:soft_schedule/core/widgets/compact_todo_card.dart';
import 'package:soft_schedule/core/widgets/todo_filter_bar.dart';
import 'package:soft_schedule/features/todo/todo_page.dart';
import 'package:soft_schedule/l10n/app_localizations.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

final _today = DateTime(2026, 10, 20);

Event _todo(
  int id,
  String title, {
  String date = '2026-10-20',
  String startTime = '09:00',
  bool completed = false,
  TodoTimeMode mode = TodoTimeMode.timeBlock,
}) {
  return Event(
    id: id,
    title: title,
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

Future<SharedPreferences> _pumpTodoPage(
  WidgetTester tester, {
  required List<Event> todos,
  Map<String, Object> prefsValues = const {},
}) async {
  SharedPreferences.setMockInitialValues(prefsValues);
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        allTodosProvider.overrideWith((ref) => Stream.value(todos)),
        todoTodayProvider.overrideWith((ref) => _today),
      ],
      child: const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: TodoPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return prefs;
}

List<String> _visibleTitles(WidgetTester tester) {
  return tester
      .widgetList<CompactTodoCard>(find.byType(CompactTodoCard))
      .map((card) => card.event.title)
      .toList();
}

void main() {
  final sampleTodos = <Event>[
    _todo(1, 'Today task'),
    _todo(2, 'Tomorrow task', date: '2026-10-21'),
    _todo(3, 'Long term task', date: '', startTime: '', mode: TodoTimeMode.noTime),
    _todo(4, 'Old done', date: '2026-10-01', completed: true),
    _todo(5, 'Future done', date: '2026-10-22', completed: true),
  ];

  testWidgets('today preset hides other days but keeps long-term tasks',
      (tester) async {
    await _pumpTodoPage(
      tester,
      todos: sampleTodos,
      prefsValues: {kTodoRangePresetKey: 'today'},
    );

    expect(find.text('Today task'), findsOneWidget);
    expect(find.text('Tomorrow task'), findsNothing);
    expect(find.text('Long term task'), findsOneWidget);
    expect(find.text('Old done'), findsNothing);
    expect(find.textContaining('已完成'), findsNothing);
  });

  testWidgets('tapping a preset chip updates the list and persists',
      (tester) async {
    final prefs = await _pumpTodoPage(
      tester,
      todos: sampleTodos,
      prefsValues: {kTodoRangePresetKey: 'today'},
    );
    expect(find.text('Tomorrow task'), findsNothing);

    await tester.tap(find.text('未来7天'));
    await tester.pumpAndSettle();

    expect(find.text('Tomorrow task'), findsOneWidget);
    expect(prefs.getString(kTodoRangePresetKey), 'next7');
  });

  testWidgets('all preset shows overdue and completed tasks', (tester) async {
    await _pumpTodoPage(
      tester,
      todos: [
        _todo(1, 'Overdue task', date: '2026-10-19'),
        _todo(2, 'Old done', date: '2026-10-01', completed: true),
      ],
      prefsValues: {kTodoRangePresetKey: 'all'},
    );

    expect(find.text('Overdue task'), findsOneWidget);
    expect(find.textContaining('已完成 (1)'), findsOneWidget);
  });

  testWidgets('sort toggle reverses date order and persists', (tester) async {
    final prefs = await _pumpTodoPage(
      tester,
      todos: [
        _todo(1, 'Earlier task', date: '2026-10-20'),
        _todo(2, 'Later task', date: '2026-10-22'),
      ],
      prefsValues: {kTodoRangePresetKey: 'all'},
    );

    expect(_visibleTitles(tester), ['Earlier task', 'Later task']);
    expect(find.text('正序'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('日期升序'));
    await tester.pumpAndSettle();

    expect(_visibleTitles(tester), ['Later task', 'Earlier task']);
    expect(prefs.getBool(kTodoSortDescendingKey), isTrue);
    expect(find.text('倒序'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

    await tester.tap(find.byTooltip('日期降序'));
    await tester.pumpAndSettle();

    expect(_visibleTitles(tester), ['Earlier task', 'Later task']);
    expect(prefs.getBool(kTodoSortDescendingKey), isFalse);
    expect(find.text('正序'), findsOneWidget);
  });

  testWidgets('custom preset shows the saved range on the chip',
      (tester) async {
    await _pumpTodoPage(
      tester,
      todos: sampleTodos,
      prefsValues: {
        kTodoRangePresetKey: 'custom',
        kTodoRangeStartKey: '2026-10-01',
        kTodoRangeEndKey: '2026-10-31',
      },
    );

    expect(find.text('10/01–10/31'), findsOneWidget);
    expect(find.text('Today task'), findsOneWidget);
    expect(find.text('Old done'), findsNothing);
  });

  testWidgets('cancelling the date range picker keeps the previous preset',
      (tester) async {
    final prefs = await _pumpTodoPage(
      tester,
      todos: sampleTodos,
      prefsValues: {kTodoRangePresetKey: 'all'},
    );

    await tester.tap(find.text('自定义'));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.byType(DateRangePickerDialog), findsNothing);
    expect(prefs.getString(kTodoRangePresetKey), 'all');
    expect(_visibleTitles(tester), isNotEmpty);
  });

  testWidgets('filtered empty state uses the range message', (tester) async {
    await _pumpTodoPage(
      tester,
      todos: [_todo(1, 'Tomorrow task', date: '2026-10-21')],
      prefsValues: {kTodoRangePresetKey: 'today'},
    );

    expect(find.text('当前日期区间暂无待办'), findsOneWidget);
  });

  testWidgets('batch mode hides the filter bar', (tester) async {
    await _pumpTodoPage(
      tester,
      todos: [_todo(1, 'Task A'), _todo(2, 'Task B', date: '2026-10-21')],
      prefsValues: {kTodoRangePresetKey: 'all'},
    );
    expect(find.byType(TodoFilterBar), findsOneWidget);

    await tester.longPress(find.text('Task A'));
    await tester.pumpAndSettle();

    expect(find.byType(TodoFilterBar), findsNothing);
    expect(find.byType(AppBar), findsNothing);

    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();

    expect(find.byType(TodoFilterBar), findsOneWidget);
  });
}
