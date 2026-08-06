class StatsFormat {
  StatsFormat._();

  static String durationCompact(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0 && m > 0) return '${h}h ${m}m';
    if (h > 0) return '${h}h';
    if (m > 0) return '${m}m';
    return '0m';
  }

  /// Scale max for bar height — highest bar should nearly fill the plot.
  static int chartScaleMax(int rawMax) {
    if (rawMax <= 0) return 60;
    final totalMinutes = (rawMax / 60.0).ceil();
    if (totalMinutes <= 60) {
      return _niceMinuteCeiling(totalMinutes) * 60;
    }
    final hours = (totalMinutes / 60.0).ceil();
    return _niceCeiling(hours) * 3600;
  }

  static int _niceMinuteCeiling(int minutes) {
    if (minutes <= 5) return 5;
    if (minutes <= 10) return 10;
    if (minutes <= 15) return 15;
    if (minutes <= 20) return 20;
    if (minutes <= 30) return 30;
    if (minutes <= 45) return 45;
    if (minutes <= 60) return 60;
    final hours = (minutes / 60.0).ceil();
    return _niceCeiling(hours) * 60;
  }

  /// Y-axis tick values (seconds), top → bottom.
  static List<int> yAxisTicks(int rawMax, {required double plotHeight}) {
    if (rawMax <= 0) return const [0];
    final ceiling = chartScaleMax(rawMax);
    final maxLabels = plotHeight < 72
        ? 3
        : plotHeight < 108
            ? 4
            : 5;
    final step = _niceStep(ceiling, maxLabels - 1);
    return _ticksFromStep(ceiling, step);
  }

  static int _niceStep(int ceiling, int divisions) {
    if (divisions <= 0) return ceiling;
    final raw = ceiling / divisions;
    if (raw <= 300) return _niceMinuteCeiling((raw / 60).ceil()) * 60;
    if (raw <= 3600) {
      final mins = (raw / 60).ceil();
      return _niceMinuteCeiling(mins) * 60;
    }
    final hours = (raw / 3600).ceil();
    return _niceCeiling(hours) * 3600;
  }

  static List<int> _ticksFromStep(int ceiling, int step) {
    if (step <= 0) return [ceiling, 0];
    final ticks = <int>[];
    for (var v = ceiling; v >= 0; v -= step) {
      ticks.add(v);
    }
    if (ticks.last != 0) ticks.add(0);
    // Drop middle ticks if labels would crowd (< 22px apart handled by caller).
    if (ticks.length > 5) {
      final stride = (ticks.length / 5).ceil();
      final sparse = <int>{
        for (var i = 0; i < ticks.length; i += stride) ticks[i],
        if (ticks.last != 0) 0,
      }.toList()
        ..sort((a, b) => b.compareTo(a));
      return sparse;
    }
    return ticks;
  }

  static int _niceCeiling(int value) {
    if (value <= 0) return 1;
    final magnitude = _pow10(value);
    final normalized = value / magnitude;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return (nice * magnitude).round();
  }

  static double _pow10(int value) {
    var p = 1.0;
    while (p * 10 < value) {
      p *= 10;
    }
    return p;
  }
}
