import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

const _channelId = 'soft_schedule_reminders';
const _channelName = 'Reminders';
const eventPayloadPrefix = 'event:';

typedef NotificationTapHandler = void Function(int eventId);

/// Schedules and cancels Android local notifications for events.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _remindersEnabled = true;
  NotificationTapHandler? _onTap;

  void configure({
    required bool remindersEnabled,
    NotificationTapHandler? onTap,
  }) {
    _remindersEnabled = remindersEnabled;
    _onTap = onTap;
  }

  set remindersEnabled(bool value) => _remindersEnabled = value;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _notificationTapBackground,
    );

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: 'Task reminders',
          importance: Importance.high,
        ),
      );
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _initialized = true;

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      _dispatchPayload(payload);
    }
  }

  @pragma('vm:entry-point')
  static void _notificationTapBackground(NotificationResponse response) {
    // Background isolate — navigation handled on next foreground resume.
  }

  void _handleNotificationResponse(NotificationResponse response) {
    _dispatchPayload(response.payload);
  }

  void _dispatchPayload(String? payload) {
    if (payload == null || !payload.startsWith(eventPayloadPrefix)) return;
    final id = int.tryParse(payload.substring(eventPayloadPrefix.length));
    if (id != null) _onTap?.call(id);
  }

  Future<bool> hasPermission() async {
    await initialize();
    if (!Platform.isAndroid) return true;
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await androidPlugin?.areNotificationsEnabled() ?? false;
  }

  Future<void> rescheduleAll(EventRepository repository) async {
    await initialize();
    if (!_remindersEnabled) {
      await cancelAll();
      return;
    }
    final rows = await repository.getAllEvents();
    for (final event in rows) {
      await scheduleForEvent(event);
    }
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Future<void> scheduleForEvent(Event event) async {
    await initialize();
    await cancelForEvent(event.id);

    if (!_remindersEnabled) return;
    if (event.reminderType == ReminderType.none) return;
    if (event.isCompleted) return;

    if (Platform.isAndroid) {
      final allowed = await hasPermission();
      if (!allowed) return;
    }

    final offset = event.reminderType.offset;
    if (offset == null) return;

    final anchor = event.reminderAnchorDateTime;
    if (anchor == null) return;

    final scheduledLocal = anchor.subtract(offset);
    final scheduled = _toLocalTz(scheduledLocal);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(now)) return;

    final body = event.note?.isNotEmpty == true
        ? event.note!
        : (event.isTodo ? 'Upcoming todo' : 'Upcoming schedule');

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Task reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
    );

    try {
      await _plugin.zonedSchedule(
        event.id,
        event.title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$eventPayloadPrefix${event.id}',
      );
    } catch (e) {
      debugPrint('Exact alarm failed, falling back: $e');
      await _plugin.zonedSchedule(
        event.id,
        event.title,
        body,
        scheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: '$eventPayloadPrefix${event.id}',
      );
    }
  }

  Future<void> cancelForEvent(int eventId) async {
    await _plugin.cancel(eventId);
  }

  tz.TZDateTime _toLocalTz(DateTime dt) {
    return tz.TZDateTime(
      tz.local,
      dt.year,
      dt.month,
      dt.day,
      dt.hour,
      dt.minute,
      dt.second,
    );
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Timezone setup failed: $e');
    }
  }
}

class DatabaseBackupService {
  DatabaseBackupService(this._db);

  final AppDatabase _db;

  Future<String?> exportDatabase() async {
    final source = await _db.databaseFile();
    if (!await source.exists()) throw StateError('Database file not found.');

    final bytes = await source.readAsBytes();
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final fileName = 'soft_schedule_backup_$stamp.sqlite';

    final savedPath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Database',
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: const ['sqlite', 'db'],
    );

    if (savedPath == null) return null;
    final out = File(savedPath);
    if (!await out.exists() || await out.length() == 0) {
      await out.writeAsBytes(bytes, flush: true);
    }
    return savedPath;
  }

  Future<void> importDatabase() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Database',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (picked.path == null) throw StateError('Unable to read selected file.');
      await _replaceDatabase(await File(picked.path!).readAsBytes());
      return;
    }
    await _replaceDatabase(bytes);
  }

  Future<void> _replaceDatabase(List<int> bytes) async {
    await _db.close();
    final dir = await getApplicationDocumentsDirectory();
    final target = File(p.join(dir.path, 'soft_schedule.sqlite'));
    if (await target.exists()) await target.delete();
    await target.writeAsBytes(bytes, flush: true);
  }
}
