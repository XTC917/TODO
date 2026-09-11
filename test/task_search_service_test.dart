import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/date_time_formats.dart';
import 'package:soft_schedule/features/search/task_search_service.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

final _now = DateTime(2026, 9, 11, 10);
final _noon = DateTime(2026, 9, 11, 12);

Event _event({
  required int id,
  required String title,
  required String date,
  String? note,
  bool completed = false,
  RepeatType repeatType = RepeatType.oneTime,
  String? repeatGroupId,
  String? repeatUntil,
  TaskType taskType = TaskType.schedule,
  TodoTimeMode todoTimeMode = TodoTimeMode.timeBlock,
  String startTime = '09:00',
  String endTime = '10:00',
}) {
  final stamp = DateTime(2026, 1, 1);
  return Event(
    id: id,
    title: title,
    date: date,
    startTime: startTime,
    endTime: endTime,
    note: note,
    color: 'blue',
    taskType: taskType,
    todoTimeMode: todoTimeMode,
    isCompleted: completed,
    repeatType: repeatType,
    repeatGroupId: repeatGroupId,
    repeatUntil: repeatUntil,
    reminderOffsetsSeconds: const [],
    focusedSeconds: 0,
    createdAt: stamp,
    updatedAt: stamp,
  );
}

List<String> _keys(List<TaskSearchResult> results) =>
    results.map((r) => r.targetDateKey).toList();

