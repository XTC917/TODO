import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/date_time_formats.dart';
import '../utils/todo_date_filter.dart';
import 'app_providers.dart';

const kTodoRangePresetKey = 'todo_range_preset';
const kTodoRangeStartKey = 'todo_range_start';
const kTodoRangeEndKey = 'todo_range_end';
const kTodoSortDescendingKey = 'todo_sort_descending';

/// Reads persisted Todo page preferences with safe fallbacks.
///
/// Corrupted or missing values fall back to "all dates + ascending". A custom
/// preset without a valid start/end date also falls back to "all dates" so the
/// page never ends up in an unusable filtered state.
TodoViewState readTodoViewState(SharedPreferences prefs) {
  try {
    final rawPreset = prefs.getString(kTodoRangePresetKey);
    var preset = TodoRangePreset.all;
    if (rawPreset != null) {
      final match =
          TodoRangePreset.values.where((value) => value.name == rawPreset);
      if (match.isEmpty) return const TodoViewState();
      preset = match.first;
    }

    final customStart = normalizeDateKey(prefs.getString(kTodoRangeStartKey));
    final customEnd = normalizeDateKey(prefs.getString(kTodoRangeEndKey));
    final descending = prefs.getBool(kTodoSortDescendingKey) ?? false;

    if (preset == TodoRangePreset.custom) {
      if (customStart == null || customEnd == null) {
        return const TodoViewState();
      }
      final ordered = customStart.compareTo(customEnd) <= 0
          ? (customStart, customEnd)
          : (customEnd, customStart);
      return TodoViewState(
        preset: preset,
        customStart: ordered.$1,
        customEnd: ordered.$2,
        descending: descending,
      );
    }

    return TodoViewState(
      preset: preset,
      customStart: customStart,
      customEnd: customEnd,
      descending: descending,
    );
  } catch (_) {
    return const TodoViewState();
  }
}

class TodoViewStateController extends StateNotifier<TodoViewState> {
  TodoViewStateController(this._prefs) : super(readTodoViewState(_prefs));

  final SharedPreferences _prefs;

  /// Switches between dynamic presets and "all". [TodoRangePreset.custom] must
  /// go through [setCustomRange] once the user confirmed a range.
  Future<void> selectPreset(TodoRangePreset preset) async {
    if (preset == TodoRangePreset.custom) return;
    if (state.preset == preset) return;
    state = state.copyWith(preset: preset);
    await _prefs.setString(kTodoRangePresetKey, preset.name);
  }

  /// Persists a confirmed custom range. Invalid input keeps the old setting.
  Future<void> setCustomRange({
    required String start,
    required String end,
  }) async {
    final normalizedStart = normalizeDateKey(start);
    final normalizedEnd = normalizeDateKey(end);
    if (normalizedStart == null || normalizedEnd == null) return;

    final ordered = normalizedStart.compareTo(normalizedEnd) <= 0
        ? (normalizedStart, normalizedEnd)
        : (normalizedEnd, normalizedStart);

    state = state.copyWith(
      preset: TodoRangePreset.custom,
      customStart: ordered.$1,
      customEnd: ordered.$2,
    );
    await _prefs.setString(kTodoRangePresetKey, TodoRangePreset.custom.name);
    await _prefs.setString(kTodoRangeStartKey, ordered.$1);
    await _prefs.setString(kTodoRangeEndKey, ordered.$2);
  }

  Future<void> setDescending(bool descending) async {
    if (state.descending == descending) return;
    state = state.copyWith(descending: descending);
    await _prefs.setBool(kTodoSortDescendingKey, descending);
  }
}

final todoViewStateProvider =
    StateNotifierProvider<TodoViewStateController, TodoViewState>((ref) {
  return TodoViewStateController(ref.watch(sharedPreferencesProvider));
});

/// Current local day used to resolve dynamic presets.
///
/// Refreshed when the Todo tab becomes visible and when the app resumes so a
/// long-running session crossing midnight recalculates "today"/"next 7"/"next 30".
final todoTodayProvider = StateProvider<DateTime>((ref) {
  return DateTimeFormats.dateOnly(DateTime.now());
});

/// Derived Todo list projection: filter -> group -> sort.
final todoSectionsProvider = Provider<AsyncValue<TodoSections>>((ref) {
  final todosAsync = ref.watch(allTodosProvider);
  final view = ref.watch(todoViewStateProvider);
  final today = ref.watch(todoTodayProvider);
  return todosAsync.whenData(
    (todos) => buildTodoSections(todos, view: view, today: today),
  );
});
