import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule_rules/core/utils/date_time_formats.dart';
import 'package:soft_schedule_rules/core/utils/quick_add_parser.dart';

void main() {
  test('run rule parser over experiment dataset', () {
    final repoRoot = _findRepoRoot(Directory.current) ?? Directory.current;
    final casesFile = File(
      '${repoRoot.path}/experiments/local_ai/datasets/cases.jsonl',
    );
    final lines = casesFile.readAsLinesSync().where((l) => l.trim().isNotEmpty);

    final outputs = <Map<String, dynamic>>[];
    for (final line in lines) {
      final c = jsonDecode(line) as Map<String, dynamic>;
      final ref = DateTime.parse('${c['referenceDate']} 00:00:00');
      final parsed = parseQuickAddInput(
        c['input'] as String,
        language: (c['input'] as String).contains(RegExp(r'[一-鿿]'))
            ? QuickAddParserLanguage.zh
            : QuickAddParserLanguage.en,
        reference: ref,
      );
      outputs.add({
        'id': c['id'],
        'group': c['group'],
        'input': c['input'],
        'expected': c['expected'],
        'parsed': {
          'title': parsed.title,
          'date': parsed.date == null
              ? null
              : DateTimeFormats.formatDate(parsed.date!),
          'startTime': parsed.startTime == null
              ? null
              : _clock(parsed.startTime!),
          'endTime': parsed.endTime == null
              ? null
              : _clock(parsed.endTime!),
          'taskType': parsed.taskType.name,
          'todoTimeMode': parsed.todoTimeMode.name,
          'reminderOffsetsSeconds': parsed.reminderOffsetsSeconds,
          'note': parsed.note,
        },
        'json_ok': true,
        'elapsed_ms': 0,
      });
    }

    final outDir = Directory('${repoRoot.path}/experiments/local_ai/out')
      ..createSync(recursive: true);
    File('${outDir.path}/pc_rules_full.json').writeAsStringSync(
      jsonEncode({
        'model': 'rules',
        'license': 'project',
        'smoke': false,
        'cases': outputs,
      }),
      flush: true,
    );
  });
}

String _clock(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

Directory? _findRepoRoot(Directory start) {
  var dir = start;
  for (var i = 0; i < 8; i++) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    dir = dir.parent;
  }
  return null;
}
