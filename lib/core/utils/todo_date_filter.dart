import '../../models/event.dart';
import 'date_time_formats.dart';

/// Date range presets for the Todo page.
///
/// Dynamic presets ([today], [next7], [next30]) only store the preset type;
/// their absolute window is always recomputed from the current local date.
/// [custom] persists concrete `yyyy-MM-dd` start/end keys.
enum TodoRangePreset { today, next7, next30, all, custom }

const _dateKeyPattern = r'^\d{4}-\d{2}-\d{2}$';

/// Validates a stored `yyyy-MM-dd` key.
///
/// Returns the normalized key, or `null` when the value is malformed or
/// semantically invalid (e.g. `2026-02-30`).
String? normalizeDateKey(String? raw) {
  if (raw == null) return null;
  final trimmed = raw.trim();
  if (!RegExp(_dateKeyPattern).hasMatch(trimmed)) return null;
  final parsed = DateTime.tryParse(trimmed);
  if (parsed == null) return null;
  final formatted = DateTimeFormats.formatDate(parsed);
  return formatted == trimmed ? formatted : null;
}

/// Immutable Todo page view preferences.
class TodoViewState {
  const TodoViewState({
    this.preset = TodoRangePreset.all,
    this.customStart,
    this.customEnd,
    this.descending = false,
  });

  final TodoRangePreset preset;

  /// Inclusive custom range start (`yyyy-MM-dd`), only meaningful for [custom].
  final String? customStart;

  /// Inclusive custom range end (`yyyy-MM-dd`), only meaningful for [custom].
  final String? customEnd;

  final bool descending;

  bool get isFiltered => preset != TodoRangePreset.all;

  TodoViewState copyWith({
    TodoRangePreset? preset,
    String? customStart,
    String? customEnd,
    bool? descending,
  }) {
    return TodoViewState(
      preset: preset ?? this.preset,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      descending: descending ?? this.descending,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TodoViewState &&
        other.preset == preset &&
        other.customStart == customStart &&
        other.customEnd == customEnd &&
        other.descending == descending;
  }

  @override
  int get hashCode => Object.hash(preset, customStart, customEnd, descending);
}

/// Inclusive date window keyed by `yyyy-MM-dd` strings.
///
/// Lexicographic comparison is safe because keys are fixed-length, zero-padded
/// dates — the same assumption used by the SQLite range queries.
class TodoDateWindow {
  const TodoDateWindow({required this.startKey, required this.endKey});

  final String startKey;
  final String endKey;

  bool contains(String dateKey) {
    return dateKey.compareTo(startKey) >= 0 && dateKey.compareTo(endKey) <= 0;
  }

  @override
  bool operator ==(Object other) {
    return other is TodoDateWindow &&
        other.startKey == startKey &&
        other.endKey == endKey;
  }

  @override
  int get hashCode => Object.hash(startKey, endKey);
}

/// Resolves the active window for [state] against the current local [today].
///
/// Returns `null` for "all dates" (no filtering).
TodoDateWindow? resolveTodoDateWindow(TodoViewState state, DateTime today) {
  final base = DateTimeFormats.dateOnly(today);
  switch (state.preset) {
    case TodoRangePreset.all:
      return null;
    case TodoRangePreset.today:
      final key = DateTimeFormats.formatDate(base);
      return TodoDateWindow(startKey: key, endKey: key);
    case TodoRangePreset.next7:
      return _windowEndingAfter(base, 6);
    case TodoRangePreset.next30:
      return _windowEndingAfter(base, 29);
    case TodoRangePreset.custom:
      final start = normalizeDateKey(state.customStart);
      final end = normalizeDateKey(state.customEnd);
      if (start == null || end == null) return null;
      if (start.compareTo(end) <= 0) {
        return TodoDateWindow(startKey: start, endKey: end);
      }
      return TodoDateWindow(startKey: end, endKey: start);
  }
}

TodoDateWindow _windowEndingAfter(DateTime today, int offsetDays) {
  return TodoDateWindow(
    startKey: DateTimeFormats.formatDate(today),
    endKey: DateTimeFormats.formatDate(
      today.add(Duration(days: offsetDays)),
    ),
  );
}

/// One date-grouped section of the pending Todo list.
class TodoDateSection {
  const TodoDateSection({required this.dateKey, required this.items});

