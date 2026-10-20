import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/providers/app_providers.dart';
import 'package:soft_schedule/core/utils/date_time_formats.dart';
import 'package:soft_schedule/core/utils/english_natural_language_parser.dart';
import 'package:soft_schedule/core/utils/natural_language_parser.dart';
import 'package:soft_schedule/core/utils/parsed_task_draft.dart';
import 'package:soft_schedule/core/utils/quick_add_form_bridge.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

void main() {
  const zh = ChineseNaturalLanguageParser();
  const en = EnglishNaturalLanguageParser();
  final ref = DateTime(2026, 10, 20);

  String dateOf(DateTime date) => DateTimeFormats.formatDate(date);

  group('Stage 1 full example', () {
    test('parses date, range, reminders and note', () {
      final r = zh.parse(
        '11.1下午三点到五点四十上英语课，提前半小时和一小时通知我，备注一下在301教室',
        reference: ref,
      );

      expect(r.title, '英语课');
      expect(dateOf(r.date!), '2026-11-01');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, const TimeOfDay(hour: 17, minute: 40));
      expect(r.reminderOffsetsSeconds, [3600, 1800]);
      expect(r.note, '301教室');
      expect(r.taskType, TaskType.schedule);
      expect(r.todoTimeMode, TodoTimeMode.timeBlock);
      expect(r.needsDateConfirmation, isFalse);
    });
  });

  group('Absolute dates', () {
    test('supports dot, slash, hyphen and month-day forms', () {
      final inputs = [
        '11.1下午三点开会',
        '11/1下午三点开会',
        '11-1下午三点开会',
        '11月1日晚上八点开会',
        '11月1号晚上八点开会',
        '2026-11-01下午三点开会',
        '2026/11/01下午三点开会',
      ];

      for (final input in inputs) {
        final r = zh.parse(input, reference: ref);
        expect(r.date, isNotNull, reason: input);
        expect(dateOf(r.date!), '2026-11-01', reason: input);
      }
    });

    test('supports next month day', () {
      final r = zh.parse('下个月3号下午三点开会', reference: ref);
      expect(dateOf(r.date!), '2026-11-03');

      final acrossYear = zh.parse(
        '下个月3号下午三点开会',
        reference: DateTime(2026, 12, 15),
      );
      expect(dateOf(acrossYear.date!), '2027-01-03');
    });

    test('crosses month and year deterministically', () {
      final crossMonth = zh.parse(
        '2.1下午三点开会',
        reference: DateTime(2026, 1, 30),
      );
      expect(dateOf(crossMonth.date!), '2026-02-01');

      final crossYear = zh.parse(
        '1.1下午三点开会',
        reference: DateTime(2026, 12, 30),
      );
      expect(dateOf(crossYear.date!), '2027-01-01');

      final sameYear = zh.parse(
        '12.31下午三点开会',
        reference: DateTime(2026, 12, 30),
      );
      expect(dateOf(sameYear.date!), '2026-12-31');
    });

    test('explicit past year is not rolled forward', () {
      final r = zh.parse(
        '2025-12-31下午三点开会',
        reference: DateTime(2026, 8, 9),
      );
      expect(dateOf(r.date!), '2025-12-31');
    });

    test('relative dates keep working', () {
      final r = zh.parse('明天下午三点开会', reference: ref);
      expect(dateOf(r.date!), '2026-10-21');

      final weekday = zh.parse('周五下午三点开会', reference: ref);
      expect(dateOf(weekday.date!), '2026-10-23');
    });
  });

  group('Reminders', () {
    test('finds multiple reminders anywhere in the input', () {
      final r = zh.parse(
        '提前60分钟、30分钟通知我，11.1下午三点开会',
        reference: ref,
      );
      expect(r.reminderOffsetsSeconds, [3600, 1800]);
      expect(r.title, '开会');
      expect(dateOf(r.date!), '2026-11-01');
    });

    test('deduplicates and sorts descending', () {
      final r = zh.parse(
        '11.1下午三点开会，提前一天和两小时提醒，提前两小时通知我',
        reference: ref,
      );
      expect(r.reminderOffsetsSeconds, [86400, 7200]);
    });

    test('supports half hour and hour', () {
      final r = zh.parse(
        '11.1下午三点开会，提前半小时和一小时提醒',
        reference: ref,
      );
      expect(r.reminderOffsetsSeconds, [3600, 1800]);
    });
  });

  group('Notes', () {
    test('extracts Chinese note and cleans title', () {
      final r = zh.parse(
        '11.1下午三点上英语课，备注一下在301教室',
        reference: ref,
      );
      expect(r.title, '英语课');
      expect(r.note, '301教室');
    });

    test('extracts note after colon', () {
      final r = zh.parse(
        '明天下午三点开会，备注：带电脑',
        reference: ref,
      );
      expect(r.title, '开会');
      expect(r.note, '带电脑');
    });

    test('extracts English note', () {
      final r = en.parse(
        'Meeting tomorrow at 3 pm note: Room 301',
        reference: DateTime(2026, 8, 9),
      );
      expect(r.title, 'Meeting');
      expect(r.note, 'Room 301');
      expect(dateOf(r.date!), '2026-08-10');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
    });
  });

  group('Unresolved date', () {
    test('preserves times and reminders for the form', () {
      final r = zh.parse(
        '下午三点到五点开会，提前半小时提醒我',
        reference: ref,
      );

      expect(r.date, isNull);
      expect(r.needsDateConfirmation, isTrue);
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(r.reminderOffsetsSeconds, [1800]);

      final prefill = QuickAddPrefill.fromParsed(parsed: r);
      expect(prefill.date, isNull);
      expect(prefill.dateUnresolved, isTrue);
      expect(prefill.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(prefill.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(prefill.reminderOffsetsSeconds, [1800]);
    });

    test('still allows a true no-date long-term todo', () {
      final r = zh.parse('买牛奶', reference: ref);

      expect(r.date, isNull);
      expect(r.needsDateConfirmation, isFalse);
      expect(r.startTime, isNull);
      expect(r.endTime, isNull);
      expect(r.reminderOffsetsSeconds, isEmpty);
      expect(r.taskType, TaskType.todo);
      expect(r.todoTimeMode, TodoTimeMode.noTime);

      final prefill = QuickAddPrefill.fromParsed(parsed: r);
      expect(prefill.dateUnresolved, isFalse);
      expect(prefill.todoTimeMode, TodoTimeMode.noTime);
    });

    test('keeps note on a long-term todo', () {
      final r = zh.parse('买牛奶，备注：超市', reference: ref);
      expect(r.title, '买牛奶');
      expect(r.note, '超市');
      expect(r.todoTimeMode, TodoTimeMode.noTime);
    });

    testWidgets('no-date long-term todo produces a creatable draft',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final parsed = zh.parse('买牛奶，备注：超市', reference: ref);

      late EventDraft draft;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, providerRef, _) {
                draft = parsedTaskToDraft(parsed, providerRef);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(draft.title, '买牛奶');
      expect(draft.date, isEmpty);
      expect(draft.startTime, isEmpty);
      expect(draft.endTime, isEmpty);
      expect(draft.note, '超市');
      expect(draft.taskType, TaskType.todo);
      expect(draft.todoTimeMode, TodoTimeMode.noTime);
    });
  });
}
