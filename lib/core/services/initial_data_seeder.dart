import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../database/event_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../theme/app_colors.dart';
import '../utils/date_time_formats.dart';

const initialDataSeededKey = 'initial_data_seeded_v2';
const expectedInitialEventCount = 9;
const onboardingWidgetTodoMigrationKey = 'onboarding_widget_todo_v1';

const _supportedSeedLocales = [
  Locale('en'),
  Locale('zh'),
  Locale('ko'),
];

const _legacyWelcomeFragments = [
  'Welcome to JUJU Schedule',
  '欢迎使用 JUJU Schedule',
  'JUJU Schedule에 오신',
  '欢迎使用 JUJU日常',
  'JUJU 일정에 오신',
];

List<EventDraft> buildInitialDrafts(AppLocalizations l10n) {
  final today = DateTimeFormats.formatDate(DateTime.now());
  final colors = AppColors.eventPalette;

  String colorAt(int index) => AppColors.toHex(colors[index % colors.length]);

  return [
    EventDraft(
      title: l10n.initialTimelineWelcomeTitle,
      date: today,
      startTime: '09:00',
      endTime: '09:30',
      color: colorAt(0),
      taskType: TaskType.schedule,
      todoTimeMode: TodoTimeMode.timeBlock,
    ),
    EventDraft(
      title: l10n.initialTimelineAddTitle,
      date: today,
      startTime: '10:00',
      endTime: '10:30',
      color: colorAt(1),
      taskType: TaskType.schedule,
      todoTimeMode: TodoTimeMode.timeBlock,
    ),
    EventDraft(
      title: l10n.initialTimelineEditTitle,
      date: today,
      startTime: '11:00',
      endTime: '11:30',
      color: colorAt(2),
      taskType: TaskType.schedule,
      todoTimeMode: TodoTimeMode.timeBlock,
    ),
    EventDraft(
      title: l10n.initialTimelineReminderTitle,
      date: today,
      startTime: '14:00',
      endTime: '14:30',
      color: colorAt(3),
      taskType: TaskType.schedule,
      todoTimeMode: TodoTimeMode.timeBlock,
      reminderOffsetsSeconds: const [0, 300],
    ),
    EventDraft(
      title: l10n.initialTimelineFocusTitle,
      date: today,
      startTime: '15:00',
      endTime: '15:30',
      color: colorAt(4),
      taskType: TaskType.schedule,
      todoTimeMode: TodoTimeMode.timeBlock,
    ),
    EventDraft(
      title: l10n.initialTodoThemeTitle,
      date: '',
      startTime: '',
      endTime: '',
      color: colorAt(5),
      taskType: TaskType.todo,
      todoTimeMode: TodoTimeMode.noTime,
    ),
    EventDraft(
      title: l10n.initialTodoLanguageTitle,
      date: '',
      startTime: '',
      endTime: '',
      color: colorAt(6),
      taskType: TaskType.todo,
      todoTimeMode: TodoTimeMode.noTime,
    ),
    EventDraft(
      title: l10n.initialTodoStatsTitle,
      date: '',
      startTime: '',
      endTime: '',
      color: colorAt(7),
      taskType: TaskType.todo,
      todoTimeMode: TodoTimeMode.noTime,
    ),
    EventDraft(
      title: l10n.initialTodoWidgetTitle,
      date: '',
      startTime: '',
      endTime: '',
      color: colorAt(8),
      taskType: TaskType.todo,
      todoTimeMode: TodoTimeMode.noTime,
    ),
  ];
}

List<Set<String>> _onboardingTitlesBySlot() {
  final bySlot =
      List.generate(expectedInitialEventCount, (_) => <String>{});

  for (final locale in _supportedSeedLocales) {
    final drafts = buildInitialDrafts(lookupAppLocalizations(locale));
    for (var i = 0; i < drafts.length; i++) {
      bySlot[i].add(drafts[i].title);
    }
  }

  for (final legacy in _legacyWelcomeFragments) {
    bySlot[0].add(legacy);
    bySlot[0].add('👋 $legacy');
    bySlot[0].add('$legacy 👋');
  }

  return bySlot;
}

Set<String> _allKnownOnboardingTitles() {
  return _onboardingTitlesBySlot().expand((titles) => titles).toSet();
}

int? _onboardingSlotIndex(String title, List<Set<String>> titlesBySlot) {
  final normalized = title.trim();
  for (var i = 0; i < titlesBySlot.length; i++) {
    if (titlesBySlot[i].contains(normalized)) return i;
  }
  if (_legacyWelcomeFragments.any(normalized.contains)) return 0;
  return null;
}