  final String dateKey;
  final List<Event> items;
}

/// Render-ready Todo list projection.
class TodoSections {
  const TodoSections({
    required this.dateSections,
    required this.longTermTodos,
    required this.completedTodos,
    required this.isFiltered,
    required this.hasStoredTodos,
  });

  final List<TodoDateSection> dateSections;
  final List<Event> longTermTodos;
  final List<Event> completedTodos;

  /// Whether a date window is active (anything other than "all").
  final bool isFiltered;

  /// Whether any non-hidden todo row exists at all (before filtering).
  final bool hasStoredTodos;

  bool get isEmpty =>
      dateSections.isEmpty && longTermTodos.isEmpty && completedTodos.isEmpty;

  /// Every visible todo, used by the batch toolbar actions.
  List<Event> get allVisibleTodos => [
        for (final section in dateSections) ...section.items,
        ...longTermTodos,
        ...completedTodos,
      ];
}

/// Filters, groups and sorts stored todo rows for the Todo page.
///
/// Semantics:
/// * Rows flagged as repeat skip markers are never rendered.
/// * Todos without a date (long-term tasks) are never removed by the window.
/// * Completed todos follow the same window; completed tasks without a date
///   stay in the completed section.
/// * Dated pending todos are grouped by their planned `date` and sorted by
///   `startTime` (matches the previous page behaviour, including deadlines
///   using `00:00`).
/// * Ties are broken by `id` so refreshes cannot reshuffle equal rows.
TodoSections buildTodoSections(
  List<Event> todos, {
  required TodoViewState view,
  required DateTime today,
}) {
  final window = resolveTodoDateWindow(view, today);
  final pending = <Event>[];
  final longTerm = <Event>[];
  final completed = <Event>[];
  var hasStoredTodos = false;

  for (final todo in todos) {
    if (todo.isRepeatSkip) continue;
    hasStoredTodos = true;

    if (window != null && todo.hasDate && !window.contains(todo.date)) {
      continue;
    }
    if (todo.isCompleted) {
      completed.add(todo);
      continue;
    }
    if (todo.isNoTimeTodo) {
      longTerm.add(todo);
      continue;
    }
    if (!todo.hasDate) continue;
    pending.add(todo);
  }

  final grouped = <String, List<Event>>{};
  for (final todo in pending) {
    grouped.putIfAbsent(todo.date, () => []).add(todo);
  }

  final dateKeys = grouped.keys.toList()..sort();
  final orderedKeys =
      view.descending ? dateKeys.reversed.toList() : dateKeys;
  final sections = <TodoDateSection>[];
  for (final dateKey in orderedKeys) {
    final items = grouped[dateKey]!.toList()
      ..sort((a, b) => _compareByTime(a, b, view.descending));
    sections.add(TodoDateSection(dateKey: dateKey, items: items));
  }

  final completedDated = completed.where((e) => e.hasDate).toList()
    ..sort((a, b) {
      final dateCmp = a.date.compareTo(b.date);
      final timeCmp = a.startTime.compareTo(b.startTime);
      final cmp = dateCmp != 0
          ? dateCmp
          : (timeCmp != 0 ? timeCmp : a.id.compareTo(b.id));
      return view.descending ? -cmp : cmp;
    });
  final completedUndated = completed.where((e) => !e.hasDate).toList();

  return TodoSections(
    dateSections: sections,
    longTermTodos: longTerm,
    completedTodos: [...completedDated, ...completedUndated],
    isFiltered: view.isFiltered,
    hasStoredTodos: hasStoredTodos,
  );
}

int _compareByTime(Event a, Event b, bool descending) {
  final timeCmp = a.startTime.compareTo(b.startTime);
  final cmp = timeCmp != 0 ? timeCmp : a.id.compareTo(b.id);
  return descending ? -cmp : cmp;
}
