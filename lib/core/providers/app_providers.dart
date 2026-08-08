import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import '../../database/focus_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../../models/focus_session.dart';
import '../../models/reminder_config.dart';
import 'focus_providers.dart';
import '../services/database_backup_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/theme_palette.dart';
import '../utils/date_time_formats.dart';

const _themeModeKey = 'theme_mode';
const _accentColorKey = 'accent_color';
const _bgModeKey = 'bg_mode';
const _bgCustomLightKey = 'bg_custom_light';
const _bgCustomDarkKey = 'bg_custom_dark';
const _remindersEnabledKey = 'reminders_enabled';
const _appLanguageKey = 'app_language';
const notificationPermissionPromptedKey = 'notification_permission_prompted';

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

Future<void> reopenDatabase(WidgetRef ref) async {
  ref.invalidate(appDatabaseProvider);
  ref.invalidate(eventRepositoryProvider);
  ref.invalidate(focusRepositoryProvider);
  ref.invalidate(eventsForDateProvider);
  ref.invalidate(allTodosProvider);
  ref.invalidate(allFocusRecordsProvider);
  ref.invalidate(daySummaryProvider);
  ref.invalidate(eventDatesInMonthProvider);
  ref.invalidate(databaseBackupProvider);
  await ref.read(eventRepositoryProvider).getAllEvents();
}

/// Reload Drift after the home-screen widget writes SQLite directly.
Future<void> reloadDatabaseAfterExternalChange(WidgetRef ref) async {
  ref.invalidate(appDatabaseProvider);
  ref.invalidate(eventRepositoryProvider);
  ref.invalidate(focusRepositoryProvider);
  ref.invalidate(eventsForDateProvider);
  ref.invalidate(allTodosProvider);
  ref.invalidate(allFocusRecordsProvider);
  ref.invalidate(daySummaryProvider);
  ref.invalidate(eventDatesInMonthProvider);
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(sharedPreferencesProvider));
});

