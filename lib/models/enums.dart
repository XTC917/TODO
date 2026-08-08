import 'package:flutter/material.dart';

/// Task category: fixed schedule vs completable todo.
enum TaskType { schedule, todo }

/// How a todo relates to time (only for [TaskType.todo]).
enum TodoTimeMode { timeBlock, deadline, noTime }

enum RepeatType { oneTime, daily, weekly, monthly }

enum FocusMode { pomodoro, stopwatch }

enum RepeatScope { onlyThis, thisAndFuture, all }

@Deprecated('Use RepeatScope')
typedef DeleteRepeatScope = RepeatScope;

extension TaskTypeX on TaskType {
  String get storage => name;

  String get label => switch (this) {
        TaskType.schedule => 'Schedule',
        TaskType.todo => 'Todo',
      };

  static TaskType fromStorage(String value) =>
      TaskType.values.firstWhere((e) => e.name == value, orElse: () => TaskType.todo);
}

extension TodoTimeModeX on TodoTimeMode {
  String get storage => name;

  String get label => switch (this) {
        TodoTimeMode.timeBlock => 'Time Block',
        TodoTimeMode.deadline => 'Deadline',
        TodoTimeMode.noTime => 'No Time',
      };

  static TodoTimeMode fromStorage(String value) => TodoTimeMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TodoTimeMode.timeBlock,
      );
}

extension RepeatTypeX on RepeatType {
  String get storage => name;

  String get label => switch (this) {
        RepeatType.oneTime => 'One Time',
        RepeatType.daily => 'Every Day',
        RepeatType.weekly => 'Every Week',
        RepeatType.monthly => 'Every Month',
      };

  static RepeatType fromStorage(String value) =>
      RepeatType.values.firstWhere((e) => e.name == value, orElse: () => RepeatType.oneTime);
}

extension FocusModeX on FocusMode {
  String get storage => name;

  String get label => switch (this) {
        FocusMode.pomodoro => 'Pomodoro',
        FocusMode.stopwatch => 'Stopwatch',
      };

  static FocusMode fromStorage(String value) =>
      FocusMode.values.firstWhere((e) => e.name == value, orElse: () => FocusMode.pomodoro);
}

/// Accent palette for Material 3 theming.
enum AccentColor {
  pink,
  purple,
  blue,
  green,
  orange,
  brown,
  teal,
}

extension AccentColorX on AccentColor {
  String get storage => name;

  String get label => switch (this) {
        AccentColor.pink => 'Pink',
        AccentColor.purple => 'Purple',
        AccentColor.blue => 'Blue',
        AccentColor.green => 'Green',
        AccentColor.orange => 'Orange',
        AccentColor.brown => 'Brown',
        AccentColor.teal => 'Teal',
      };

  Color get seed => switch (this) {
        AccentColor.pink => const Color(0xFFE8A0A0),
        AccentColor.purple => const Color(0xFFB39DDB),
        AccentColor.blue => const Color(0xFF90CAF9),
        AccentColor.green => const Color(0xFFA5D6A7),
        AccentColor.orange => const Color(0xFFFFCC80),
        AccentColor.brown => const Color(0xFFBCAAA4),
        AccentColor.teal => const Color(0xFF80CBC4),
      };

  static AccentColor fromStorage(String? value) =>
      AccentColor.values.firstWhere((e) => e.name == value, orElse: () => AccentColor.pink);
}
