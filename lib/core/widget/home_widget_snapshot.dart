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

      final events = await eventRepo.watchByDate(dateKey).first;
      final allTodos = await eventRepo.watchAllTodos().first;
      final records = await focusRepo.watchByDate(dateKey).first;
      final datedToday =
          events.where((e) => e.showsOnHomeDate(dateKey)).toList();
      final undatedPending =
          allTodos.where((e) => !e.hasDate && !e.isCompleted).toList();
      final existingTodosJson =
          sharedPrefs.getString(HomeWidgetKeys.todosJson);
      final todos = _buildWidgetTodos(
        datedToday: datedToday,
        undatedPending: undatedPending,
        allTodos: allTodos,
        existingTodosJson: existingTodosJson,
        dropCompleted: dropCompletedFromWidget,
      );
      final todosAll = events.where((e) => e.isTodo).toList();
      final todoCompleted = todosAll.where((e) => e.isTodoDone()).length;
      final todoPending = allTodos.where((e) => !e.isCompleted).length;
      final focusSeconds =
          records.fold<int>(0, (sum, r) => sum + r.durationSeconds);

      final schedules = events.where((e) => e.isSchedule && e.hasDate).toList()
        ..sort((a, b) => a.timelineSortKey.compareTo(b.timelineSortKey));

      await HomeWidget.saveWidgetData<String>(HomeWidgetKeys.date, dateKey);
      await HomeWidget.saveWidgetData<int>(
        HomeWidgetKeys.todoDone,
        todoCompleted,
      );
      await HomeWidget.saveWidgetData<int>(
        HomeWidgetKeys.todoTotal,
        todosAll.length,
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.todosJson,
        jsonEncode(todos.take(6).map(_todoItem).toList()),
      );
      await HomeWidget.saveWidgetData<String>(
        HomeWidgetKeys.schedulesJson,
        jsonEncode(schedules.take(6).map(_scheduleItem).toList()),
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
        HomeWidgetKeys.labelTodoProgress,
        l10n.widgetTodoProgress(todoCompleted, todosAll.length),
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
    required List<Event> datedToday,
    required List<Event> undatedPending,
    required List<Event> allTodos,
    required String? existingTodosJson,
    required bool dropCompleted,
  }) {
    final byId = <int, Event>{
      for (final event in [...datedToday, ...allTodos]) event.id: event,
    };
    final ordered = <Event>[];
    final seen = <int>{};

    for (final id in _parseTodoIds(existingTodosJson)) {
      final event = byId[id];
      if (event == null) continue;
      if (dropCompleted && event.isCompleted) continue;
      if (seen.add(event.id)) ordered.add(event);
    }

    for (final event in [...datedToday, ...undatedPending]) {
      if (ordered.length >= 6) break;
      if (dropCompleted && event.isCompleted) continue;
      if (seen.add(event.id)) ordered.add(event);
    }

    return ordered.take(6).toList();
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

  static Map<String, Object?> _todoItem(Event event) => {
        'id': event.id,
        'title': event.title,
        'done': event.isCompleted,
      };

  static Map<String, String> _scheduleItem(Event event) {
    final time = event.startTime.isEmpty
        ? ''
        : event.endTime.isEmpty
            ? event.startTime
            : '${event.startTime}-${event.endTime}';
    return {
      'id': '${event.id}',
      'title': event.title,
      'time': time,
    };
  }
}

const _appLanguageKey = 'app_language';
