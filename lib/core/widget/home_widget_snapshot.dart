import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import '../../database/focus_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import '../theme/app_colors.dart';
import '../theme/theme_palette.dart';
import '../utils/date_time_formats.dart';
import '../utils/repeat_expander.dart';
import 'home_widget_keys.dart';

/// Writes widget snapshot data without Riverpod (for background isolate too).
class HomeWidgetSnapshotWriter {
  HomeWidgetSnapshotWriter._();

  static Future<void> syncFromDatabase({
    SharedPreferences? prefs,
    bool dropCompletedFromWidget = false,
  }) async {
    WidgetsFlutterBinding.ensureInitialized();
    final sharedPrefs = prefs ?? await SharedPreferences.getInstance();
    final db = AppDatabase();
    try {
      final eventRepo = EventRepository(db);
      final focusRepo = FocusRepository(db);
      final today = DateTimeFormats.dateOnly(DateTime.now());
      final dateKey = DateTimeFormats.formatDate(today);
      final language = _readLanguage(sharedPrefs);
      final l10n = lookupAppLocalizations(resolveAppLocale(language));
      final palette = ThemePalette.fromPrefs(sharedPrefs);

      final allTodos = await eventRepo.watchAllTodos().first;
      final records = await focusRepo.watchByDate(dateKey).first;
      final existingTodosJson =
          sharedPrefs.getString(HomeWidgetKeys.todosJson);
      final todos = _buildWidgetTodos(
        allTodos: allTodos,
        existingTodosJson: existingTodosJson,
        dropCompleted: dropCompletedFromWidget,
      );
      final todoPending = allTodos.where((e) => !e.isCompleted).length;
      final focusSeconds =
          records.fold<int>(0, (sum, r) => sum + r.durationSeconds);

      final allEvents = await eventRepo.getAllEvents();
      final schedules = _buildWidgetSchedules(
        allEvents: allEvents,
        now: DateTime.now(),
      );

      await HomeWidget.saveWidgetData<String>(HomeWidgetKeys.date, dateKey);
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.todosJson,
        jsonEncode(todos.take(6).map(_todoItem).toList()),
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.schedulesJson,
        jsonEncode(schedules.take(6).map((e) => _scheduleItem(e, dateKey)).toList()),
      );
      await HomeWidget.saveWidgetData<int>(
        HomeWidgetKeys.focusSeconds,
        focusSeconds,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.accentHex,
        AppColors.toHex(palette.seedColor),
      );

      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelTodoTitle,
        l10n.widgetTodoTitle,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelScheduleTitle,
        l10n.widgetScheduleTitle,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelFocusTitle,
        l10n.widgetFocusTitle,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelStartFocus,
        l10n.widgetStartFocus,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelEmpty,
        l10n.widgetEmpty,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelFocusDuration,
        l10n.focusMinutes(focusSeconds ~/ 60),
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelOpenFocus,
        l10n.widgetOpenFocus,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.labelFocusPending,
        l10n.widgetFocusPending(todoPending),
      );

      await Future.wait([
        HomeWidget.updateWidget(
          qualifiedAndroidName: HomeWidgetKeys.androidTodoReceiver,
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName: HomeWidgetKeys.androidTodoCompactReceiver,
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName: HomeWidgetKeys.androidScheduleReceiver,
        ),
        HomeWidget.updateWidget(
          qualifiedAndroidName: HomeWidgetKeys.androidFocusReceiver,
        ),
      ]);
    } finally {
      await db.close();
    }
  }

  static AppLanguage _readLanguage(SharedPreferences prefs) {
    return AppLanguage.values.firstWhere(
      (language) => language.name == prefs.getString(_appLanguageKey),
      orElse: () => AppLanguage.system,
    );
  }

  static List<Event> _buildWidgetTodos({
    required List<Event> allTodos,
    required String? existingTodosJson,
    required bool dropCompleted,
  }) {
    final pending =
        allTodos.where((event) => event.isTodo && !event.isCompleted).toList()
          ..sort(_compareWidgetTodos);

    if (dropCompleted) {
      final byId = {for (final event in pending) event.id: event};
      final ordered = <Event>[];
      final seen = <int>{};
      for (final id in _parseTodoIds(existingTodosJson)) {
        final event = byId[id];
        if (event == null) continue;
        if (seen.add(event.id)) ordered.add(event);
      }
      for (final event in pending) {
        if (ordered.length >= 6) break;
        if (seen.add(event.id)) ordered.add(event);
      }
      return ordered.take(6).toList();
    }

    return pending.take(6).toList();
  }

  /// Long-term (no date) first, then nearest calendar date ascending.
  static int _compareWidgetTodos(Event a, Event b) {
    final aUndated = !a.hasDate;
    final bUndated = !b.hasDate;
    if (aUndated != bUndated) {
      return aUndated ? -1 : 1;
    }
    if (aUndated && bUndated) {
      return a.title.compareTo(b.title);
    }
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.startTime.compareTo(b.startTime);
  }

  static List<Event> _buildWidgetSchedules({
    required List<Event> allEvents,
    required DateTime now,
  }) {
    final todayKey = DateTimeFormats.formatDate(now);
    final start = DateTimeFormats.parseDate(todayKey);
    final end = start.add(const Duration(days: 365));
    final expanded = RepeatExpander.expandForRange(allEvents, start, end);

    final schedules = expanded
        .where(
          (event) =>
              event.isSchedule &&
              event.hasDate &&
              !event.isCompleted &&
              _isScheduleUpcoming(event, now),
        )
        .toList()
      ..sort(_compareWidgetSchedules);
    return schedules.take(6).toList();
  }

  /// Schedule is shown only while its time slot has not ended yet.
  static bool _isScheduleUpcoming(Event event, DateTime now) {
    if (event.endTime.isNotEmpty) {
      return event.endDateTime.isAfter(now);
    }
    if (event.startTime.isNotEmpty) {
      return event.startDateTime.isAfter(now);
    }
    final day = DateTimeFormats.parseDate(event.date);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return endOfDay.isAfter(now);
  }

  static int _compareWidgetSchedules(Event a, Event b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.startTime.compareTo(b.startTime);
  }

  static List<int> _parseTodoIds(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final array = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in array)
          if (item is Map && item['id'] is int) item['id'] as int,
      ];
    } catch (_) {
      return const [];
    }
  }

  static Map<String, Object?> _todoItem(Event event) {
    final title = event.hasDate
        ? '${DateTimeFormats.formatMonthDay(DateTimeFormats.parseDate(event.date))} ${event.title}'
        : event.title;
    return {
      'id': event.id,
      'title': title,
      'done': event.isCompleted,
    };
  }

  static Map<String, String> _scheduleItem(Event event, String todayKey) {
    final dateLabel = event.date == todayKey
        ? ''
        : '${DateTimeFormats.formatMonthDay(DateTimeFormats.parseDate(event.date))} ';
    final time = event.startTime.isEmpty
        ? ''
        : event.endTime.isEmpty
            ? event.startTime
            : '${event.startTime}-${event.endTime}';
    return {
      'id': '${event.id}',
      'title': event.title,
      'time': '$dateLabel$time'.trim(),
    };
  }
}

const _appLanguageKey = 'app_language';
