import '../../models/enums.dart';
import '../../models/focus_session.dart';

/// Core focus timer logic — elapsed time derived from [Stopwatch] + wall clock.
class FocusTimerService {
  FocusRuntimeSession _session =
      const FocusRuntimeSession(mode: FocusMode.pomodoro);

  int _accumulatedMilliseconds = 0;
  Stopwatch? _segmentStopwatch;

  FocusRuntimeSession get session => _session;

  /// Elapsed seconds for the active or paused session.
  int elapsedSeconds() {
    if (!_session.isActive) return 0;
    if (_session.state == FocusTimerState.paused) {
      return _accumulatedMilliseconds ~/ 1000;
    }
    final segmentMs = _segmentStopwatch?.elapsedMilliseconds ?? 0;
    return (_accumulatedMilliseconds + segmentMs) ~/ 1000;
  }

  /// Remaining seconds for countdown mode, or null for stopwatch.
  int? remainingSeconds() {
    final target = _session.targetSeconds;
    if (target == null) return null;
    final remaining = target - elapsedSeconds();
    return remaining.clamp(0, target);
  }

  void configureIdle({
    required FocusMode mode,
    int? targetSeconds,
  }) {
    if (_session.isActive) return;
    _accumulatedMilliseconds = 0;
    _segmentStopwatch?.stop();
    _segmentStopwatch = null;
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
    _accumulatedMilliseconds = 0;
    _segmentStopwatch = Stopwatch()..start();
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
    if (_segmentStopwatch != null) {
      _accumulatedMilliseconds += _segmentStopwatch!.elapsedMilliseconds;
      _segmentStopwatch!.stop();
      _segmentStopwatch = null;
    }
    _session = _session.copyWith(
      accumulatedSeconds: _accumulatedMilliseconds ~/ 1000,
      clearSegmentStartedAt: true,
      state: FocusTimerState.paused,
    );
  }

  void resume(DateTime now) {
    if (_session.state != FocusTimerState.paused) return;
    _segmentStopwatch = Stopwatch()..start();
    _session = _session.copyWith(
      segmentStartedAt: now,
      state: FocusTimerState.running,
    );
  }

  void updateLinkedTask({int? eventId, String? taskTitle}) {
    if (!_session.isActive) return;
    final trimmed = taskTitle?.trim();
    final hasTitle = trimmed != null && trimmed.isNotEmpty;
    _session = _session.copyWith(
      linkedEventId: eventId,
      linkedTaskTitle: hasTitle ? trimmed : null,
      clearLinkedEventId: eventId == null,
      clearLinkedTaskTitle: !hasTitle,
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

    final elapsed = elapsedSeconds();
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
    if (elapsedSeconds() < _session.targetSeconds!) return null;
    return stop(now, completed: true);
  }

  void _resetIdle() {
    _accumulatedMilliseconds = 0;
    _segmentStopwatch?.stop();
    _segmentStopwatch = null;
    _session = FocusRuntimeSession(mode: _session.mode);
  }
}
