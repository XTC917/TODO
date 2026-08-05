import 'package:intl/intl.dart';

class DateTimeFormats {
  DateTimeFormats._();

  static final weekday = DateFormat('EEEE');
  static final shortWeekday = DateFormat('EEE');
  static final ymd = DateFormat('yyyy-MM-dd');
  static final displayDate = DateFormat('yyyy-MM-dd');
  static final monthDay = DateFormat('MM/dd');
  static final headerDate = DateFormat('MMM d · EEEE');
  static final hm = DateFormat('HH:mm');
  static final hms = DateFormat('HH:mm:ss');

  static String formatDate(DateTime date) => ymd.format(date);

  static String formatWeekday(DateTime date) => weekday.format(date);

  static String formatHeader(DateTime date) => headerDate.format(date);

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
}
