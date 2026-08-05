import 'package:flutter/material.dart';

/// Task category: time-blocked schedule vs completable todo.
enum TaskType { schedule, todo }

enum RepeatType { oneTime, daily, weekly, monthly }

enum ReminderType {
  none,
  atTime,
  min5,
  min10,
  min15,
  min30,
  hour1,
}

enum FocusMode { pomodoro, stopwatch }

enum DeleteRepeatScope { onlyThis, thisAndFuture, all }

extension TaskTypeX on TaskType {
  String get storage => name;

  static TaskType fromStorage(String value) =>
      TaskType.values.firstWhere((e) => e.name == value, orElse: () => TaskType.schedule);
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

extension ReminderTypeX on ReminderType {
  String get storage => name;

  String get label => switch (this) {
        ReminderType.none => 'No Reminder',
        ReminderType.atTime => 'At Time',
        ReminderType.min5 => '5 min before',
        ReminderType.min10 => '10 min before',
        ReminderType.min15 => '15 min before',
        ReminderType.min30 => '30 min before',
        ReminderType.hour1 => '1 hour before',
      };

  Duration? get offset => switch (this) {
        ReminderType.none => null,
        ReminderType.atTime => Duration.zero,
        ReminderType.min5 => const Duration(minutes: 5),
        ReminderType.min10 => const Duration(minutes: 10),
        ReminderType.min15 => const Duration(minutes: 15),
        ReminderType.min30 => const Duration(minutes: 30),
        ReminderType.hour1 => const Duration(hours: 1),
      };

  static ReminderType fromStorage(String value) =>
      ReminderType.values.firstWhere((e) => e.name == value, orElse: () => ReminderType.none);
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
