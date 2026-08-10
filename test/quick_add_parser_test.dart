import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/date_time_formats.dart';
import 'package:soft_schedule/core/utils/english_natural_language_parser.dart';
import 'package:soft_schedule/core/utils/natural_language_parser.dart';
import 'package:soft_schedule/core/utils/quick_add_parser.dart';
import 'package:soft_schedule/models/enums.dart';

void main() {
  final ref = DateTime(2026, 8, 9); // Sunday

  group('Chinese parser', () {
    const parser = ChineseNaturalLanguageParser();

    test('full example with reminders', () {
      final r = parser.parse(
        '明天下午三点到五点开会，提前半小时和一小时提醒我',
        reference: ref,
      );
      expect(r.title, '开会');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-10');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(r.reminderOffsetsSeconds, [3600, 1800]);
    });
  });

  group('English parser', () {
    const parser = EnglishNaturalLanguageParser();

    test('Meeting tomorrow from 3 to 5 pm, remind me 30 minutes and 1 hour before.', () {
      final r = parser.parse(
        'Meeting tomorrow from 3 to 5 pm, remind me 30 minutes and 1 hour before.',
        reference: ref,
      );
      expect(r.title, 'Meeting');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-10');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(r.reminderOffsetsSeconds, [3600, 1800]);
      expect(r.taskType, TaskType.schedule);
    });

    test('Meeting tomorrow at 3 pm, remind me 10 minutes before.', () {
      final r = parser.parse(
        'Meeting tomorrow at 3 pm, remind me 10 minutes before.',
        reference: ref,
      );
      expect(r.title, 'Meeting');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.reminderOffsetsSeconds, [600]);
    });

    test('Team meeting tomorrow from 3 pm to 5 pm, remind me 30 minutes and 1 hour before.', () {
      final r = parser.parse(
        'Team meeting tomorrow from 3 pm to 5 pm, remind me 30 minutes and 1 hour before.',
        reference: ref,
      );
      expect(r.title, 'Team meeting');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(r.reminderOffsetsSeconds, [3600, 1800]);
    });

    test('no reminder without trigger phrase', () {
      final r = parser.parse(
        'Meeting tomorrow at 3 pm',
        reference: ref,
      );
      expect(r.reminderOffsetsSeconds, isEmpty);
    });

    test('notify me half an hour before', () {
      final r = parser.parse(
        'Meeting tomorrow at 3 pm, notify me half an hour before.',
        reference: ref,
      );
      expect(r.reminderOffsetsSeconds, [1800]);
    });

    test('due by 3 pm -> todo deadline 15:00', () {
      final r = parser.parse('Finish report due by 3 pm', reference: ref);
      expect(r.taskType, TaskType.todo);
      expect(r.todoTimeMode, TodoTimeMode.deadline);
      expect(r.endTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.startTime, isNull);
    });

    test('tomorrow due by 3 pm', () {
      final r = parser.parse(
        'Submit homework tomorrow due by 3 pm',
        reference: ref,
      );
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-10');
      expect(r.endTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.todoTimeMode, TodoTimeMode.deadline);
    });

    test('finish by 8 tonight', () {
      final r = parser.parse('Finish report by 8 tonight', reference: ref);
      expect(r.endTime, const TimeOfDay(hour: 20, minute: 0));
      expect(r.todoTimeMode, TodoTimeMode.deadline);
      expect(r.taskType, TaskType.todo);
    });
  });

  group('Explicit task type', () {
    const parser = EnglishNaturalLanguageParser();

    test('Add a schedule -> Schedule', () {
      final r = parser.parse(
        'Add a schedule for tomorrow at 3 pm, team meeting.',
        reference: ref,
      );
      expect(r.taskType, TaskType.schedule);
      expect(r.title, 'team meeting');
    });

    test('Add a todo -> Todo', () {
      final r = parser.parse(
        'Add a todo for tomorrow, buy groceries.',
        reference: ref,
      );
      expect(r.taskType, TaskType.todo);
      expect(r.title, 'buy groceries');
    });

    test('Create a todo with time stays Todo', () {
      final r = parser.parse(
        'Create a todo for tomorrow at 3 pm, buy groceries.',
        reference: ref,
      );
      expect(r.taskType, TaskType.todo);
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
    });
  });

  group('Quick add language dispatch', () {
    test('parseQuickAddInput zh vs en produce same structure', () {
      const zh = '明天下午三点到五点开会，提前半小时和一小时提醒我';
      const en =
          'Meeting tomorrow from 3 to 5 pm, remind me 30 minutes and 1 hour before.';

      final zhResult = parseQuickAddInput(
        zh,
        language: QuickAddParserLanguage.zh,
        reference: ref,
      );
      final enResult = parseQuickAddInput(
        en,
        language: QuickAddParserLanguage.en,
        reference: ref,
      );

      expect(DateTimeFormats.formatDate(zhResult.date!), '2026-08-10');
      expect(DateTimeFormats.formatDate(enResult.date!), '2026-08-10');
      expect(zhResult.startTime, enResult.startTime);
      expect(zhResult.endTime, enResult.endTime);
      expect(zhResult.reminderOffsetsSeconds, enResult.reminderOffsetsSeconds);
      expect(zhResult.taskType, enResult.taskType);
    });
  });
}
