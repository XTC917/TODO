import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/event.dart';
import '../../models/focus_session.dart';
import '../services/focus_preset_service.dart';
import '../services/focus_timer_service.dart';
import 'app_providers.dart';

export '../../models/focus_session.dart';

class FocusTimerTick {
  const FocusTimerTick({
    required this.session,
    this.completion,
  });

  final FocusRuntimeSession session;
  final FocusCompletionResult? completion;
}

class FocusTimerNotifier extends StateNotifier<FocusTimerTick> {
  FocusTimerNotifier(this._service) : super(_initialTick(_service));

  final FocusTimerService _service;
  Timer? _uiTimer;

  static FocusTimerTick _initialTick(FocusTimerService service) {
    return FocusTimerTick(session: service.session);
  }

  void _emit({FocusCompletionResult? completion}) {
    state = FocusTimerTick(
      session: _service.session,
      completion: completion,
    );
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final completion = _service.tick(DateTime.now());
      if (completion != null) _stopUiTimer();
      _emit(completion: completion);
    });
  }

  void _stopUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = null;
  }

  /// Refresh display after returning from background (wall-clock catch-up).
  void refreshDisplay() {
    if (_service.session.state == FocusTimerState.running) {
      final completion = _service.tick(DateTime.now());
      if (completion != null) _stopUiTimer();
      _emit(completion: completion);
    } else {
      _emit();
    }
  }

  void configureIdle({
    required FocusMode mode,
    int? targetSeconds,
  }) {
    if (_service.session.isActive) return;
    _service.configureIdle(mode: mode, targetSeconds: targetSeconds);
    _emit();
  }

  void start({
    required FocusMode mode,
    int? targetSeconds,
    int? linkedEventId,
    String? linkedTaskTitle,
  }) {
    _service.start(
      mode: mode,
      now: DateTime.now(),
      targetSeconds: targetSeconds,
      linkedEventId: linkedEventId,
      linkedTaskTitle: linkedTaskTitle,
    );
    _startUiTimer();
    _emit();
  }

  void pause() {
    _service.pause(DateTime.now());
    _stopUiTimer();
    _emit();
  }

  void resume() {
    _service.resume(DateTime.now());
    _startUiTimer();
    _emit();
  }

  void updateLinkedTask({int? eventId, String? taskTitle}) {
    _service.updateLinkedTask(eventId: eventId, taskTitle: taskTitle);
    _emit();
  }

  FocusCompletionResult? stop({bool completed = false}) {
    _stopUiTimer();
    final result = _service.stop(DateTime.now(), completed: completed);
    _emit();
    return result;
  }

  void clearCompletion() {
    state = FocusTimerTick(session: state.session);
  }

  @override
  void dispose() {
    _stopUiTimer();
    super.dispose();
  }
}

final focusTimerServiceProvider = Provider<FocusTimerService>((ref) {
  return FocusTimerService();
});

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerTick>((ref) {
  return FocusTimerNotifier(ref.watch(focusTimerServiceProvider));
});

final focusLaunchProvider = StateProvider<FocusLaunchConfig?>((ref) => null);

final shellTabProvider = StateProvider<int>((ref) => 0);

final completedSectionExpandedProvider = StateProvider<bool>((ref) => false);

final focusPresetServiceProvider = Provider<FocusPresetService>((ref) {
  return FocusPresetService(ref.watch(sharedPreferencesProvider));
});

class FocusPresetsController extends StateNotifier<List<int>> {
  FocusPresetsController(this._service) : super(_service.loadPresets());

  final FocusPresetService _service;

  Future<void> addPreset(int seconds) async {
    await _service.addPreset(seconds);
    state = _service.loadPresets();
  }

  Future<void> removePreset(int seconds) async {
    await _service.removePreset(seconds);
    state = _service.loadPresets();
  }

  Future<void> reload() async {
    state = _service.loadPresets();
  }
}

final focusPresetsProvider =
    StateNotifierProvider<FocusPresetsController, List<int>>((ref) {
  return FocusPresetsController(ref.watch(focusPresetServiceProvider));
});

class FocusDisplayModeController extends StateNotifier<FocusDurationDisplayMode> {
  FocusDisplayModeController(this._service)
      : super(_parseMode(_service.loadDisplayMode()));

  final FocusPresetService _service;

  static FocusDurationDisplayMode _parseMode(String raw) {
    return raw == 'minute'
        ? FocusDurationDisplayMode.minute
        : FocusDurationDisplayMode.hour;
  }

  Future<void> toggle() async {
    final next = state == FocusDurationDisplayMode.hour
        ? FocusDurationDisplayMode.minute
        : FocusDurationDisplayMode.hour;
    state = next;
    await _service.saveDisplayMode(
      next == FocusDurationDisplayMode.minute ? 'minute' : 'hour',
    );
  }
}

final focusDisplayModeProvider =
    StateNotifierProvider<FocusDisplayModeController, FocusDurationDisplayMode>(
        (ref) {
  return FocusDisplayModeController(ref.watch(focusPresetServiceProvider));
});

final selectedCountdownSecondsProvider = StateProvider<int>((ref) {
  final presets = ref.watch(focusPresetsProvider);
  return presets.contains(25 * 60) ? 25 * 60 : presets.first;
});

/// When true, hides shell chrome and shows immersive focus UI.
final focusImmersiveModeProvider = StateProvider<bool>((ref) => false);
