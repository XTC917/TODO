import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/event.dart';
import '../../models/focus_session.dart';
import '../services/focus_preset_service.dart';
import '../services/focus_session_store.dart';
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
  FocusTimerNotifier(this._service, this._store)
      : super(_initialTick(_service)) {
    unawaited(_restoreIfNeeded());
  }

  final FocusTimerService _service;
  final FocusSessionStore _store;
  Timer? _uiTimer;

  static FocusTimerTick _initialTick(FocusTimerService service) {
    return FocusTimerTick(session: service.session);
  }

  void _emit({FocusCompletionResult? completion}) {
    state = FocusTimerTick(
      session: _service.session,
      completion: completion,
    );
    unawaited(_persist());
  }

  Future<void> _persist() async {
    await _store.save(_service.session);
  }

  Future<void> _restoreIfNeeded() async {
    final saved = _store.loadSession();
    if (saved == null || !saved.isActive) return;

    _service.restoreSession(saved);

    final bgAt = _store.strictBackgroundedAt();
    if (bgAt != null &&
        saved.enforcementMode == FocusEnforcementMode.strict &&
        saved.state == FocusTimerState.running &&
        DateTime.now().difference(bgAt).inSeconds >= 60) {
      await _store.clearStrictBackgroundedAt();
      final result = _service.stopStrictFailure(DateTime.now());
      await _store.clearSession();
      _emit(completion: result);
      return;
    }

    if (saved.state == FocusTimerState.running) {
      final completion = _service.tick(DateTime.now());
      if (completion != null) {
        await _store.clearSession();
        _emit(completion: completion);
        return;
      }
      _startUiTimer();
    }
    _emit();
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final completion = _service.tick(DateTime.now());
      if (completion != null) {
        _stopUiTimer();
        unawaited(_store.clearSession());
      }
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
    FocusEnforcementMode enforcementMode = FocusEnforcementMode.normal,
  }) {
    if (_service.session.isActive) return;
    _service.configureIdle(
      mode: mode,
      targetSeconds: targetSeconds,
      enforcementMode: enforcementMode,
    );
    _emit();
  }

  void start({
    required FocusMode mode,
    int? targetSeconds,
    int? linkedEventId,
    String? linkedTaskTitle,
    FocusEnforcementMode enforcementMode = FocusEnforcementMode.normal,
  }) {
    _service.start(
      mode: mode,
      now: DateTime.now(),
      targetSeconds: targetSeconds,
      linkedEventId: linkedEventId,
      linkedTaskTitle: linkedTaskTitle,
      enforcementMode: enforcementMode,
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

  void updateEnforcementMode(FocusEnforcementMode mode) {
    _service.updateEnforcementMode(mode);
    _emit();
  }

  FocusCompletionResult? failStrictSession() {
    _stopUiTimer();
    final result = _service.stopStrictFailure(DateTime.now());
    unawaited(_store.clearSession());
    _emit();
    return result;
  }

  FocusCompletionResult? stop({bool completed = false}) {
    _stopUiTimer();
    final result = _service.stop(DateTime.now(), completed: completed);
    unawaited(_store.clearSession());
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

final focusSessionStoreProvider = Provider<FocusSessionStore>((ref) {
  return FocusSessionStore(ref.watch(sharedPreferencesProvider));
});

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusTimerTick>((ref) {
  return FocusTimerNotifier(
    ref.watch(focusTimerServiceProvider),
    ref.watch(focusSessionStoreProvider),
  );
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

  Future<bool> addPreset(int seconds) async {
    final added = await _service.addPreset(seconds);
    state = _service.loadPresets();
    return added;
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

class DefaultCountdownController extends StateNotifier<int> {
  DefaultCountdownController(this._service, List<int> presets)
      : super(_service.loadDefaultCountdown(presets));

  final FocusPresetService _service;

  Future<void> setDefault(int seconds) async {
    state = seconds;
    await _service.saveDefaultCountdown(seconds);
  }
}

final defaultCountdownSecondsProvider =
    StateNotifierProvider<DefaultCountdownController, int>((ref) {
  final service = ref.watch(focusPresetServiceProvider);
  final presets = ref.watch(focusPresetsProvider);
  return DefaultCountdownController(service, presets);
});

class FocusKeepAwakeController extends StateNotifier<bool> {
  FocusKeepAwakeController(this._service)
      : super(_service.loadKeepScreenAwake());

  final FocusPresetService _service;

  Future<void> setEnabled(bool enabled) async {
    state = enabled;
    await _service.saveKeepScreenAwake(enabled);
  }
}

final focusKeepAwakeProvider =
    StateNotifierProvider<FocusKeepAwakeController, bool>((ref) {
  return FocusKeepAwakeController(ref.watch(focusPresetServiceProvider));
});

class FocusEnforcementModeController
    extends StateNotifier<FocusEnforcementMode> {
  FocusEnforcementModeController(this._service)
      : super(_service.loadEnforcementMode());

  final FocusPresetService _service;

  Future<void> setMode(FocusEnforcementMode mode) async {
    state = mode;
    await _service.saveEnforcementMode(mode);
  }
}

final focusEnforcementModeProvider =
    StateNotifierProvider<FocusEnforcementModeController, FocusEnforcementMode>(
        (ref) {
  return FocusEnforcementModeController(ref.watch(focusPresetServiceProvider));
});

final selectedCountdownSecondsProvider = StateProvider<int>((ref) {
  final presets = ref.watch(focusPresetsProvider);
  final defaultSeconds = ref.watch(defaultCountdownSecondsProvider);
  if (presets.contains(defaultSeconds)) return defaultSeconds;
  return presets.contains(25 * 60) ? 25 * 60 : presets.first;
});

/// When true, hides shell chrome and shows immersive focus UI.
final focusImmersiveModeProvider = StateProvider<bool>((ref) => false);

/// Local dark/light override while in immersive focus (does not affect app theme).
final focusImmersiveDarkModeProvider = StateProvider<bool>((ref) => false);

/// Open focus record swipe row id.
final focusRecordSwipeOpenProvider = StateProvider<int?>((ref) => null);
