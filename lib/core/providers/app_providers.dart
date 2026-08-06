import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import '../../database/focus_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../../models/focus_session.dart';
import '../../models/reminder_config.dart';
import '../data/demo_data.dart';
import 'focus_providers.dart';
import '../services/database_backup_service.dart';
import '../services/notification_service.dart';
import '../utils/date_time_formats.dart';

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _remindersEnabledKey = 'reminders_enabled';
const _appLanguageKey = 'app_language';
const _showSampleDataKey = 'show_sample_data';

AppLocalizations _localizationsFor(Ref ref) {
  final language = ref.watch(appLanguageProvider);
  return lookupAppLocalizations(_resolveLocale(language));
}

Locale _resolveLocale(AppLanguage language) {
  return switch (language) {
    AppLanguage.zh => const Locale('zh'),
    AppLanguage.en => const Locale('en'),
    AppLanguage.ko => const Locale('ko'),
    AppLanguage.system => _deviceLocale(),
  };
}

Locale _deviceLocale() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return switch (code) {
    'zh' => const Locale('zh'),
    'ko' => const Locale('ko'),
    _ => const Locale('en'),
  };
}

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

final allFocusRecordsProvider = StreamProvider<List<FocusRecord>>((ref) {
  return ref.watch(focusRepositoryProvider).watchAll();
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
    await NotificationService.instance.requestPermissions(force: true);
    if (await NotificationService.instance.hasPermission()) {
      await NotificationService.instance.rescheduleAll(
        _ref.read(eventRepositoryProvider),
      );
    }
  }
}

class ShowSampleDataController extends StateNotifier<bool> {
  ShowSampleDataController(this._prefs)
      : super(_prefs.getBool(_showSampleDataKey) ?? true);

  final SharedPreferences _prefs;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _prefs.setBool(_showSampleDataKey, enabled);
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

final showSampleDataProvider =
    StateNotifierProvider<ShowSampleDataController, bool>((ref) {
  return ShowSampleDataController(ref.watch(sharedPreferencesProvider));
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
  final showSample = ref.watch(showSampleDataProvider);
  final l10n = _localizationsFor(ref);
  final dateKey = DateTimeFormats.formatDate(date);
  return repo.watchByDate(dateKey).map((events) {
    if (!showSample) return events;
    return mergeDemoFirst(
      demoScheduleEventsForDate(l10n, dateKey),
      events,
    );
  });
});

final allTodosProvider = StreamProvider<List<Event>>((ref) {
  final showSample = ref.watch(showSampleDataProvider);
  final l10n = _localizationsFor(ref);
  return ref.watch(eventRepositoryProvider).watchAllTodos().map((todos) {
    if (!showSample) return todos;
    return mergeDemoFirst(demoTodos(l10n), todos);
  });
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

  void _assertNotDemo(int id) {
    if (isDemoEventId(id)) {
      throw StateError('Demo events cannot be modified');
    }
  }

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
      debugPrint(
        'Skipping notification for event ${event.id}: permission not granted',
      );
      return;
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
    _assertNotDemo(event.id);
    await _ref.read(eventRepositoryProvider).update(event);
    await _syncNotification(event);
  }

  Future<void> toggleTodo(int id, bool completed) async {
    _assertNotDemo(id);
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
    _assertNotDemo(id);
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
    _assertNotDemo(id);
    final event = await _ref.read(eventRepositoryProvider).duplicate(id);
    await _syncNotification(event);
    return event;
  }

  Future<void> delete(int id) async {
    _assertNotDemo(id);
    await NotificationService.instance.cancelForEvent(id);
    await _ref.read(eventRepositoryProvider).delete(id);
  }

  Future<void> deleteWithScope(Event event, DeleteRepeatScope scope) async {
    _assertNotDemo(event.id);
    await NotificationService.instance.cancelForEvent(event.id);
    await _ref.read(eventRepositoryProvider).deleteWithScope(event, scope);
  }

  Future<void> batchDelete(Set<int> ids) async {
    for (final id in ids) {
      _assertNotDemo(id);
      await NotificationService.instance.cancelForEvent(id);
    }
    await _ref.read(eventRepositoryProvider).batchDelete(ids);
  }

  Future<void> batchUpdateDate(Set<int> ids, String newDate) async {
    for (final id in ids) {
      _assertNotDemo(id);
    }
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

  Future<FocusRecord?> saveCompletion(FocusCompletionResult result) async {
    if (result.elapsedSeconds <= 0) return null;

    await _ref.read(focusRepositoryProvider).saveCompletion(result);

    if (result.linkedEventId != null) {
      await _ref.read(eventRepositoryProvider).addFocusedSeconds(
            result.linkedEventId!,
            result.elapsedSeconds,
          );
    }

    return FocusRecord(
      id: 0,
      date: DateTimeFormats.formatDate(result.sessionStartedAt),
      startTime: DateTimeFormats.formatTimeOfDay(result.sessionStartedAt),
      endTime: DateTimeFormats.formatTimeOfDay(result.endedAt),
      durationSeconds: result.elapsedSeconds,
      mode: result.mode,
      eventId: result.linkedEventId,
      taskTitle: result.linkedTaskTitle,
      plannedDurationSeconds: result.plannedDurationSeconds,
      completed: result.completed,
      createdAt: DateTime.now(),
    );
  }

  Future<void> deleteRecord(FocusRecord record) async {
    await _ref.read(focusRepositoryProvider).deleteRecord(record.id);
    if (record.eventId != null) {
      await _ref.read(eventRepositoryProvider).addFocusedSeconds(
            record.eventId!,
            -record.durationSeconds,
          );
    }
  }

  Future<void> updateRecord(
    FocusRecord previous,
    FocusRecord updated,
  ) async {
    await _ref.read(focusRepositoryProvider).updateRecord(
          id: updated.id,
          date: updated.date,
          startTime: updated.startTime,
          endTime: updated.endTime,
          durationSeconds: updated.durationSeconds,
          taskTitle: updated.taskTitle,
          eventId: updated.eventId,
        );

    final delta = updated.durationSeconds - previous.durationSeconds;
    if (previous.eventId != null && delta != 0) {
      await _ref.read(eventRepositoryProvider).addFocusedSeconds(
            previous.eventId!,
            delta,
          );
    }
  }
}

final focusActionsProvider = Provider<FocusActions>((ref) {
  return FocusActions(ref);
});
