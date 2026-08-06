import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/utils/date_time_formats.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/statistics.dart';

String statsPeriodLabel(
  AppLocalizations l10n,
  StatsPeriod period,
  int offset,
  Locale locale,
) {
  final now = DateTime.now();
  switch (period) {
    case StatsPeriod.day:
      return _dayLabel(l10n, now, offset);
    case StatsPeriod.week:
      return _weekLabel(l10n, now, offset);
    case StatsPeriod.month:
      return _monthLabel(now, offset, locale);
    case StatsPeriod.year:
      return '${now.year + offset}';
  }
}

String _dayLabel(
  AppLocalizations l10n,
  DateTime now,
  int offset,
) {
  final date = DateTimeFormats.dateOnly(now.add(Duration(days: offset)));
  return DateTimeFormats.formatSectionDate(date, l10n);
}

String _weekLabel(AppLocalizations l10n, DateTime now, int offset) {
  return switch (offset) {
    -1 => l10n.statsLastWeek,
    0 => l10n.statsThisWeek,
    1 => l10n.statsNextWeek,
    _ => _weekRangeLabel(now, offset),
  };
}

String _weekRangeLabel(DateTime now, int offset) {
  final start = DateTimeFormats.startOfWeek(now).add(Duration(days: offset * 7));
  final end = start.add(const Duration(days: 6));
  return '${DateTimeFormats.formatMonthDay(start)} - '
      '${DateTimeFormats.formatMonthDay(end)}';
}

String _monthLabel(DateTime now, int offset, Locale locale) {
  final month = DateTime(now.year, now.month + offset, 1);
  final code = switch (locale.languageCode) {
    'zh' => 'zh_CN',
    'ko' => 'ko_KR',
    _ => 'en_US',
  };
  return DateFormat('MMMM yyyy', code).format(month);
}