void main() {
  group('relevance ordering (unchanged)', () {
    test('exact > prefix > contains > note-only', () {
      final events = [
        _event(id: 1, title: '今晚复习', date: '2026-09-15', note: '记得写报告交上去'),
        _event(id: 2, title: '写报告', date: '2026-09-15'),
        _event(id: 3, title: '报告修改', date: '2026-09-15'),
        _event(id: 4, title: '报告', date: '2026-09-15'),
      ];

      final results = TaskSearchService.search(events, '报告', now: _now);

      expect(results.map((r) => r.event.title).toList(), [
        '报告',
        '报告修改',
        '写报告',
        '今晚复习',
      ]);
    });

    test('spec example: prefix first, note-only last', () {
      final events = [
        _event(id: 1, title: '今晚复习', date: '2026-09-16', note: '顺手写报告'),
        _event(id: 2, title: '完成DSS报告', date: '2026-09-14'),
        _event(id: 3, title: '写报告', date: '2026-09-15'),
        _event(id: 4, title: '报告修改', date: '2026-09-15'),
      ];

      final results = TaskSearchService.search(events, '报告', now: _now);
      final titles = results.map((r) => r.event.title).toList();

      expect(titles.first, '报告修改');
      expect(titles.last, '今晚复习');
      expect(
          titles.sublist(0, 3), containsAll(['报告修改', '写报告', '完成DSS报告']));
    });
  });

  group('chinese queries (unchanged)', () {
    final events = [
      _event(id: 1, title: '写报告', date: '2026-09-15'),
      _event(id: 2, title: '完成DSS报告', date: '2026-09-16'),
      _event(id: 3, title: '今晚复习', date: '2026-09-16'),
    ];

    test('single character query returns matches', () {
      final results = TaskSearchService.search(events, '报', now: _now);

      expect(results.map((r) => r.event.title).toList(),
          containsAll(['写报告', '完成DSS报告']));
      expect(results.map((r) => r.event.title), isNot(contains('今晚复习')));
    });

    test('two character query returns matches', () {
      expect(
          TaskSearchService.search(events, '报告', now: _now), hasLength(2));
    });

    test('full keyword exact match ranks first', () {
      final results = TaskSearchService.search(events, '写报告', now: _now);

      expect(results.first.event.title, '写报告');
    });
  });

  group('english case-insensitive (unchanged)', () {
    final events = [
      _event(id: 1, title: 'Team Meeting', date: '2026-09-15'),
      _event(id: 2, title: 'MEETING Notes Review', date: '2026-09-16'),
      // No shared latin characters with "meeting", so fuzzy cannot match it.
      _event(id: 3, title: '买菜', date: '2026-09-16'),
    ];

    test('lowercase query matches mixed/upper titles', () {
      final results = TaskSearchService.search(events, 'meeting', now: _now);

      expect(results.map((r) => r.event.title).toList(),
          containsAll(['Team Meeting', 'MEETING Notes Review']));
      expect(results.map((r) => r.event.title), isNot(contains('买菜')));
    });

    test('uppercase query matches lowercase title', () {
      final lower = [
        _event(id: 1, title: 'team meeting', date: '2026-09-15'),
      ];

      expect(
          TaskSearchService.search(lower, 'MEETING', now: _now), hasLength(1));
    });
  });

  group('note hits (unchanged)', () {
    test('note-only hit keeps flags and snippet', () {
      final events = [
        _event(
          id: 1,
          title: 'DSS5105 Presentation',
          date: '2026-09-18',
          note: '记得提前把 slides 发给老师确认',
        ),
      ];

      final results = TaskSearchService.search(events, '老师', now: _now);

      expect(results, hasLength(1));
      expect(results.single.titleMatched, isFalse);
      expect(results.single.noteMatched, isTrue);
      expect(results.single.noteSnippet, contains('老师'));
    });

    test('long note snippet is truncated with ellipsis', () {
      final note = '${'前言' * 30}老师${'后记' * 30}';
      final events = [
        _event(
            id: 1, title: 'DSS5105 Presentation', date: '2026-09-18', note: note),
      ];

      final results = TaskSearchService.search(events, '老师', now: _now);
      final snippet = results.single.noteSnippet!;

      expect(snippet, contains('老师'));
      expect(snippet.length, lessThan(note.length));
      expect(snippet.contains('…'), isTrue);
    });

    test('title hit without note leaves snippet null', () {
      final events = [
        _event(id: 1, title: '写报告', date: '2026-09-15'),
      ];

      final results = TaskSearchService.search(events, '报告', now: _now);

      expect(results.single.titleMatched, isTrue);
      expect(results.single.noteMatched, isFalse);
      expect(results.single.noteSnippet, isNull);
    });
  });

  group('edge cases (unchanged)', () {
    test('empty and blank query return empty', () {
      final events = [_event(id: 1, title: '写报告', date: '2026-09-15')];

      expect(TaskSearchService.search(events, '', now: _now), isEmpty);
      expect(TaskSearchService.search(events, '   ', now: _now), isEmpty);
    });

    test('query with surrounding spaces still works', () {
      final events = [_event(id: 1, title: '写报告', date: '2026-09-15')];

      expect(TaskSearchService.search(events, '  报告  ', now: _now),
          hasLength(1));
    });

    test('no match returns empty', () {
      final events = [_event(id: 1, title: '写报告', date: '2026-09-15')];

      expect(TaskSearchService.search(events, '不存在xyz123', now: _now),
          isEmpty);
    });

    test('same-name tasks are all returned', () {
      final events = [
        _event(id: 1, title: '组会', date: '2026-09-12'),
        _event(id: 2, title: '组会', date: '2026-09-20'),
      ];

      final results = TaskSearchService.search(events, '组会', now: _now);

      expect(results, hasLength(2));
      expect(results.map((r) => r.event.id).toList(), [1, 2]);
    });

    test('history and future tasks are both searchable', () {
      final events = [
        _event(id: 1, title: '提交报告', date: '2025-03-01'),
        _event(id: 2, title: '提交报告终稿', date: '2026-12-01'),
      ];

      final results = TaskSearchService.search(events, '报告', now: _now);

      expect(results.map((r) => r.event.id).toSet(), {1, 2});
    });

    test('rows without date, skip markers and blank titles are excluded', () {
      final events = [
        _event(id: 1, title: '写报告', date: '2026-09-15'),
        _event(id: 2, title: '写报告', date: ''),
        _event(id: 3, title: '   ', date: '2026-09-15'),
        _event(
          id: 4,
          title: kRepeatSkipMarker,
          date: '2026-09-15',
          repeatGroupId: 'g-skip',
        ),
      ];

      final results = TaskSearchService.search(events, '报告', now: _now);

      expect(results.map((r) => r.event.id).toList(), [1]);
    });
  });

  group('recurring expansion: daily 约图书馆', () {
    // 2026-09-01 is a Tuesday. Daily series with 23:58-23:59.
    Event libMaster() => _event(
          id: 1,
          title: '约图书馆',
          date: '2026-09-01',
          startTime: '23:58',
          endTime: '23:59',
          repeatType: RepeatType.daily,
          repeatGroupId: 'lib-group',
        );

    test('occurrences generated continuously 09-09..09-13', () {
      final results = TaskSearchService.search(
        [libMaster()],
        '图书馆',
        now: DateTime(2026, 9, 11, 12),
      );

      expect(
          _keys(results),
          containsAll(
              ['2026-09-09', '2026-09-10', '2026-09-11', '2026-09-12', '2026-09-13']));
      // Each occurrence carries its own date + stable identity.
      final byKey = {for (final r in results) r.targetDateKey: r};
      expect(byKey['2026-09-12']!.stableKey, '1@2026-09-12');
      expect(byKey['2026-09-12']!.event.title, '约图书馆');
      expect(byKey['2026-09-10']!.stableKey, isNot('1@2026-09-12'));
    });

    test('master collapses to nothing: no master-date result', () {
      final results = TaskSearchService.search(
        [libMaster()],
        '图书馆',
        now: DateTime(2026, 9, 11, 12),
      );

      // Far more than one representative occurrence.
      expect(results.length, greaterThan(100));
    });

    test('skip occurrence date produces nothing', () {
      final skip = _event(
        id: 9,
        title: kRepeatSkipMarker,
        date: '2026-09-10',
        repeatType: RepeatType.oneTime,
        repeatGroupId: 'lib-group',
      );

      final results = TaskSearchService.search(
        [libMaster(), skip],
        '图书馆',
        now: DateTime(2026, 9, 11, 12),
      );

      expect(_keys(results), isNot(contains('2026-09-10')));
      expect(_keys(results), contains('2026-09-11'));
    });

    test('edited occurrence shows edited content, hides series title',
        () {
      final edited = _event(
        id: 42,
        title: '图书馆闭馆不去',
        date: '2026-09-12',
        startTime: '23:58',
        endTime: '23:59',
        repeatType: RepeatType.oneTime,
        repeatGroupId: 'lib-group',
      );

      final results = TaskSearchService.search(
        [libMaster(), edited],
        '图书馆',
        now: DateTime(2026, 9, 11, 12),
      );
      final on12 = results.where((r) => r.targetDateKey == '2026-09-12');

      // The day shows the edited row instead of the virtual instance.
      expect(on12, hasLength(1));
      expect(on12.single.event.id, 42);
      expect(on12.single.event.title, '图书馆闭馆不去');
    });

    test('completed occurrence keeps its own completion state', () {
      final done = _event(
        id: 43,
        title: '约图书馆',
        date: '2026-09-10',
        startTime: '23:58',
        endTime: '23:59',
        completed: true,
        repeatType: RepeatType.oneTime,
        repeatGroupId: 'lib-group',
      );

      final all = TaskSearchService.search(
        [libMaster(), done],
        '图书馆',
        now: DateTime(2026, 9, 11, 12),
      );
      final on10 = all.singleWhere((r) => r.targetDateKey == '2026-09-10');
      final on11 = all.singleWhere((r) => r.targetDateKey == '2026-09-11');

      expect(on10.isCompleted, isTrue);
      expect(on11.isCompleted, isFalse);

      final completedOnly = TaskSearchService.search(
        [libMaster(), done],
        '图书馆',
        now: DateTime(2026, 9, 11, 12),
        status: TaskSearchStatusFilter.completed,
      );
      expect(
          completedOnly.map((r) => r.targetDateKey), contains('2026-09-10'));
      expect(completedOnly.map((r) => r.targetDateKey),
          isNot(contains('2026-09-11')));

      final incompleteOnly = TaskSearchService.search(
        [libMaster(), done],
        '图书馆',
        now: DateTime(2026, 9, 11, 12),
        status: TaskSearchStatusFilter.incomplete,
      );
      expect(
          incompleteOnly.map((r) => r.targetDateKey), contains('2026-09-11'));
      expect(incompleteOnly.map((r) => r.targetDateKey),
          isNot(contains('2026-09-10')));
    });

    test('one-time event targets its own date', () {
      final events = [
        _event(id: 1, title: 'DSS5105 Presentation', date: '2026-09-18'),
      ];

      final results =
          TaskSearchService.search(events, 'Presentation', now: _now);

      expect(results.single.targetDateKey, '2026-09-18');
      expect(results.single.stableKey, '1@2026-09-18');
    });
  });

  group('recurring rules: weekly / repeatUntil / window', () {
    test('weekly only fires on series weekday', () {
      // 2026-09-01 is a Tuesday.
      final master = _event(
        id: 1,
        title: 'Weekly sync',
        date: '2026-09-01',
        repeatType: RepeatType.weekly,
        repeatGroupId: 'weekly-group',
      );

      final occurrences =
          TaskSearchService.expandSearchableOccurrences([master], _now);
      final keys = occurrences.map((e) => e.date).toSet();

      expect(keys, contains('2026-09-08')); // Tuesday
      expect(keys, contains('2026-09-15')); // Tuesday
      expect(keys, isNot(contains('2026-09-09'))); // Wednesday
    });

    test('repeatUntil bounds the series', () {
      final master = _event(
        id: 1,
        title: '约图书馆',
        date: '2026-09-01',
        repeatType: RepeatType.daily,
        repeatGroupId: 'lib-group',
        repeatUntil: '2026-09-03',
      );

      final occurrences =
          TaskSearchService.expandSearchableOccurrences([master], _now);
      final keys = occurrences.map((e) => e.date).toSet();

      expect(keys, containsAll(['2026-09-01', '2026-09-02', '2026-09-03']));
      expect(keys, isNot(contains('2026-09-04')));
    });

    test('infinite recurrence spans past-1y to future-1y', () {
      final master = _event(
        id: 1,
        title: '约图书馆',
        date: '2024-01-01',
        repeatType: RepeatType.daily,
        repeatGroupId: 'lib-group',
      );

      final occurrences =
          TaskSearchService.expandSearchableOccurrences([master], _now);
      final keys = occurrences.map((e) => e.date).toSet();

      expect(keys, contains('2025-09-11'));
      expect(keys, contains('2027-09-11'));
      expect(keys, isNot(contains('2025-09-10')));
      expect(keys, isNot(contains('2027-09-12')));
    });

    test('bounded series outside window still searchable', () {
      final master = _event(
        id: 1,
        title: '远古报告',
        date: '2020-01-01',
        repeatType: RepeatType.daily,
        repeatGroupId: 'old-group',
        repeatUntil: '2020-01-05',
      );

      final results =
          TaskSearchService.search([master], '远古', now: _now);

      expect(_keys(results),
          containsAll(['2020-01-01', '2020-01-03', '2020-01-05']));
    });
  });

  group('status filter', () {
    final events = [
      _event(id: 1, title: '写报告', date: '2026-09-12'),
      _event(id: 2, title: '写报告终稿', date: '2026-09-13', completed: true),
    ];

    test('all shows both', () {
      final results = TaskSearchService.search(events, '报告', now: _now);

      expect(results.map((r) => r.event.id).toSet(), {1, 2});
    });

    test('completed shows only completed', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        status: TaskSearchStatusFilter.completed,
      );

      expect(results.map((r) => r.event.id).toList(), [2]);
    });

    test('incomplete shows only incomplete', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        status: TaskSearchStatusFilter.incomplete,
      );

      expect(results.map((r) => r.event.id).toList(), [1]);
    });
  });

  group('type filter uses Event.taskType', () {
    final events = [
      _event(
          id: 1,
          title: '开会报告',
          date: '2026-09-12',
          taskType: TaskType.todo,
          todoTimeMode: TodoTimeMode.deadline,
          startTime: '',
          endTime: '18:00'),
      _event(id: 2, title: '开会报告会', date: '2026-09-13'),
    ];

    test('all shows both', () {
      expect(TaskSearchService.search(events, '报告', now: _now), hasLength(2));
    });

    test('todo shows deadline todo only', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        type: TaskSearchTypeFilter.todo,
      );

      expect(results.map((r) => r.event.id).toList(), [1]);
    });

    test('schedule shows schedule only', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        type: TaskSearchTypeFilter.schedule,
      );

      expect(results.map((r) => r.event.id).toList(), [2]);
    });
  });

  group('time filter on real occurrence DateTime', () {
    Event libAt(String date, String start) => _event(
          id: date.hashCode,
          title: '约图书馆',
          date: date,
          startTime: start,
          endTime: start,
          repeatType: RepeatType.oneTime,
        );

    test('today AM is past, today PM is future at noon', () {
      final events = [
        libAt('2026-09-11', '09:00'),
        libAt('2026-09-11', '15:00'),
      ];

      final future = TaskSearchService.search(
        events,
        '图书馆',
        now: _noon,
        time: TaskSearchTimeFilter.future,
      );
      final past = TaskSearchService.search(
        events,
        '图书馆',
        now: _noon,
        time: TaskSearchTimeFilter.past,
      );

      expect(future, hasLength(1));
      expect(future.single.event.startTime, '15:00');
      expect(past, hasLength(1));
      expect(past.single.event.startTime, '09:00');
    });

    test('deadline todo judges by deadline time', () {
      final events = [
        _event(
            id: 1,
            title: '交报告',
            date: '2026-09-11',
            taskType: TaskType.todo,
            todoTimeMode: TodoTimeMode.deadline,
            startTime: '',
            endTime: '09:00'),
        _event(
            id: 2,
            title: '交报告终稿',
            date: '2026-09-11',
            taskType: TaskType.todo,
            todoTimeMode: TodoTimeMode.deadline,
            startTime: '',
            endTime: '15:00'),
      ];

      final future = TaskSearchService.search(
        events,
        '报告',
        now: _noon,
        time: TaskSearchTimeFilter.future,
      );

      expect(future.map((r) => r.event.id).toList(), [2]);
    });

    test('date-only todo counts as future until day passes', () {
      final events = [
        _event(
            id: 1,
            title: '读报告',
            date: '2026-09-11',
            taskType: TaskType.todo,
            todoTimeMode: TodoTimeMode.noTime,
            startTime: '',
            endTime: ''),
      ];

      // Date-only rows have no Calendar date anchor in current data model,
      // but if dated they resolve to end-of-day: still future at noon.
      final dated = [
        _event(
            id: 1,
            title: '读报告',
            date: '2026-09-11',
            taskType: TaskType.todo,
            todoTimeMode: TodoTimeMode.timeBlock,
            startTime: '',
            endTime: ''),
      ];

      expect(
          TaskSearchService.search(dated, '报告',
              now: _noon, time: TaskSearchTimeFilter.future),
          hasLength(1));
      expect(
          TaskSearchService.search(events, '报告',
              now: _noon, time: TaskSearchTimeFilter.future),
          hasLength(1));
    });
  });

  group('combined filters', () {
    final events = [
      _event(
          id: 1,
          title: '写报告',
          date: '2026-09-20',
          taskType: TaskType.todo,
          todoTimeMode: TodoTimeMode.deadline,
          startTime: '',
          endTime: '18:00'), // incomplete + todo + future
      _event(
          id: 2,
          title: '写报告复盘',
          date: '2026-09-01',
          taskType: TaskType.todo,
          completed: true), // completed + todo + past
      _event(id: 3, title: '报告分享会', date: '2026-09-20'), // schedule + future
      _event(
          id: 4,
          title: '报告分享会回顾',
          date: '2026-09-01',
          completed: true), // schedule + past
    ];

    test('incomplete + todo + future', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        status: TaskSearchStatusFilter.incomplete,
        type: TaskSearchTypeFilter.todo,
        time: TaskSearchTimeFilter.future,
      );

      expect(results.map((r) => r.event.id).toList(), [1]);
    });

    test('completed + todo + past', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        status: TaskSearchStatusFilter.completed,
        type: TaskSearchTypeFilter.todo,
        time: TaskSearchTimeFilter.past,
      );

      expect(results.map((r) => r.event.id).toList(), [2]);
    });

    test('all + schedule + future', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        type: TaskSearchTypeFilter.schedule,
        time: TaskSearchTimeFilter.future,
      );

      expect(results.map((r) => r.event.id).toList(), [3]);
    });

    test('incomplete + schedule + all', () {
      final results = TaskSearchService.search(
        events,
        '报告',
        now: _now,
        status: TaskSearchStatusFilter.incomplete,
        type: TaskSearchTypeFilter.schedule,
      );

      expect(results.map((r) => r.event.id).toList(), [3]);
    });
  });

  group('sorting: distance, future-first, modes', () {
    List<Event> equidistantDays() => [
          _event(
              id: 1,
              title: '报告',
              date: '2026-09-09',
              startTime: '12:00',
              endTime: '12:00'),
          _event(
              id: 2,
              title: '报告',
              date: '2026-09-10',
              startTime: '12:00',
              endTime: '12:00'),
          _event(
              id: 3,
              title: '报告',
              date: '2026-09-11',
              startTime: '12:00',
              endTime: '12:00'),
          _event(
              id: 4,
              title: '报告',
              date: '2026-09-12',
              startTime: '12:00',
              endTime: '12:00'),
          _event(
              id: 5,
              title: '报告',
              date: '2026-09-13',
              startTime: '12:00',
              endTime: '12:00'),
        ];

    test('all: absolute distance ASC with future before past on ties', () {
      final results =
          TaskSearchService.search(equidistantDays(), '报告', now: _noon);

      expect(_keys(results), [
        '2026-09-11', // 0
        '2026-09-12', // +24h beats -24h
        '2026-09-10',
        '2026-09-13', // +48h beats -48h
        '2026-09-09',
      ]);
    });

    test('future: nearest future first', () {
      final results = TaskSearchService.search(
        equidistantDays(),
        '报告',
        now: _noon,
        time: TaskSearchTimeFilter.future,
      );

      expect(_keys(results), ['2026-09-11', '2026-09-12', '2026-09-13']);
    });

    test('past: nearest past first', () {
      final results = TaskSearchService.search(
        equidistantDays(),
        '报告',
        now: _noon,
        time: TaskSearchTimeFilter.past,
      );

      expect(_keys(results), ['2026-09-10', '2026-09-09']);
    });

    test('relevance still dominates distance', () {
      final events = [
        _event(id: 1, title: '今晚复习顺手写报告', date: '2026-09-11', note: '报告'),
        _event(id: 2, title: '报告', date: '2026-09-20'),
      ];

      final results = TaskSearchService.search(events, '报告', now: _now);

      // Exact title (id 2) wins despite being 9 days away.
      expect(results.first.event.id, 2);
    });
  });

  group('occurrenceDateTime helper', () {
    test('parses real DateTime for timeline rows', () {
      final e = _event(
          id: 1, title: '约图书馆', date: '2026-09-12', startTime: '23:58');

      expect(TaskSearchService.occurrenceDateTime(e, _now),
          DateTime(2026, 9, 12, 23, 58));
    });

    test('deadline uses endTime', () {
      final e = _event(
          id: 1,
          title: '交报告',
          date: '2026-09-11',
          taskType: TaskType.todo,
          todoTimeMode: TodoTimeMode.deadline,
          startTime: '',
          endTime: '15:00');

      expect(TaskSearchService.occurrenceDateTime(e, _noon),
          DateTime(2026, 9, 11, 15));
    });

    test('formatDate round-trips targetDateKey', () {
      expect(
          DateTimeFormats.formatDate(DateTime(2026, 9, 20)), '2026-09-20');
    });
  });
}
