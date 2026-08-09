import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/natural_language_parser.dart';
import 'package:soft_schedule/core/utils/quick_add_form_bridge.dart';
import 'package:soft_schedule/models/enums.dart';

void main() {
  const parser = ChineseNaturalLanguageParser();
  final fallbackDate = DateTime(2026, 8, 10);

  test('prefill afternoon deadline without date in text', () {
    final parsed = parser.parse('下午三点截止', reference: DateTime(2026, 8, 9));
    final prefill = QuickAddPrefill.fromParsed(
      parsed: parsed,
      fallbackDate: fallbackDate,
    );

    expect(prefill.todoTimeMode, TodoTimeMode.deadline);
    expect(prefill.deadline, const TimeOfDay(hour: 15, minute: 0));
    expect(prefill.date, fallbackDate);
  });
}
