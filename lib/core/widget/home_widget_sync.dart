import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import '../providers/app_providers.dart';
import '../providers/focus_providers.dart';
import '../utils/date_time_formats.dart';
import 'home_widget_snapshot.dart';
import 'widget_background_handler.dart';
import 'widget_launch_handler.dart';

final homeWidgetSyncProvider = Provider<HomeWidgetSyncService>((ref) {
  return HomeWidgetSyncService(ref);
});

class HomeWidgetSyncService {
  HomeWidgetSyncService(this._ref);

  final Ref _ref;
  Timer? _debounce;

  void scheduleSync() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    try {
      await HomeWidgetSnapshotWriter.syncFromDatabase(
        prefs: _ref.read(sharedPreferencesProvider),
      );
    } catch (e, st) {
      debugPrint('Home widget sync failed: $e\n$st');
    }
  }
}

/// Keeps home screen widgets in sync and handles widget deep links.
class WidgetBootstrap extends ConsumerStatefulWidget {
  const WidgetBootstrap({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<WidgetBootstrap> createState() => _WidgetBootstrapState();
}

class _WidgetBootstrapState extends ConsumerState<WidgetBootstrap> {
  StreamSubscription<Uri?>? _clickSub;

  @override
  void initState() {
    super.initState();
    HomeWidget.registerInteractivityCallback(widgetInteractivityCallback);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeWidgetSyncProvider).syncNow();
      _bindWidgetClicks();
      _handleInitialWidgetLaunch();
    });
  }

  Future<void> _bindWidgetClicks() async {
    _clickSub = HomeWidget.widgetClicked.listen((uri) {
      if (!mounted) return;
      handleWidgetLaunch(ref, uri);
    });
  }

  Future<void> _handleInitialWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (!mounted || uri == null) return;
    handleWidgetLaunch(ref, uri);
  }

  @override
  void dispose() {
    _clickSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTimeFormats.dateOnly(DateTime.now());
    ref.watch(eventsForDateProvider(today));
    ref.watch(daySummaryProvider(today));
    ref.watch(themePaletteProvider);
    ref.watch(appLanguageProvider);

    ref.listen(eventsForDateProvider(today), (_, __) {
      ref.read(homeWidgetSyncProvider).scheduleSync();
    });
    ref.listen(daySummaryProvider(today), (_, __) {
      ref.read(homeWidgetSyncProvider).scheduleSync();
    });
    ref.listen(focusTimerProvider, (_, next) {
      if (next.completion != null) {
        ref.read(homeWidgetSyncProvider).scheduleSync();
      }
    });

    return widget.child;
  }
}

@pragma('vm:entry-point')
Future<void> widgetInteractivityCallback(Uri? uri) async {
  await handleWidgetBackgroundUri(uri);
}
