import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/providers/app_providers.dart';
import 'package:soft_schedule/core/utils/event_display.dart';
import 'package:soft_schedule/core/utils/parsed_task.dart';
import 'package:soft_schedule/core/utils/parsed_task_draft.dart';
import 'package:soft_schedule/core/utils/quick_add_form_bridge.dart';
import 'package:soft_schedule/core/utils/quick_add_parser.dart';
import 'package:soft_schedule/features/schedule/event_form_page.dart';
import 'package:soft_schedule/l10n/app_localizations.dart';
import 'package:soft_schedule/l10n/app_localizations_en.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

// Non-ASCII UI strings are written as Unicode escapes to keep this source file
// ASCII-only and immune to local encoding issues.
const _title = '\u5f00\u4f1a'; // meeting
const _noEndTime = '\u65e0\u7ed3\u675f\u65f6\u95f4'; // no end time
const _clearEndTime = '\u6e05\u9664\u7ed3\u675f\u65f6\u95f4'; // clear end time
const _schedule = '\u65e5\u7a0b'; // schedule
const _todo = '\u5f85\u529e'; // todo
const _input = '11.1\u4e0b\u5348\u4e09\u70b9\u5f00\u4f1a'; // 11.1 3pm meeting
const _rangeSeparator = ' \u2013 '; // en dash

Event _event({
  TaskType taskType = TaskType.schedule,
  TodoTimeMode todoTimeMode = TodoTimeMode.timeBlock,
  String startTime = '15:00',
  String endTime = '',
}) {
  final stamp = DateTime(2026, 1, 1);
  return Event(
    id: 1,
    title: _title,
    date: '2026-11-01',
    startTime: startTime,
    endTime: endTime,
    color: 'blue',
    taskType: taskType,
    todoTimeMode: todoTimeMode,
    isCompleted: false,
    repeatType: RepeatType.oneTime,
    reminderOffsetsSeconds: const [],
    focusedSeconds: 0,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

Widget _wrap(Widget child, SharedPreferences prefs) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: MaterialApp(
      locale: const Locale('zh'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

void main() {
  final en = AppLocalizationsEn();

  group('eventTimeLabel', () {
    test('shows a single time for a start-only schedule', () {
      expect(
        eventTimeLabel(_event(startTime: '15:00', endTime: ''), en),
        '15:00',
      );
    });

    test('keeps the range for a two-ended schedule', () {
      expect(
        eventTimeLabel(_event(startTime: '15:00', endTime: '17:00'), en),
        '15:00${_rangeSeparator}17:00',
      );
    });

    test('keeps todo time-block semantics', () {
      expect(
        eventTimeLabel(
          _event(
            taskType: TaskType.todo,
            todoTimeMode: TodoTimeMode.timeBlock,
            startTime: '09:00',
            endTime: '10:00',
          ),
          en,
        ),
        '09:00${_rangeSeparator}10:00',
      );
    });
  });

  group('quick add draft', () {
    testWidgets('schedule with only a start keeps endTime empty',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final parsed = parseQuickAddInput(
        _input,
        language: QuickAddParserLanguage.zh,
        reference: DateTime(2026, 10, 20),
      );

      expect(parsed.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(parsed.endTime, isNull);

      final prefill = QuickAddPrefill.fromParsed(parsed: parsed);
      expect(prefill.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(prefill.endTime, isNull);

      late EventDraft draft;
      await tester.pumpWidget(
        _wrap(
          Consumer(
            builder: (context, ref, _) {
              draft = parsedTaskToDraft(parsed, ref);
              return const SizedBox.shrink();
            },
          ),
          prefs,
        ),
      );

      expect(draft.startTime, '15:00');
      expect(draft.endTime, '');
      expect(draft.taskType, TaskType.schedule);
      expect(draft.todoTimeMode, TodoTimeMode.timeBlock);
    });

    testWidgets('todo time block still gets the legacy default end',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      // Force a todo time block to exercise the unchanged path.
      final parsed = ParsedTask(
        rawInput: _input,
        title: _title,
        date: DateTime(2026, 11, 1),
        startTime: const TimeOfDay(hour: 15, minute: 0),
        taskType: TaskType.todo,
        todoTimeMode: TodoTimeMode.timeBlock,
      );

      late EventDraft draft;
      await tester.pumpWidget(
        _wrap(
          Consumer(
            builder: (context, ref, _) {
              draft = parsedTaskToDraft(parsed, ref);
              return const SizedBox.shrink();
            },
          ),
          prefs,
        ),
      );

      expect(draft.taskType, TaskType.todo);
      expect(draft.startTime, '15:00');
      expect(draft.endTime, '16:00');
    });
  });

  group('EventFormPage end time', () {
    testWidgets('new schedule starts with no end time', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrap(
          const EventFormPage(
            initialTaskType: TaskType.schedule,
            initialStartTime: TimeOfDay(hour: 15, minute: 0),
          ),
          prefs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(_noEndTime), findsOneWidget);
      expect(find.text('16:00'), findsNothing);
    });

    testWidgets('switching todo -> schedule drops the auto end time',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrap(
          const EventFormPage(
            initialStartTime: TimeOfDay(hour: 15, minute: 0),
          ),
          prefs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('16:00'), findsOneWidget);

      await tester.tap(find.text(_schedule));
      await tester.pumpAndSettle();
      expect(find.text(_noEndTime), findsOneWidget);

      await tester.tap(find.text(_todo));
      await tester.pumpAndSettle();
      expect(find.text('16:00'), findsOneWidget);
    });

    testWidgets('clear button empties an explicit end time', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrap(
          const EventFormPage(
            initialTaskType: TaskType.schedule,
            initialStartTime: TimeOfDay(hour: 15, minute: 0),
            initialEndTime: TimeOfDay(hour: 17, minute: 0),
          ),
          prefs,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('17:00'), findsOneWidget);
      await tester.tap(find.byTooltip(_clearEndTime));
      await tester.pumpAndSettle();
      expect(find.text(_noEndTime), findsOneWidget);
    });
  });
}
