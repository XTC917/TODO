import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/event.dart';

enum FocusTimerState { idle, running, paused }

class FocusSession {
  const FocusSession({
    required this.mode,
    this.startedAt,
    this.linkedEventId,
    this.targetSeconds,
    this.elapsedSeconds = 0,
    this.state = FocusTimerState.idle,
  });

  final FocusMode mode;
  final DateTime? startedAt;
  final int? linkedEventId;
  final int? targetSeconds;
  final int elapsedSeconds;
  final FocusTimerState state;

  bool get isActive =>
      state == FocusTimerState.running || state == FocusTimerState.paused;

  FocusSession copyWith({
    FocusMode? mode,
    DateTime? startedAt,
    int? linkedEventId,
    bool clearLinkedEventId = false,
    int? targetSeconds,
    bool clearTargetSeconds = false,
    int? elapsedSeconds,
    FocusTimerState? state,
  }) {
    return FocusSession(
      mode: mode ?? this.mode,
      startedAt: startedAt ?? this.startedAt,
      linkedEventId:
          clearLinkedEventId ? null : (linkedEventId ?? this.linkedEventId),
      targetSeconds:
          clearTargetSeconds ? null : (targetSeconds ?? this.targetSeconds),
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      state: state ?? this.state,
    );
  }
}

class FocusTimerNotifier extends StateNotifier<FocusSession> {
  FocusTimerNotifier() : super(const FocusSession(mode: FocusMode.pomodoro));

  Timer? _timer;

  void start({
    required FocusMode mode,
    int? targetMinutes,
    int? linkedEventId,
  }) {
    _timer?.cancel();
    state = FocusSession(
      mode: mode,
      startedAt: DateTime.now(),
      linkedEventId: linkedEventId,
      targetSeconds: targetMinutes != null ? targetMinutes * 60 : null,
      elapsedSeconds: 0,
      state: FocusTimerState.running,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void pause() {
    if (state.state != FocusTimerState.running) return;
    _timer?.cancel();
    state = state.copyWith(state: FocusTimerState.paused);
  }

  void resume() {
    if (state.state != FocusTimerState.paused) return;
    state = state.copyWith(
      startedAt: DateTime.now(),
      state: FocusTimerState.running,
    );
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  FocusSession? stop() {
    _timer?.cancel();
    if (!state.isActive || state.startedAt == null) {
      state = const FocusSession(mode: FocusMode.pomodoro);
      return null;
    }
    final ended = DateTime.now();
    final session = state;
    state = const FocusSession(mode: FocusMode.pomodoro);
    return session.copyWith(elapsedSeconds: _currentElapsed(ended));
  }

  void _tick() {
    if (state.startedAt == null) return;
    final elapsed = _currentElapsed(DateTime.now());
    state = state.copyWith(elapsedSeconds: elapsed);

    if (state.mode == FocusMode.pomodoro &&
        state.targetSeconds != null &&
        elapsed >= state.targetSeconds!) {
      stop();
    }
  }

  int _currentElapsed(DateTime now) {
    if (state.startedAt == null) return state.elapsedSeconds;
    final delta = now.difference(state.startedAt!).inSeconds;
    return state.elapsedSeconds + delta;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final focusTimerProvider =
    StateNotifierProvider<FocusTimerNotifier, FocusSession>((ref) {
  return FocusTimerNotifier();
});

final focusLaunchProvider = StateProvider<FocusLaunchConfig?>((ref) => null);

final shellTabProvider = StateProvider<int>((ref) => 0);

final completedSectionExpandedProvider =
    StateProvider<bool>((ref) => false);
