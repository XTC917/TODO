import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

class DateTimeFormats {
  DateTimeFormats._();

  static final weekday = DateFormat('EEEE');
  static final shortWeekday = DateFormat('EEE');
  static final ymd = DateFormat('yyyy-MM-dd');
  static final displayDate = DateFormat('yyyy-MM-dd');
  static final monthDay = DateFormat('MM/dd');
  static final sectionDate = DateFormat('yyyy.MM.dd');
  static final hm = DateFormat('HH:mm');
  static final hms = DateFormat('HH:mm:ss');

  static String formatDate(DateTime date) => ymd.format(date);

  static String formatWeekday(DateTime date) => weekday.format(date);

  static String formatHeader(DateTime date, Locale locale) {
    final code = switch (locale.languageCode) {
      'zh' => 'zh_CN',
      'ko' => 'ko_KR',
      _ => 'en_US',
    };
    final pattern = switch (locale.languageCode) {
      'zh' => 'M月d日 · EEEE',
      'ko' => 'M월 d일 · EEEE',
      _ => 'MMM d · EEEE',
    };
    return DateFormat(pattern, code).format(date);
  }

  static String formatMonthDay(DateTime date) => monthDay.format(date);

  static String formatTime(DateTime time) => hm.format(time);

  static String formatTimeOfDay(DateTime time) => hm.format(time);

  static String formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '$h h ${m.toString().padLeft(2, '0')} min';
    return '$m min';
  }

  static String formatStopwatch(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  static DateTime parseDate(String date) => DateTime.parse(date);

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static String formatSectionDate(DateTime date, AppLocalizations l10n) {
    final d = dateOnly(date);
    final today = dateOnly(DateTime.now());
    final diff = d.difference(today).inDays;
    final relative = switch (diff) {
      -1 => l10n.relativeYesterday,
      0 => l10n.relativeToday,
      1 => l10n.relativeTomorrow,
      _ => weekdayLabel(l10n, d.weekday),
    };
    return '${sectionDate.format(d)} · $relative';
  }

  static String weekdayLabel(AppLocalizations l10n, int weekday) {
    return switch (weekday) {
      DateTime.monday => l10n.weekdayMon,
      DateTime.tuesday => l10n.weekdayTue,
      DateTime.wednesday => l10n.weekdayWed,
      DateTime.thursday => l10n.weekdayThu,
      DateTime.friday => l10n.weekdayFri,
      DateTime.saturday => l10n.weekdaySat,
      DateTime.sunday => l10n.weekdaySun,
      _ => l10n.weekdayMon,
    };
  }
}
