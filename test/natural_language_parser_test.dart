import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/date_time_formats.dart';
import 'package:soft_schedule/core/utils/natural_language_parser.dart';
import 'package:soft_schedule/core/utils/parsed_task.dart';
import 'package:soft_schedule/models/enums.dart';

void main() {
  const parser = NaturalLanguageParser();
  final ref = DateTime(2026, 8, 9); // Sunday

  ParsedTask parse(String input) => parser.parse(input, reference: ref);

  group('Schedule with explicit time', () {
    test('明天下午3点和导师开会', () {
      final r = parse('明天下午3点和导师开会');
      expect(r.title, '和导师开会');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-10');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, isNull);
      expect(r.taskType, TaskType.schedule);
      expect(r.reminderOffsetsSeconds, isEmpty);
    });

    test('周五晚上8点去超市买东西', () {
      final r = parse('周五晚上8点去超市买东西');
      expect(r.title, '去超市买东西');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-14');
      expect(r.startTime, const TimeOfDay(hour: 20, minute: 0));
      expect(r.taskType, TaskType.schedule);
    });

    test('明天3点到5点团队会议', () {
      final r = parse('明天3点到5点团队会议');
      expect(r.title, '团队会议');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-10');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(r.taskType, TaskType.schedule);
    });
  });

  group('Todo without specific time', () {
    test('明天买菜', () {
      final r = parse('明天买菜');
      expect(r.title, '买菜');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-10');
      expect(r.startTime, isNull);
      expect(r.endTime, isNull);
      expect(r.taskType, TaskType.todo);
      expect(r.todoTimeMode, TodoTimeMode.deadline);
    });

    test('周六阅读30分钟', () {
      final r = parse('周六阅读30分钟');
      expect(r.title, '阅读30分钟');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-15');
      expect(r.startTime, isNull);
      expect(r.taskType, TaskType.todo);
      expect(r.reminderOffsetsSeconds, isEmpty);
    });

    test('今晚把报告改完', () {
      final r = parse('今晚把报告改完');
      expect(r.title, '把报告改完');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-09');
      expect(r.startTime, isNull);
      expect(r.taskType, TaskType.todo);
    });
  });

  group('No over-guessing for vague periods', () {
    test('下午去学习', () {
      final r = parse('下午去学习');
      expect(r.startTime, isNull);
      expect(r.endTime, isNull);
    });

    test('晚上看书', () {
      final r = parse('晚上看书');
      expect(r.startTime, isNull);
      expect(r.endTime, isNull);
    });
  });

  group('Reminder offsets', () {
    test('明天下午三点开会，提前五分钟提醒我', () {
      final r = parse('明天下午三点开会，提前五分钟提醒我');
      expect(r.title, '开会');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.reminderOffsetsSeconds, [5 * 60]);
    });

    test('明天下午三点到五点开会，提前半小时和一小时通知我', () {
      final r = parse('明天下午三点到五点开会，提前半小时和一小时通知我');
      expect(r.title, '开会');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.endTime, const TimeOfDay(hour: 17, minute: 0));
      expect(r.reminderOffsetsSeconds, [60 * 60, 30 * 60]);
    });

    test('明天下午三点开会，提前10分钟和30分钟提醒我', () {
      final r = parse('明天下午三点开会，提前10分钟和30分钟提醒我');
      expect(r.reminderOffsetsSeconds, [30 * 60, 10 * 60]);
    });

    test('明天上午十点开会，提前一天提醒我', () {
      final r = parse('明天上午十点开会，提前一天提醒我');
      expect(r.startTime, const TimeOfDay(hour: 10, minute: 0));
      expect(r.reminderOffsetsSeconds, [24 * 60 * 60]);
    });

    test('今天晚上八点看电影，提前一小时和十五分钟提醒我', () {
      final r = parse('今天晚上八点看电影，提前一小时和十五分钟提醒我');
      expect(r.title, '看电影');
      expect(DateTimeFormats.formatDate(r.date!), '2026-08-09');
      expect(r.startTime, const TimeOfDay(hour: 20, minute: 0));
      expect(r.reminderOffsetsSeconds, [60 * 60, 15 * 60]);
    });

    test('明天下午三点开会', () {
      final r = parse('明天下午三点开会');
      expect(r.title, '开会');
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(r.reminderOffsetsSeconds, isEmpty);
    });
  });

  group('Explicit task type', () {
    test('添加一个日程 -> Schedule', () {
      final r = parse('添加一个日程，明天下午三点开会');
      expect(r.taskType, TaskType.schedule);
      expect(r.title, '开会');
    });

    test('添加一个待办 -> Todo', () {
      final r = parse('添加一个待办，明天下午三点买东西');
      expect(r.taskType, TaskType.todo);
      expect(r.startTime, const TimeOfDay(hour: 15, minute: 0));
    });

    test('创建待办：明天买菜', () {
      final r = parse('创建待办：明天买菜');
      expect(r.taskType, TaskType.todo);
      expect(r.title, '买菜');
    });
  });
}