Map<int, Event>? _matchOnboardingEvents(
  List<Event> events,
  List<Set<String>> titlesBySlot,
) {
  final matched = <int, Event>{};
  for (final event in events) {
    final slot = _onboardingSlotIndex(event.title, titlesBySlot);
    if (slot == null || matched.containsKey(slot)) continue;
    matched[slot] = event;
  }
  return matched.length == expectedInitialEventCount ? matched : null;
}

bool _looksLikeOnboardingEvent(Event event, Set<String> knownTitles) {
  final title = event.title.trim();
  if (knownTitles.contains(title)) return true;
  return _legacyWelcomeFragments.any(title.contains);
}

bool _isIncompleteOnboarding(List<Event> events, Set<String> knownTitles) {
  if (events.isEmpty || events.length >= expectedInitialEventCount) {
    return false;
  }
  return events.every((event) => _looksLikeOnboardingEvent(event, knownTitles));
}

/// Inserts starter events once on first launch when the database is empty.
class InitialDataSeeder {
  InitialDataSeeder._();

  static Future<void> seedIfFirstLaunch({
    required SharedPreferences prefs,
    required EventRepository repo,
    required AppLocalizations l10n,
  }) async {
    await _cleanupLegacyPrefs(prefs);

    final knownTitles = _allKnownOnboardingTitles();
    var existing = await repo.getAllEvents();
    final markedSeeded = prefs.getBool(initialDataSeededKey) == true;

    if (markedSeeded && !_isIncompleteOnboarding(existing, knownTitles)) {
      return;
    }

    if (_isIncompleteOnboarding(existing, knownTitles)) {
      for (final event in existing) {
        await repo.delete(event.id);
      }
      existing = await repo.getAllEvents();
    }

    if (existing.isNotEmpty) {
      await prefs.setBool(initialDataSeededKey, true);
      return;
    }

    await _seedAll(repo, l10n);
    await prefs.setBool(initialDataSeededKey, true);
  }

  /// Adds the widget onboarding todo for installs that still have the 8-item set.
  static Future<void> ensureWidgetOnboardingTodo({
    required SharedPreferences prefs,
    required EventRepository repo,
    required AppLocalizations l10n,
  }) async {
    if (prefs.getBool(onboardingWidgetTodoMigrationKey) == true) return;

    final titlesBySlot = _onboardingTitlesBySlot();
    final slot8Titles = titlesBySlot[8];
    final events = await repo.getAllEvents();

    if (events.any((e) => slot8Titles.contains(e.title.trim()))) {
      await prefs.setBool(onboardingWidgetTodoMigrationKey, true);
      return;
    }

    final matched8 = <int, Event>{};
    for (final event in events) {
      for (var i = 0; i < 8; i++) {
        if (titlesBySlot[i].contains(event.title.trim())) {
          matched8[i] = event;
          break;
        }
      }
    }
    if (matched8.length != 8) {
      await prefs.setBool(onboardingWidgetTodoMigrationKey, true);
      return;
    }

    await repo.create(buildInitialDrafts(l10n)[8]);
    await prefs.setBool(onboardingWidgetTodoMigrationKey, true);
  }

  /// Updates starter event titles when the app language changes.
  static Future<void> syncOnboardingLanguage({
    required EventRepository repo,
    required AppLocalizations l10n,
  }) async {
    final titlesBySlot = _onboardingTitlesBySlot();
    final events = await repo.getAllEvents();
    final matched = _matchOnboardingEvents(events, titlesBySlot);
    if (matched == null) return;

    final drafts = buildInitialDrafts(l10n);
    for (final entry in matched.entries) {
      final event = entry.value;
      final newTitle = drafts[entry.key].title;
      if (event.title == newTitle) continue;
      await repo.update(event.copyWith(title: newTitle));
    }
  }

  static Future<void> _seedAll(
    EventRepository repo,
    AppLocalizations l10n,
  ) async {
    final drafts = buildInitialDrafts(l10n);
    final createdIds = <int>[];
    try {
      for (final draft in drafts) {
        createdIds.add(await repo.create(draft));
      }
    } catch (e) {
      for (final id in createdIds) {
        try {
          await repo.delete(id);
        } catch (_) {}
      }
      rethrow;
    }
  }

  static Future<void> _cleanupLegacyPrefs(SharedPreferences prefs) async {
    await prefs.remove('show_sample_data');
    await prefs.remove('demo_event_ids');
    await prefs.remove('onboarding_seeded_v2');
    await prefs.remove('onboarding_seeded_v3');
    await prefs.remove('initial_data_seeded');
  }
}
