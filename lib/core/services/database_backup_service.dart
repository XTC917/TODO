import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../database/app_database.dart';

class DatabaseBackupService {
  DatabaseBackupService(this._db);

  final AppDatabase _db;

  /// SQLite magic header: "SQLite format 3\0"
  static final Uint8List sqliteMagicHeader = Uint8List.fromList(
    <int>[
      0x53, 0x51, 0x4c, 0x69, 0x74, 0x65, 0x20, 0x66, // SQLite f
      0x6f, 0x72, 0x6d, 0x61, 0x74, 0x20, 0x33, 0x00, // ormat 3\0
    ],
  );

  static Future<File> databaseFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, 'soft_schedule.sqlite'));
  }

  /// Returns true when [bytes] start with the SQLite database file header.
  static bool isSqliteDatabaseBytes(List<int> bytes) {
    if (bytes.length < sqliteMagicHeader.length) return false;
    for (var i = 0; i < sqliteMagicHeader.length; i++) {
      if (bytes[i] != sqliteMagicHeader[i]) return false;
    }
    return true;
  }

  static void ensureSqliteDatabaseBytes(List<int> bytes) {
    if (!isSqliteDatabaseBytes(bytes)) {
      throw StateError('Selected file is not a valid SQLite database.');
    }
  }

  /// Writes backup bytes to the app database file. Caller must close connections first.
  static Future<void> replaceDatabaseFile(List<int> bytes) async {
    ensureSqliteDatabaseBytes(bytes);
    final target = await databaseFilePath();
    final temp = File('${target.path}.importing');
    await temp.writeAsBytes(bytes, flush: true);
    if (await target.exists()) {
      await target.delete();
    }
    await temp.rename(target.path);
  }

  Future<String?> exportDatabase() async {
    // Merge any pending WAL pages into the main DB file before copying.
    await _db.customStatement('PRAGMA wal_checkpoint(FULL);');

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
    final List<int> resolved;
    if (bytes != null && bytes.isNotEmpty) {
      resolved = bytes;
    } else if (picked.path == null) {
      throw StateError('Unable to read selected file.');
    } else {
      resolved = await File(picked.path!).readAsBytes();
    }

    // Reject invalid files before the caller closes/replaces the live database.
    ensureSqliteDatabaseBytes(resolved);
    return resolved;
  }
}
