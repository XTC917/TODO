import 'package:flutter/material.dart';

import '../../models/enums.dart';

/// Shared structured result for rule-based parsing and future on-device LLM
/// extraction. Both paths should map onto this shape before touching the UI.
class ParsedTask {
  const ParsedTask({
    required this.rawInput,
    required this.title,
    this.date,
    this.startTime,
    this.endTime,
    this.note,
    required this.taskType,
    required this.todoTimeMode,
    this.reminderOffsetsSeconds = const [],
  });

  final String rawInput;
  final String title;
  final DateTime? date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;

  /// Note / location extracted from expressions such as "备注：301教室".
  final String? note;
  final TaskType taskType;
  final TodoTimeMode todoTimeMode;

  /// Seconds before [Event.reminderAnchorDateTime] (start or deadline).
  final List<int> reminderOffsetsSeconds;

  bool get hasTimeRange => startTime != null && endTime != null;
  bool get hasSpecificTime => startTime != null;
  bool get hasReminders => reminderOffsetsSeconds.isNotEmpty;

  /// A time or reminder was understood but no date was given. The UI must ask
  /// the user to confirm a date instead of falling back to today silently.
  bool get needsDateConfirmation =>
      date == null && (startTime != null || endTime != null || hasReminders);
}
