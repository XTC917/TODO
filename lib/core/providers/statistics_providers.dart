import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../models/statistics.dart';
import '../services/statistics_service.dart';
import '../utils/date_time_formats.dart';
import 'app_providers.dart';

final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  return StatisticsService();
});

final statsPeriodProvider =
    StateProvider<StatsPeriod>((ref) => StatsPeriod.day);

final statsPeriodOffsetProvider = StateProvider<int>((ref) => 0);

final statsDashboardProvider =
    StreamProvider.autoDispose.family<StatsDashboard, StatsQuery>((ref, query) {
  final service = ref.watch(statisticsServiceProvider);
  final range = service.rangeFor(query.period, query.offset);
  final startKey = DateTimeFormats.formatDate(range.start);
  final endKey = DateTimeFormats.formatDate(range.end);

  final eventRepo = ref.watch(eventRepositoryProvider);
  final focusRepo = ref.watch(focusRepositoryProvider);

  final controller = StreamController<StatsDashboard>();
  var latestEvents = <Event>[];
  var latestRecords = <FocusRecord>[];
  var hasEvents = false;
  var hasRecords = false;

  void emitDashboard() {
    if (!hasEvents || !hasRecords) return;
    controller.add(
      service.buildDashboard(
        period: query.period,
        range: range,
        events: latestEvents,
        records: latestRecords,
      ),
    );
  }

  final eventsSub = eventRepo.watchInRange(startKey, endKey).listen((events) {
    latestEvents = events;
    hasEvents = true;
    emitDashboard();
  });
  final focusSub = focusRepo.watchInRange(startKey, endKey).listen((records) {
    latestRecords = records;
    hasRecords = true;
    emitDashboard();
  });

  ref.onDispose(() {
    eventsSub.cancel();
    focusSub.cancel();
    controller.close();
  });

  return controller.stream;
});
