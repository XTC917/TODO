import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

/// SharedPreferences keys embedded in database exports (single-file backup).
class AppSettingsBackupService {
  AppSettingsBackupService(this._prefs);

  final SharedPreferences _prefs;

  static const backupVersion = 1;
  static const _tableName = '_app_settings_backup';

  static const _keys = [
    'theme_mode',
    'accent_color',
    'bg_mode',
    'bg_custom_light',
    'bg_custom_dark',
    'app_language',
    'focus_countdown_presets',
  ];

  Map<String, dynamic> exportMap() {
    final map = <String, dynamic>{'v': backupVersion};
    for (final key in _keys) {
      final value = _read(key);
      if (value != null) {
        map[key] = value;
      }
    }
    return map;
  }

  Object? _read(String key) {
    return switch (key) {
      'theme_mode' => _prefs.getString(key),
      'accent_color' => _prefs.getString(key),
      'bg_mode' => _prefs.getString(key),
      'bg_custom_light' => _prefs.getString(key),
      'bg_custom_dark' => _prefs.getString(key),
      'app_language' => _prefs.getString(key),
      'focus_countdown_presets' => _prefs.getString(key),
      _ => null,
    };
  }

  Future<void> importMap(Map<String, dynamic> map) async {
    final version = map['v'];
    if (version is! num || version.toInt() != backupVersion) {
      throw StateError('Unsupported settings backup version.');
    }
    for (final key in _keys) {
      if (!map.containsKey(key)) continue;
      final value = map[key];
      if (value is String) {
        await _prefs.setString(key, value);
      } else if (value is bool) {
        await _prefs.setBool(key, value);
      } else if (value is num) {
        await _prefs.setInt(key, value.toInt());
      }
    }
  }

  /// Copies [source], embeds settings, and returns bytes for export.
  Future<List<int>> embedSettingsInDatabaseCopy(File source) async {
    final tempDir = await Directory.systemTemp.createTemp('juju_export_');
    final temp = File(p.join(tempDir.path, 'backup.sqlite'));
    try {
      await source.copy(temp.path);
      _writeEmbeddedSettings(temp, exportMap());
      return await temp.readAsBytes();
    } finally {
      await tempDir.delete(recursive: true);
    }
  }

  static String sidecarPathFor(String sqlitePath) {
    return p.join(
      p.dirname(sqlitePath),
      '${p.basenameWithoutExtension(sqlitePath)}.settings.json',
    );
  }

  /// Legacy desktop export: companion JSON next to the sqlite file.
  Future<void> writeSidecar(String sqlitePath) async {
    final file = File(sidecarPathFor(sqlitePath));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportMap()),
      flush: true,
    );
  }

  /// Reads embedded settings from a database file, applies them, and drops the table.
  static Future<bool> tryImportEmbedded(
    SharedPreferences prefs,
    File databaseFile,
  ) async {
    final map = _readEmbeddedSettings(databaseFile);
    if (map == null) return false;
    await AppSettingsBackupService(prefs).importMap(map);
    _removeEmbeddedSettings(databaseFile);
    return true;
  }

  /// Returns true when a companion settings file was found and applied.
  static Future<bool> tryImportSidecar(
    SharedPreferences prefs,
    String sqlitePath,
  ) async {
    final file = File(sidecarPathFor(sqlitePath));
    if (!await file.exists()) return false;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw StateError('Invalid settings backup file.');
    }
    await AppSettingsBackupService(prefs).importMap(decoded);
    return true;
  }

  static void _writeEmbeddedSettings(
    File databaseFile,
    Map<String, dynamic> map,
  ) {
    final db = sqlite3.open(databaseFile.path);
    try {
      db.execute(
        'CREATE TABLE IF NOT EXISTS $_tableName (payload TEXT NOT NULL)',
      );
      db.execute('DELETE FROM $_tableName');
      final stmt = db.prepare('INSERT INTO $_tableName (payload) VALUES (?)');
      try {
        stmt.execute([jsonEncode(map)]);
      } finally {
        stmt.dispose();
      }
    } finally {
      db.dispose();
    }
  }

  static Map<String, dynamic>? _readEmbeddedSettings(File databaseFile) {
    if (!databaseFile.existsSync()) return null;
    final db = sqlite3.open(databaseFile.path);
    try {
      final tables = db.select(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        [_tableName],
      );
      if (tables.isEmpty) return null;

      final rows = db.select('SELECT payload FROM $_tableName LIMIT 1');
      if (rows.isEmpty) return null;

      final decoded = jsonDecode(rows.first.columnAt(0) as String);
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Invalid embedded settings payload.');
      }
      return decoded;
    } finally {
      db.dispose();
    }
  }

  static void _removeEmbeddedSettings(File databaseFile) {
    if (!databaseFile.existsSync()) return;
    final db = sqlite3.open(databaseFile.path);
    try {
      db.execute('DROP TABLE IF EXISTS $_tableName');
    } finally {
      db.dispose();
    }
  }
}
