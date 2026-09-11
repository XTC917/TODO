import 'dart:io';

import 'package:timezone/timezone.dart' as tz;

import '../../database/event_repository.dart';
import '../../models/event.dart';
import '../../models/reminder_config.dart';
import '../config/app_config.dart';
import '../utils/repeat_expander.dart';
import 'reminder_constants.dart';
import 'reminder_log.dart';
import 'reminder_permissions.dart';
import 'reminder_scheduler.dart';

typedef ReminderBodyBuilder = String Function(int offsetSeconds);

/// Event-level reminder orchestration: schedule, cancel, reschedule.
class ReminderEngine {
  ReminderEngine({
    required ReminderPermissions permissions,
    required ReminderScheduler scheduler,
  })  : _permissions = permissions,
        _scheduler = scheduler;

  final ReminderPermissions _permissions;
  final ReminderScheduler _scheduler;

  bool remindersEnabled = true;
  ReminderBodyBuilder? bodyBuilder;

  Future<void> _tail = Future<void>.value();

  Future<T> _locked<T>(Future<T> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<bool> _ensureReady({int maxAttempts = 30}) async {
    if (_permissions.isReady) return true;
    for (var i = 0; i < maxAttempts; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (_permissions.isReady) return true;
    }
    return false;
  }

  Future<int> scheduleForEvent(
    Event event, {
    Event? previousEvent,
    bool skipPermissionCheck = false,
    List<Event>? seriesEvents,
  }) =>
      _locked(
        () => _scheduleForEventUnlocked(
          event,
          previousEvent: previousEvent,
          skipPermissionCheck: skipPermissionCheck,
          seriesEvents: seriesEvents,
        ),
      );

  Future<void> cancelForEvent(int eventId) =>
      _locked(() => _cancelForEventUnlocked(eventId));

  Future<void> deleteEventReminders(int eventId) => _locked(() async {
        reminderLog('delete eventId=$eventId');
        await _cancelForEventUnlocked(eventId);
      });

  Future<int> rescheduleAll(EventRepository repository) =>
      _locked(() => _rescheduleAllUnlocked(repository));

  Future<int> _scheduleForEventUnlocked(
    Event event, {
    Event? previousEvent,
    bool skipPermissionCheck = false,
    List<Event>? seriesEvents,
  }) async {
    if (!await _ensureReady()) {
      reminderLog('schedule eventId=${event.id} skipped — not initialized');
      return 0;
    }

    await _logUpdateIfNeeded(previousEvent, event);
    await _cancelForEventUnlocked(event.id);

    if (!remindersEnabled) return 0;
    if (event.isRepeatSkip) return 0;
    if (!ReminderPresets.hasReminder(event.reminderOffsetsSeconds)) return 0;
    if (event.isCompleted) return 0;

    if (!skipPermissionCheck &&
        !await _permissions.hasNotificationPermission()) {
      reminderLog(
        'schedule eventId=${event.id} skipped — notification permission denied',
      );
      return 0;
    }

    // Single exact/inexact decision per task: one platform check feeds both
    // the warning and every reminder of this task, so a transient `false`
    // mid-batch can no longer downgrade a single sibling to inexact.
    final exactGranted =
        !Platform.isAndroid || await _permissions.canScheduleExactAlarms();
    if (Platform.isAndroid && !exactGranted) {
      reminderLog(
        'schedule eventId=${event.id} warning — exact alarm not granted, '
        'background delivery may fail on some devices',
      );
    }

    final siblings = seriesEvents == null || seriesEvents.isEmpty
        ? [event]
        : seriesEvents;
    final sources = RepeatExpander.reminderSources(event, siblings);
    if (sources.isEmpty) {
      reminderLog('schedule eventId=${event.id} skipped — no upcoming occurrence');
      return 0;
    }

    // Single exact/inexact decision per schedule call so every reminder of
    // this task uses the same mode (fixes "one reminder late, others on
    // time" caused by per-reminder platform-check flapping mid-batch).
    final useExact = exactGranted;
    reminderLog(
      'schedule eventId=${event.id} useExact=$useExact '
      'occurrences=${sources.length}',
    );
    await _scheduler.ensureTimezone();
    var scheduled = 0;
    for (var occ = 0; occ < sources.length; occ++) {
      scheduled += await _scheduleOccurrenceUnlocked(
        sources[occ],
        occurrence: occ,
        useExact: useExact,
      );
    }

    if (scheduled > 0) {
      final pending = await _scheduler.pendingCount();
      reminderLog(
        'schedule eventId=${event.id} done scheduled=$scheduled '
        'occurrences=${sources.length} pending=$pending',
      );
    }

    return scheduled;
  }

  Future<int> _scheduleOccurrenceUnlocked(
    Event event, {
    required int occurrence,
    required bool useExact,
  }) async {
    if (event.isCompleted) return 0;
    final anchor = event.reminderAnchorDateTime;
    if (anchor == null) {
      reminderLog(
        'schedule eventId=${event.id} occ=$occurrence skipped — no anchor time',
      );
      return 0;
    }

    final now = tz.TZDateTime.now(tz.local);
    final scheduleCalledAt = DateTime.now();
    final offsets = [...event.reminderOffsetsSeconds]
      ..sort((a, b) => b.compareTo(a));

    var scheduled = 0;
    for (var i = 0; i < offsets.length && i < kMaxRemindersPerEvent; i++) {
      final offsetSeconds = offsets[i];
      final offset = ReminderPresets.toDuration(offsetSeconds);
      if (offset == null) continue;

      final triggerLocal = anchor.subtract(offset);
      final triggerTime = tz.TZDateTime.from(triggerLocal, tz.local);
      if (!triggerTime.isAfter(now)) {
        reminderLog(
          'schedule eventId=${event.id} occ=$occurrence date=${event.date} '
          'offset=${offsetSeconds}s skipped — trigger in past ($triggerTime)',
        );
        continue;
      }

      final notificationId = notificationIdForEvent(
        event.id,
        i,
        occurrence: occurrence,
      );
      final bodySuffix =
          bodyBuilder?.call(offsetSeconds) ?? _fallbackBodySuffix(offsetSeconds);
      final body = '${event.title}\n$bodySuffix';

      reminderLog(
        'schedule eventId=${event.id} occ=$occurrence date=${event.date} '
        'taskStart=$anchor offset=${offsetSeconds}s '
        'expectedTrigger=$triggerTime finalScheduled=$triggerTime '
        'reminderId=$i notificationId=$notificationId now=$now '
        'tz=${tz.local.name} useExact=$useExact apiCalledAt=$scheduleCalledAt',
      );

      final mode = await _scheduler.scheduleAt(
        notificationId: notificationId,
        title: AppConfig.appName,
        body: body,
        triggerTime: triggerTime,
        payload: '${ReminderConstants.eventPayloadPrefix}${event.id}',
        logContext:
            'eventId=${event.id} occ=$occurrence id=$notificationId',
        useExact: useExact,
      );
      if (mode != null) scheduled++;
    }
    return scheduled;
  }

  Future<void> _cancelForEventUnlocked(int eventId) async {
    if (!_permissions.isReady) return;
    for (var i = 0; i < kMaxRemindersPerEvent; i++) {
      await _scheduler.cancel(legacyNotificationIdForEvent(eventId, i));
    }
    final pending = await _scheduler.pendingIds();
    final stride = kMaxScheduledOccurrences * kMaxRemindersPerEvent;
    final start = eventId * stride;
    final end = start + stride;
    for (final id in pending) {
      if (id >= start && id < end) {
        await _scheduler.cancel(id);
      }
    }
  }

  Future<int> _rescheduleAllUnlocked(EventRepository repository) async {
    reminderLog('rescheduleAll() start');
    if (!await _ensureReady()) {
      reminderLog('rescheduleAll() skipped — not initialized');
      return 0;
    }

    if (!remindersEnabled) {
      await _scheduler.cancelAll();
      reminderLog('rescheduleAll() reminders disabled — cleared all');
      return 0;
    }

    final events = await repository.getAllEvents();
    await _scheduler.ensureTimezone();
    await _cancelOrphanNotifications(events);

    var total = 0;
    for (final event in events) {
      total += await _scheduleForEventUnlocked(
        event,
        skipPermissionCheck: true,
        seriesEvents: events,
      );
    }

    final pending = await _scheduler.pendingCount();
    reminderLog(
      'rescheduleAll() events=${events.length} scheduled=$total pending=$pending',
    );
    return total;
  }

  Future<void> _cancelOrphanNotifications(List<Event> events) async {
    final expected = _expectedNotificationIds(events);
    final pending = await _scheduler.pendingIds();
    for (final id in pending) {
      if (id == ReminderConstants.testNotificationId) continue;
      if (!expected.contains(id)) {
        await _scheduler.cancel(id);
        reminderLog('cancel orphan id=$id');
      }
    }
  }

  Set<int> _expectedNotificationIds(List<Event> events) {
    final expected = <int>{};
    if (!remindersEnabled) return expected;

    final now = tz.TZDateTime.now(tz.local);
    for (final event in events) {
      if (event.isRepeatSkip) continue;
      if (!ReminderPresets.hasReminder(event.reminderOffsetsSeconds)) continue;
      final sources = RepeatExpander.reminderSources(event, events);
      for (var occ = 0; occ < sources.length; occ++) {
        final source = sources[occ];
        if (source.isCompleted) continue;
        final anchor = source.reminderAnchorDateTime;
        if (anchor == null) continue;

        final offsets = [...source.reminderOffsetsSeconds]
          ..sort((a, b) => b.compareTo(a));
        for (var i = 0; i < offsets.length && i < kMaxRemindersPerEvent; i++) {
          final offset = ReminderPresets.toDuration(offsets[i]);
          if (offset == null) continue;
          final trigger = tz.TZDateTime.from(anchor.subtract(offset), tz.local);
          if (trigger.isAfter(now)) {
            expected.add(
              notificationIdForEvent(source.id, i, occurrence: occ),
            );
          }
        }
      }
    }
    return expected;
  }

  Future<void> _logUpdateIfNeeded(Event? previous, Event event) async {
    if (previous == null) return;
    final oldAnchor = previous.reminderAnchorDateTime;
    final newAnchor = event.reminderAnchorDateTime;
    final oldOffsets = previous.reminderOffsetsSeconds;
    final newOffsets = event.reminderOffsetsSeconds;
    if (oldAnchor != newAnchor ||
        oldOffsets.toString() != newOffsets.toString()) {
      reminderLog(
        'update eventId=${event.id} oldTime=$oldAnchor newTime=$newAnchor',
      );
    }
  }

  String _fallbackBodySuffix(int offsetSeconds) {
    if (offsetSeconds <= 0) return 'Starting now';
    final d = Duration(seconds: offsetSeconds);
    if (d.inDays > 0) return 'Starts in ${d.inDays}d';
    if (d.inHours > 0) return 'Starts in ${d.inHours}h ${d.inMinutes % 60}m';
    return 'Starts in ${d.inMinutes}m';
  }
}
