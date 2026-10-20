import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/english_natural_language_parser.dart';
import 'package:soft_schedule/core/utils/natural_language_parser.dart';
import 'package:soft_schedule/core/utils/quick_add_form_bridge.dart';
import 'package:soft_schedule/models/enums.dart';

void main() {
  test('prefill afternoon deadline without date in text (zh)', () {
    const parser = ChineseNaturalLanguageParser();
    final parsed = parser.parse('下午三点截止', reference: DateTime(2026, 8, 9));
    final prefill = QuickAddPrefill.fromParsed(parsed: parsed);

    expect(prefill.todoTimeMode, TodoTimeMode.deadline);
    expect(prefill.deadline, const TimeOfDay(hour: 15, minute: 0));
    expect(prefill.date, isNull);
    expect(prefill.dateUnresolved, isTrue);
  });

  test('prefill afternoon deadline without date in text (en)', () {
    const parser = EnglishNaturalLanguageParser();
    final parsed = parser.parse(
      'Finish report due by 3 pm',
      reference: DateTime(2026, 8, 9),
    );
    final prefill = QuickAddPrefill.fromParsed(parsed: parsed);

    expect(prefill.todoTimeMode, TodoTimeMode.deadline);
    expect(prefill.deadline, const TimeOfDay(hour: 15, minute: 0));
    expect(prefill.date, isNull);
    expect(prefill.dateUnresolved, isTrue);
  });
}
