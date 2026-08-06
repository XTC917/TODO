import '../../models/enums.dart';
import '../../models/focus_session.dart';

/// Core focus timer logic — all elapsed time derived from wall clock.
class FocusTimerService {
  FocusRuntimeSession _session =
      const FocusRuntimeSession(mode: FocusMode.pomodoro);

  FocusRuntimeSession get session => _session;

  void configureIdle({
    required FocusMode mode,
    int? targetSeconds,
  }) {
    if (_session.isActive) return;
    _session = FocusRuntimeSession(
      mode: mode,
      targetSeconds: targetSeconds,
    );
  }

  void start({
    required FocusMode mode,
    required DateTime now,
    int? targetSeconds,
    int? linkedEventId,
    String? linkedTaskTitle,
  }) {
    _session = FocusRuntimeSession(
      mode: mode,
      sessionStartedAt: now,
      segmentStartedAt: now,
      targetSeconds: targetSeconds,
      linkedEventId: linkedEventId,
      linkedTaskTitle: linkedTaskTitle,
      state: FocusTimerState.running,
    );
  }

  void pause(DateTime now) {
    if (_session.state != FocusTimerState.running) return;
    _session = _session.copyWith(
      accumulatedSeconds: _session.elapsedSecondsAt(now),
      clearSegmentStartedAt: true,
      state: FocusTimerState.paused,
    );
  }

  void resume(DateTime now) {
    if (_session.state != FocusTimerState.paused) return;
    _session = _session.copyWith(
      segmentStartedAt: now,
      state: FocusTimerState.running,
    );
  }

  /// Stops the session and returns completion data, or null if nothing to save.
  FocusCompletionResult? stop(
    DateTime now, {
    bool completed = false,
  }) {
    if (!_session.isActive || _session.sessionStartedAt == null) {
      _resetIdle();
      return null;
    }

    final elapsed = _session.elapsedSecondsAt(now);
    if (elapsed <= 0) {
      _resetIdle();
      return null;
    }

    final result = FocusCompletionResult(
      mode: _session.mode,
      sessionStartedAt: _session.sessionStartedAt!,
      endedAt: now,
      elapsedSeconds: elapsed,
      completed: completed,
      plannedDurationSeconds: _session.targetSeconds,
      linkedEventId: _session.linkedEventId,
      linkedTaskTitle: _session.linkedTaskTitle,
    );
    _resetIdle();
    return result;
  }

  /// Call on each UI tick to detect pomodoro completion.
  FocusCompletionResult? tick(DateTime now) {
    if (_session.state != FocusTimerState.running) return null;
    if (_session.mode != FocusMode.pomodoro || _session.targetSeconds == null) {
      return null;
    }
    if (_session.elapsedSecondsAt(now) < _session.targetSeconds!) return null;
    return stop(now, completed: true);
  }

  FocusRuntimeSession snapshotAt(DateTime now) {
    if (!_session.isActive) return _session;
    return _session.copyWith(
      accumulatedSeconds: _session.elapsedSecondsAt(now),
    );
  }

  void _resetIdle() {
    _session = FocusRuntimeSession(mode: _session.mode);
  }
}