final themePaletteProvider =
    StateNotifierProvider<ThemePaletteController, ThemePalette>((ref) {
  return ThemePaletteController(ref.watch(sharedPreferencesProvider));
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

class ThemePaletteController extends StateNotifier<ThemePalette> {
  ThemePaletteController(this._prefs) : super(ThemePalette.fromPrefs(_prefs));

  final SharedPreferences _prefs;

  Future<void> setPresetAccent(AccentColor color) async {
    state = state.copyWith(seedColor: color.seed, preset: color);
    await _prefs.setString(_accentColorKey, color.storage);
  }

  Future<void> setCustomSeed(Color color) async {
    state = state.copyWith(
      seedColor: color,
      clearPreset: true,
    );
    await _prefs.setString(_accentColorKey, 'custom:${AppColors.toHex(color)}');
  }

  Future<void> setBackgroundMode(BackgroundMode mode) async {
    state = state.copyWith(backgroundMode: mode);
    await _prefs.setString(
      _bgModeKey,
      mode == BackgroundMode.custom ? 'custom' : 'follow',
    );
  }

  Future<void> setCustomBackground(Color color, Brightness brightness) async {
    if (brightness == Brightness.light) {
      state = state.copyWith(
        backgroundMode: BackgroundMode.custom,
        customBackgroundLight: color,
      );
      await _prefs.setString(_bgModeKey, 'custom');
      await _prefs.setString(_bgCustomLightKey, AppColors.toHex(color));
      return;
    }
    state = state.copyWith(
      backgroundMode: BackgroundMode.custom,
      customBackgroundDark: color,
    );
    await _prefs.setString(_bgModeKey, 'custom');
    await _prefs.setString(_bgCustomDarkKey, AppColors.toHex(color));
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
    try {
      if (!enabled) {
        await NotificationService.instance.cancelAll();
        return;
      }
      await NotificationService.instance.requestPermissionsWhenReady(force: true);
      if (await NotificationService.instance.hasPermission()) {
        await NotificationService.instance.rescheduleAll(
          _ref.read(eventRepositoryProvider),
        );
      }
    } catch (e, st) {
      debugPrint('Reminder toggle notification sync failed: $e\n$st');
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

/// Forces a fresh permission read (e.g. after returning from system settings).
Future<bool> refreshNotificationPermission(WidgetRef ref) async {
  ref.invalidate(notificationPermissionProvider);
  return ref.read(notificationPermissionProvider.future);
}

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
  final dateKey = DateTimeFormats.formatDate(date);
  return repo.watchByDate(dateKey);
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

  Future<void> _syncReminder(Event event, {Event? previous}) async {
    try {
      if (!_ref.read(remindersEnabledProvider)) {
        await NotificationService.instance.cancelForEvent(event.id);
        return;
      }
      if (!ReminderPresets.hasReminder(event.reminderOffsetsSeconds)) {
        await NotificationService.instance.cancelForEvent(event.id);
        return;
      }
      await NotificationService.instance.scheduleForEvent(
        event,
        previousEvent: previous,
        skipPermissionCheck: true,
      );
    } catch (e, st) {
      debugPrint('Reminder sync failed for event ${event.id}: $e\n$st');
    }
  }

  Future<void> _cancelReminder(int eventId) async {
    try {
      await NotificationService.instance.cancelForEvent(eventId);
    } catch (e, st) {
      debugPrint('Reminder cancel failed for event $eventId: $e\n$st');
    }
  }

  Future<int> create(EventDraft draft) async {
    final id = await _ref.read(eventRepositoryProvider).create(draft);
    final event = await _ref.read(eventRepositoryProvider).getById(id);
    if (event != null) await _syncReminder(event);
    return id;
  }

  Future<void> update(Event event) async {
    final previous =
        await _ref.read(eventRepositoryProvider).getById(event.id);
    await _ref.read(eventRepositoryProvider).update(event);
    await _syncReminder(event, previous: previous);
  }

  Future<void> toggleTodo(int id, bool completed) async {
    await _ref.read(eventRepositoryProvider).toggleTodoComplete(
          id,
          completed: completed,
        );
    if (completed) {
      await _cancelReminder(id);
    } else {
      final event = await _ref.read(eventRepositoryProvider).getById(id);
      if (event != null) await _syncReminder(event);
    }
  }

  Future<void> toggleOccurrence(Event occurrence, bool completed) async {
    if (occurrence.isRepeatSeriesOccurrence) {
      await toggleTimelineOccurrence(occurrence, completed);
      return;
    }
    if (occurrence.isTodo) {
      await toggleTodo(occurrence.id, completed);
    } else {
      await toggleTimeline(occurrence.id, completed);
    }
  }

  Future<void> toggleTimelineOccurrence(Event occurrence, bool completed) async {
    await _ref.read(eventRepositoryProvider).toggleTimelineForOccurrence(
          occurrence,
          completed: completed,
        );
    if (completed) {
      await _cancelReminder(occurrence.id);
    } else {
      await _syncReminder(occurrence);
    }
  }

  Future<void> toggleTimeline(int id, bool completed) async {
    final event = await _ref.read(eventRepositoryProvider).getById(id);
    if (event == null) return;
    await toggleTimelineOccurrence(event, completed);
  }

  Future<void> updateWithScope(
    Event occurrence,
    Event updated,
    RepeatScope scope,
  ) async {
    final repo = _ref.read(eventRepositoryProvider);
    final previous = await repo.getById(occurrence.id);
    await repo.updateWithScope(occurrence, updated, scope);
    await _syncReminder(updated, previous: previous);
  }

  Future<Event> duplicate(int id) async {
    final event = await _ref.read(eventRepositoryProvider).duplicate(id);
    await _syncReminder(event);
    return event;
  }

  Future<void> delete(int id) async {
    await _ref.read(eventRepositoryProvider).delete(id);
    await NotificationService.instance.deleteEventReminders(id);
  }

  Future<void> deleteWithScope(Event event, RepeatScope scope) async {
    final repo = _ref.read(eventRepositoryProvider);
    if (scope == RepeatScope.all && event.repeatGroupId != null) {
      final rows =
          await repo.getEventsByRepeatGroup(event.repeatGroupId!);
      for (final row in rows) {
        await NotificationService.instance.deleteEventReminders(row.id);
      }
    } else {
      await NotificationService.instance.deleteEventReminders(event.id);
    }
    await repo.deleteWithScope(event, scope);
  }

  Future<void> batchDelete(Set<int> ids) async {
    if (ids.isEmpty) return;
    await _ref.read(eventRepositoryProvider).batchDelete(ids);
    for (final id in ids) {
      await NotificationService.instance.deleteEventReminders(id);
    }
  }

  Future<void> batchUpdateDate(Set<int> ids, String newDate) async {
    if (ids.isEmpty) return;
    await _ref.read(eventRepositoryProvider).batchUpdateDate(ids, newDate);
    if (!_ref.read(remindersEnabledProvider)) return;
    for (final id in ids) {
      final event = await _ref.read(eventRepositoryProvider).getById(id);
      if (event != null) await _syncReminder(event);
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
