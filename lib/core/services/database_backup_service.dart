import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';

class DatabaseBackupService {
  DatabaseBackupService(this._db);

  final AppDatabase _db;

  static Future<File> databaseFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'soft_schedule.sqlite'));
  }

  /// Writes backup bytes to the app database file. Caller must close connections first.
  static Future<void> replaceDatabaseFile(List<int> bytes) async {
    final target = await databaseFilePath();
    final temp = File('${target.path}.importing');
    await temp.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);
  }

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

  /// Returns backup bytes when a file was picked, otherwise `null`.
  Future<List<int>?> pickDatabaseBytes() async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import Database',
      type: FileType.any,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final picked = result.files.single;
    final bytes = picked.bytes;
    if (bytes != null && bytes.isNotEmpty) return bytes;

    if (picked.path == null) {
      throw StateError('Unable to read selected file.');
    }
    return File(picked.path!).readAsBytes();
  }
}
