import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import '../../database/focus_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import 'focus_providers.dart';
import '../services/notification_service.dart';
import '../utils/date_time_formats.dart';

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository(ref.watch(appDatabaseProvider));
});

final focusRepositoryProvider = Provider<FocusRepository>((ref) {
  return FocusRepository(ref.watch(appDatabaseProvider));
});

final databaseBackupProvider = Provider<DatabaseBackupService>((ref) {
  return DatabaseBackupService(ref.watch(appDatabaseProvider));
});

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(sharedPreferencesProvider));
});

final accentColorProvider =
    StateNotifierProvider<AccentColorController, AccentColor>((ref) {
  return AccentColorController(ref.watch(sharedPreferencesProvider));
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._prefs) : super(_readMode(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _readMode(SharedPreferences prefs) {
    return prefs.getString(_themeModeKey) == 'dark'
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(
      _themeModeKey,
      mode == ThemeMode.dark ? 'dark' : 'light',
    );
  }
}

class AccentColorController extends StateNotifier<AccentColor> {
  AccentColorController(this._prefs)
      : super(AccentColorX.fromStorage(_prefs.getString(_accentColorKey)));

  final SharedPreferences _prefs;

  Future<void> setAccent(AccentColor color) async {
    state = color;
    await _prefs.setString(_accentColorKey, color.storage);
  }
}

// --- Event providers ---

final homeSelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTimeFormats.dateOnly(DateTime.now());
});

final calendarSelectedDateProvider = StateProvider<DateTime>((ref) {
  return DateTimeFormats.dateOnly(DateTime.now());
});

final calendarFocusedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});

final eventsForDateProvider =
    StreamProvider.family<List<Event>, DateTime>((ref, date) {
  final repo = ref.watch(eventRepositoryProvider);
  return repo.watchByDate(DateTimeFormats.formatDate(date));
});

final allTodosProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllTodos();
});

final eventDatesInMonthProvider =
    StreamProvider.family<Set<String>, DateTime>((ref, month) {
  final repo = ref.watch(eventRepositoryProvider);
  final start = DateTime(month.year, month.month, 1);
  final end = DateTime(month.year, month.month + 1, 0);
  return Stream.fromFuture(
    repo.datesWithEvents(
      DateTimeFormats.formatDate(start),
      DateTimeFormats.formatDate(end),
    ),
  );
});

final daySummaryProvider =
    StreamProvider.family<DaySummary, DateTime>((ref, date) async* {
  final dateKey = DateTimeFormats.formatDate(date);
  final eventRepo = ref.watch(eventRepositoryProvider);
  final focusRepo = ref.watch(focusRepositoryProvider);

  await for (final events in eventRepo.watchByDate(dateKey)) {
    final records = await focusRepo.watchByDate(dateKey).first;
    final todos = events.where((e) => e.isTodo).toList();
    final schedules = events.where((e) => e.isSchedule).toList();
    final completed = todos.where((e) => e.isTodoDone()).length;
    final focusSeconds =
        records.fold<int>(0, (s, r) => s + r.durationSeconds);
    yield DaySummary(
      focusSeconds: focusSeconds,
      scheduleTotal: schedules.length,
      todoCompleted: completed,
      todoTotal: todos.length,
    );
  }
});

class EventActions {
  EventActions(this._ref);

  final Ref _ref;

  Future<int> create(EventDraft draft) async {
    final id = await _ref.read(eventRepositoryProvider).create(draft);
    final event = await _ref.read(eventRepositoryProvider).getById(id);
    if (event != null) {
      await NotificationService.instance.scheduleForEvent(event);
    }
    return id;
  }

  Future<void> update(Event event) async {
    await _ref.read(eventRepositoryProvider).update(event);
    await NotificationService.instance.scheduleForEvent(event);
  }

  Future<void> toggleTodo(int id, bool completed) {
    return _ref.read(eventRepositoryProvider).toggleTodoComplete(
          id,
          completed: completed,
        );
  }

  Future<void> toggleTimeline(int id, bool completed) {
    return _ref.read(eventRepositoryProvider).toggleTimelineComplete(
          id,
          completed: completed,
        );
  }

  Future<Event> duplicate(int id) {
    return _ref.read(eventRepositoryProvider).duplicate(id);
  }

  Future<void> delete(int id) async {
    await NotificationService.instance.cancelForEvent(id);
    await _ref.read(eventRepositoryProvider).delete(id);
  }

  Future<void> deleteWithScope(Event event, DeleteRepeatScope scope) async {
    await NotificationService.instance.cancelForEvent(event.id);
    await _ref.read(eventRepositoryProvider).deleteWithScope(event, scope);
  }
}

final eventActionsProvider = Provider<EventActions>((ref) {
  return EventActions(ref);
});

class FocusActions {
  FocusActions(this._ref);

  final Ref _ref;

  Future<void> saveSession(FocusSession session) async {
    if (session.startedAt == null || session.elapsedSeconds <= 0) return;
    final end = DateTime.now();
    final start = end.subtract(Duration(seconds: session.elapsedSeconds));

    await _ref.read(focusRepositoryProvider).save(
          start: start,
          end: end,
          mode: session.mode,
          eventId: session.linkedEventId,
        );

    if (session.linkedEventId != null) {
      await _ref.read(eventRepositoryProvider).addFocusedSeconds(
            session.linkedEventId!,
            session.elapsedSeconds,
          );
    }
  }
}

final focusActionsProvider = Provider<FocusActions>((ref) {
  return FocusActions(ref);
});
