import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';

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
      if (picked.path == null) {
        throw StateError('Unable to read selected file.');
      }
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
