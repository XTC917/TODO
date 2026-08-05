import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
/// Schedules and cancels Android local notifications for events.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(settings);

    if (Platform.isAndroid) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
      await androidPlugin?.requestExactAlarmsPermission();
    }

    _initialized = true;
  }

  Future<void> scheduleForEvent(Event event) async {
    await cancelForEvent(event.id);
    if (event.reminderType == ReminderType.none) return;

    final offset = event.reminderType.offset;
    if (offset == null) return;

    final scheduled = event.startDateTime.subtract(offset);
    if (scheduled.isBefore(DateTime.now())) return;

    await _plugin.zonedSchedule(
      event.id,
      event.title,
      event.note ?? 'Upcoming ${event.isTodo ? 'todo' : 'schedule'}',
      tz.TZDateTime.from(scheduled, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'soft_schedule_reminders',
          'Reminders',
          channelDescription: 'Task reminders',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelForEvent(int eventId) async {
    await _plugin.cancel(eventId);
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
      dialogTitle: '导出数据库',
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
      dialogTitle: '导入数据库',
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
