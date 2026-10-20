import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/providers/todo_view_providers.dart';
import 'package:soft_schedule/core/utils/todo_date_filter.dart';

Future<SharedPreferences> _prefs([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('readTodoViewState', () {
    test('missing preferences default to all dates + ascending', () async {
      final prefs = await _prefs();
      expect(readTodoViewState(prefs), const TodoViewState());
    });

    test('restores a dynamic preset without absolute dates', () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'next7',
        kTodoSortDescendingKey: true,
      });
      final state = readTodoViewState(prefs);
      expect(state.preset, TodoRangePreset.next7);
      expect(state.descending, isTrue);
      expect(state.customStart, isNull);
      expect(state.customEnd, isNull);
    });

    test('restores a confirmed custom range and its boundaries', () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'custom',
        kTodoRangeStartKey: '2026-01-31',
        kTodoRangeEndKey: '2026-02-01',
        kTodoSortDescendingKey: true,
      });
      final state = readTodoViewState(prefs);
      expect(state.preset, TodoRangePreset.custom);
      expect(state.customStart, '2026-01-31');
      expect(state.customEnd, '2026-02-01');
      expect(state.descending, isTrue);
    });

    test('custom preset with missing dates falls back to all + ascending',
        () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'custom',
        kTodoRangeStartKey: '2026-01-31',
        kTodoSortDescendingKey: true,
      });
      expect(readTodoViewState(prefs), const TodoViewState());
    });

    test('corrupted preset name falls back to all + ascending', () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'everyOtherTuesday',
        kTodoSortDescendingKey: true,
      });
      expect(readTodoViewState(prefs), const TodoViewState());
    });

    test('corrupted custom dates fall back to all + ascending', () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'custom',
        kTodoRangeStartKey: '2026-02-30',
        kTodoRangeEndKey: 'not-a-date',
        kTodoSortDescendingKey: true,
      });
      expect(readTodoViewState(prefs), const TodoViewState());
    });

    test('wrong value types fall back safely', () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'today',
        kTodoSortDescendingKey: 'yes',
      });
      expect(readTodoViewState(prefs), const TodoViewState());
    });

    test('reversed custom dates are normalized on read', () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'custom',
        kTodoRangeStartKey: '2026-02-01',
        kTodoRangeEndKey: '2026-01-31',
      });
      final state = readTodoViewState(prefs);
      expect(state.customStart, '2026-01-31');
      expect(state.customEnd, '2026-02-01');
    });
  });

  group('TodoViewStateController persistence', () {
    test('dynamic preset stores only the preset type', () async {
      final prefs = await _prefs();
      final controller = TodoViewStateController(prefs);

      await controller.selectPreset(TodoRangePreset.today);

      expect(prefs.getString(kTodoRangePresetKey), 'today');
      expect(prefs.getString(kTodoRangeStartKey), isNull);
      expect(prefs.getString(kTodoRangeEndKey), isNull);

      // Simulates a new app launch reading the same storage.
      final restored = readTodoViewState(prefs);
      expect(restored.preset, TodoRangePreset.today);
    });

    test('dynamic preset window follows the current date after restart',
        () async {
      final prefs = await _prefs({
        kTodoRangePresetKey: 'today',
      });
      final first = resolveTodoDateWindow(
        readTodoViewState(prefs),
        DateTime(2026, 10, 20),
      );
      final later = resolveTodoDateWindow(
        readTodoViewState(prefs),
        DateTime(2026, 11, 1),
      );
      expect(first!.startKey, '2026-10-20');
      expect(first.endKey, '2026-10-20');
      expect(later!.startKey, '2026-11-01');
      expect(later.endKey, '2026-11-01');
    });

    test('custom range persists concrete dates and survives restart', () async {
      final prefs = await _prefs();
      final controller = TodoViewStateController(prefs);

      await controller.setCustomRange(
        start: '2026-10-01',
        end: '2026-10-31',
      );

      expect(prefs.getString(kTodoRangePresetKey), 'custom');
      expect(prefs.getString(kTodoRangeStartKey), '2026-10-01');
      expect(prefs.getString(kTodoRangeEndKey), '2026-10-31');

      final restored = TodoViewStateController(prefs).state;
      expect(restored.preset, TodoRangePreset.custom);
      expect(restored.customStart, '2026-10-01');
      expect(restored.customEnd, '2026-10-31');
    });

    test('custom range stays fixed across different current dates', () async {
      final prefs = await _prefs();
      final controller = TodoViewStateController(prefs);
      await controller.setCustomRange(
        start: '2026-10-01',
        end: '2026-10-31',
      );

      final restored = readTodoViewState(prefs);
      final first = resolveTodoDateWindow(restored, DateTime(2026, 10, 20));
      final later = resolveTodoDateWindow(restored, DateTime(2027, 2, 10));
      expect(first!.startKey, '2026-10-01');
      expect(first.endKey, '2026-10-31');
      expect(later!.startKey, '2026-10-01');
      expect(later.endKey, '2026-10-31');
    });

    test('invalid custom input keeps the previous setting', () async {
      final prefs = await _prefs();
      final controller = TodoViewStateController(prefs);
      await controller.selectPreset(TodoRangePreset.next30);

      await controller.setCustomRange(start: 'bad', end: '2026-10-31');

      expect(controller.state.preset, TodoRangePreset.next30);
      expect(prefs.getString(kTodoRangePresetKey), 'next30');
    });

    test('sort direction persists and survives restart', () async {
      final prefs = await _prefs();
      final controller = TodoViewStateController(prefs);

      await controller.setDescending(true);
      expect(prefs.getBool(kTodoSortDescendingKey), isTrue);
      expect(TodoViewStateController(prefs).state.descending, isTrue);

      await controller.setDescending(false);
      expect(prefs.getBool(kTodoSortDescendingKey), isFalse);
      expect(TodoViewStateController(prefs).state.descending, isFalse);
    });

    test('unrelated preference changes do not disturb the todo view state',
        () async {
      final prefs = await _prefs();
      final controller = TodoViewStateController(prefs);
      await controller.selectPreset(TodoRangePreset.next7);
      await controller.setDescending(true);

      await prefs.setString('app_language', 'ko');
      await prefs.setString('theme_mode', 'dark');

      final restored = readTodoViewState(prefs);
      expect(restored.preset, TodoRangePreset.next7);
      expect(restored.descending, isTrue);
    });

    test('returning to a dynamic preset keeps stored custom dates', () async {
      final prefs = await _prefs();
      final controller = TodoViewStateController(prefs);
      await controller.setCustomRange(
        start: '2026-10-01',
        end: '2026-10-31',
      );
      await controller.selectPreset(TodoRangePreset.all);

      final restored = TodoViewStateController(prefs).state;
      expect(restored.preset, TodoRangePreset.all);
      expect(restored.customStart, '2026-10-01');
      expect(restored.customEnd, '2026-10-31');
    });
  });
}
