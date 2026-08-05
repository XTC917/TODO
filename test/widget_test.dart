import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/date_time_formats.dart';

void main() {
  test('formatDate returns yyyy-MM-dd', () {
    final date = DateTime(2026, 8, 4);
    expect(DateTimeFormats.formatDate(date), '2026-08-04');
  });
}
