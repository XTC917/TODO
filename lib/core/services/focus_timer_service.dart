import '../../models/enums.dart';
import '../../models/focus_session.dart';

/// Core focus timer logic — elapsed time derived from wall clock.
class FocusTimerService {
  FocusRuntimeSession _session =
      const FocusRuntimeSession(mode: FocusMode.pomodoro);

  FocusRuntimeSession get session => _session;

  int elapsedSeconds() {
    if (!_session.isActive) return 0;
    return _session.elapsedSecondsAt(DateTime.now());
  }

  int? remainingSeconds() {
    final target = _session.targetSeconds;
    if (target == null) return null;
    final remaining = target - elapsedSeconds();
    return remaining.clamp(0, target);
  }

  void restoreSession(FocusRuntimeSession session) {
    _session = session;
  }

  void configureIdle({
    required FocusMode mode,
    int? targetSeconds,
    FocusEnforcementMode enforcementMode = FocusEnforcementMode.normal,
  }) {
    if (_session.isActive) return;
    _session = FocusRuntimeSession(
      mode: mode,
      targetSeconds: targetSeconds,
      enforcementMode: enforcementMode,
    );
  }

  void start({
    required FocusMode mode,
    required DateTime now,
    int? targetSeconds,
    int? linkedEventId,
    String? linkedTaskTitle,
    FocusEnforcementMode enforcementMode = FocusEnforcementMode.normal,
  }) {
    _session = FocusRuntimeSession(
      mode: mode,
      sessionStartedAt: now,
      segmentStartedAt: now,
      targetSeconds: targetSeconds,
      linkedEventId: linkedEventId,
      linkedTaskTitle: linkedTaskTitle,
      state: FocusTimerState.running,
      enforcementMode: enforcementMode,
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

  void updateEnforcementMode(FocusEnforcementMode mode) {
    _session = _session.copyWith(enforcementMode: mode);
  }

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

    final result = _buildResult(
      now: now,
      elapsedSeconds: elapsed,
      completed: completed,
    );
    _resetIdle();
    return result;
  }

  FocusCompletionResult? stopStrictFailure(DateTime now) {
    if (!_session.isActive || _session.sessionStartedAt == null) {
      _resetIdle();
      return null;
    }

    final result = _buildResult(
      now: now,
      elapsedSeconds: 0,
      completed: false,
      strictFailed: true,
    );
    _resetIdle();
    return result;
  }

  FocusCompletionResult _buildResult({
    required DateTime now,
    required int elapsedSeconds,
    required bool completed,
    bool strictFailed = false,
  }) {
    return FocusCompletionResult(
      mode: _session.mode,
      sessionStartedAt: _session.sessionStartedAt!,
      endedAt: now,
      elapsedSeconds: elapsedSeconds,
      completed: completed,
      plannedDurationSeconds: _session.targetSeconds,
      linkedEventId: _session.linkedEventId,
      linkedTaskTitle: _session.linkedTaskTitle,
      enforcementMode: _session.enforcementMode,
      strictFailed: strictFailed,
    );
  }

  FocusCompletionResult? tick(DateTime now) {
    if (_session.state != FocusTimerState.running) return null;
    if (_session.mode != FocusMode.pomodoro || _session.targetSeconds == null) {
      return null;
    }
    if (elapsedSeconds() < _session.targetSeconds!) return null;
    return stop(now, completed: true);
  }

  void _resetIdle() {
    _session = FocusRuntimeSession(
      mode: _session.mode,
      enforcementMode: _session.enforcementMode,
    );
  }
}
