import 'package:flutter/material.dart';

import '../../models/enums.dart';

/// Structured output from local natural-language parsing (no AI / network).
class ParsedTask {
  const ParsedTask({
    required this.rawInput,
    required this.title,
    this.date,
    this.startTime,
    this.endTime,
    required this.taskType,
    required this.todoTimeMode,
    this.reminderOffsetsSeconds = const [],
  });

  final String rawInput;
  final String title;
  final DateTime? date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final TaskType taskType;
  final TodoTimeMode todoTimeMode;
  /// Seconds before [Event.reminderAnchorDateTime] (start or deadline).
  final List<int> reminderOffsetsSeconds;

  bool get hasTimeRange => startTime != null && endTime != null;
  bool get hasSpecificTime => startTime != null;
  bool get hasReminders => reminderOffsetsSeconds.isNotEmpty;
}
