import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import '../../database/focus_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../../models/reminder_config.dart';
import 'focus_providers.dart';
import '../services/database_backup_service.dart';
import '../services/notification_service.dart';
import '../utils/date_time_formats.dart';

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _remindersEnabledKey = 'reminders_enabled';
const _appLanguageKey = 'app_language';

enum AppLanguage { system, zh, en, ko }

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main()');
});

final packageInfoProvider = Provider<PackageInfo>((ref) {
  throw UnimplementedError('PackageInfo must be overridden in main()');
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

class RemindersEnabledController extends StateNotifier<bool> {
  RemindersEnabledController(this._prefs, this._ref)
      : super(_prefs.getBool(_remindersEnabledKey) ?? true) {
    NotificationService.instance.remindersEnabled = state;
  }

  final SharedPreferences _prefs;
  final Ref _ref;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_remindersEnabledKey, enabled);
    NotificationService.instance.remindersEnabled = enabled;
    if (!enabled) {
      await NotificationService.instance.cancelAll();
      return;
    }
    await NotificationService.instance.requestPermissions();
    if (await NotificationService.instance.hasPermission()) {
      await NotificationService.instance.rescheduleAll(
        _ref.read(eventRepositoryProvider),
      );
    }
  }
}

class AppLanguageController extends StateNotifier<AppLanguage> {
  AppLanguageController(this._prefs)
      : super(_readLanguage(_prefs));

  final SharedPreferences _prefs;

  static AppLanguage _readLanguage(SharedPreferences prefs) {
    return AppLanguage.values.firstWhere(
      (e) => e.name == prefs.getString(_appLanguageKey),
      orElse: () => AppLanguage.system,
    );
  }

  Locale? get localeOverride => switch (state) {
        AppLanguage.system => null,
        AppLanguage.zh => const Locale('zh'),
        AppLanguage.en => const Locale('en'),
        AppLanguage.ko => const Locale('ko'),
      };

  Future<void> setLanguage(AppLanguage language) async {
    state = language;
    await _prefs.setString(_appLanguageKey, language.name);
  }
}

final remindersEnabledProvider =
    StateNotifierProvider<RemindersEnabledController, bool>((ref) {
  return RemindersEnabledController(ref.watch(sharedPreferencesProvider), ref);
});

final appLanguageProvider =
    StateNotifierProvider<AppLanguageController, AppLanguage>((ref) {
  return AppLanguageController(ref.watch(sharedPreferencesProvider));
});

final notificationPermissionProvider = FutureProvider<bool>((ref) async {
  ref.watch(remindersEnabledProvider);
  return NotificationService.instance.hasPermission();
});

final pendingNotificationEventIdProvider = StateProvider<int?>((ref) => null);

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

  Future<void> _syncNotification(Event event) async {
    if (!_ref.read(remindersEnabledProvider)) {
      await NotificationService.instance.cancelForEvent(event.id);
      return;
    }
    if (!ReminderPresets.hasReminder(event.reminderOffsetsSeconds)) {
      await NotificationService.instance.cancelForEvent(event.id);
      return;
    }
    if (!await NotificationService.instance.hasPermission()) {
      await NotificationService.instance.requestPermissions();
    }
    await NotificationService.instance.scheduleForEvent(event);
  }

  Future<int> create(EventDraft draft) async {
    final id = await _ref.read(eventRepositoryProvider).create(draft);
    final event = await _ref.read(eventRepositoryProvider).getById(id);
    if (event != null) await _syncNotification(event);
    return id;
  }

  Future<void> update(Event event) async {
    await _ref.read(eventRepositoryProvider).update(event);
    await _syncNotification(event);
  }

  Future<void> toggleTodo(int id, bool completed) async {
    await _ref.read(eventRepositoryProvider).toggleTodoComplete(
          id,
          completed: completed,
        );
    if (completed) {
      await NotificationService.instance.cancelForEvent(id);
    } else {
      final event = await _ref.read(eventRepositoryProvider).getById(id);
      if (event != null) await _syncNotification(event);
    }
  }

  Future<void> toggleTimeline(int id, bool completed) async {
    await _ref.read(eventRepositoryProvider).toggleTimelineComplete(
          id,
          completed: completed,
        );
    if (completed) {
      await NotificationService.instance.cancelForEvent(id);
    } else {
      final event = await _ref.read(eventRepositoryProvider).getById(id);
      if (event != null) await _syncNotification(event);
    }
  }

  Future<Event> duplicate(int id) async {
    final event = await _ref.read(eventRepositoryProvider).duplicate(id);
    await _syncNotification(event);
    return event;
  }

  Future<void> delete(int id) async {
    await NotificationService.instance.cancelForEvent(id);
    await _ref.read(eventRepositoryProvider).delete(id);
  }

  Future<void> deleteWithScope(Event event, DeleteRepeatScope scope) async {
    await NotificationService.instance.cancelForEvent(event.id);
    await _ref.read(eventRepositoryProvider).deleteWithScope(event, scope);
  }

  Future<void> batchDelete(Set<int> ids) async {
    for (final id in ids) {
      await NotificationService.instance.cancelForEvent(id);
    }
    await _ref.read(eventRepositoryProvider).batchDelete(ids);
  }

  Future<void> batchUpdateDate(Set<int> ids, String newDate) async {
    await _ref.read(eventRepositoryProvider).batchUpdateDate(ids, newDate);
    if (!_ref.read(remindersEnabledProvider)) return;
    for (final id in ids) {
      final event = await _ref.read(eventRepositoryProvider).getById(id);
      if (event != null) await _syncNotification(event);
    }
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
