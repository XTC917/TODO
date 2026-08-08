import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/services/database_backup_service.dart';

void main() {
  group('DatabaseBackupService.isSqliteDatabaseBytes', () {
    test('accepts SQLite format 3 header', () {
      final bytes = List<int>.from(DatabaseBackupService.sqliteMagicHeader)
        ..addAll(List<int>.filled(48, 0));
      expect(DatabaseBackupService.isSqliteDatabaseBytes(bytes), isTrue);
    });

    test('rejects empty / short / non-sqlite bytes', () {
      expect(DatabaseBackupService.isSqliteDatabaseBytes(const []), isFalse);
      expect(
        DatabaseBackupService.isSqliteDatabaseBytes(List<int>.filled(8, 0)),
        isFalse,
      );
      expect(
        DatabaseBackupService.isSqliteDatabaseBytes(
          'not a sqlite file!!!!'.codeUnits,
        ),
        isFalse,
      );
    });

    test('ensureSqliteDatabaseBytes throws for invalid input', () {
      expect(
        () => DatabaseBackupService.ensureSqliteDatabaseBytes(const [1, 2, 3]),
        throwsA(isA<StateError>()),
      );
    });
  });
}
