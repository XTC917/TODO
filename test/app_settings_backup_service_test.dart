import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/services/app_settings_backup_service.dart';
import 'package:sqlite3/sqlite3.dart';

File _createMinimalDatabase(Directory dir) {
  final dbFile = File('${dir.path}/test.sqlite');
  final db = sqlite3.open(dbFile.path);
  try {
    db.execute('CREATE TABLE sample (id INTEGER PRIMARY KEY)');
  } finally {
    db.dispose();
  }
  return dbFile;
}

void main() {
  test('settings backup roundtrip restores theme and preset keys', () async {
    SharedPreferences.setMockInitialValues({
      'theme_mode': 'dark',
      'accent_color': 'custom:#AABBCC',
      'bg_mode': 'custom',
      'bg_custom_light': '#112233',
      'bg_custom_dark': '#445566',
      'app_language': 'zh',
      'focus_countdown_presets': jsonEncode([900, 1500, 1800]),
    });
    final prefs = await SharedPreferences.getInstance();
    final service = AppSettingsBackupService(prefs);

    final exported = service.exportMap();
    await prefs.clear();

    await AppSettingsBackupService(prefs).importMap(exported);

    expect(prefs.getString('theme_mode'), 'dark');
    expect(prefs.getString('accent_color'), 'custom:#AABBCC');
    expect(prefs.getString('bg_mode'), 'custom');
    expect(prefs.getString('bg_custom_light'), '#112233');
    expect(prefs.getString('bg_custom_dark'), '#445566');
    expect(prefs.getString('app_language'), 'zh');
    expect(
      prefs.getString('focus_countdown_presets'),
      jsonEncode([900, 1500, 1800]),
    );
  });

  test('embedded settings roundtrip inside sqlite export file', () async {
    final tempDir = await Directory.systemTemp.createTemp('settings_backup_');
    try {
      final source = _createMinimalDatabase(tempDir);
      SharedPreferences.setMockInitialValues({
        'theme_mode': 'light',
        'focus_countdown_presets': jsonEncode([1200, 2400]),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = AppSettingsBackupService(prefs);

      final bytes = await service.embedSettingsInDatabaseCopy(source);
      final exportFile = File('${tempDir.path}/export.sqlite');
      await exportFile.writeAsBytes(bytes);

      await prefs.clear();
      final imported = await AppSettingsBackupService.tryImportEmbedded(
        prefs,
        exportFile,
      );

      expect(imported, isTrue);
      expect(prefs.getString('theme_mode'), 'light');
      expect(
        prefs.getString('focus_countdown_presets'),
        jsonEncode([1200, 2400]),
      );

      final db = sqlite3.open(exportFile.path);
      try {
        final rows = db.select(
          "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
          ['_app_settings_backup'],
        );
        expect(rows, isEmpty);
      } finally {
        db.dispose();
      }
    } finally {
      await tempDir.delete(recursive: true);
    }
  });
}
