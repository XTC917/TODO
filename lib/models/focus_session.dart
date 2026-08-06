import 'enums.dart';

enum FocusTimerState { idle, running, paused }

/// In-memory state while a focus session is active.
class FocusRuntimeSession {
  const FocusRuntimeSession({
    required this.mode,
    this.sessionStartedAt,
    this.segmentStartedAt,
    this.accumulatedSeconds = 0,
    this.targetSeconds,
    this.linkedEventId,
    this.linkedTaskTitle,
    this.state = FocusTimerState.idle,
    this.completedNaturally = false,
  });

  final FocusMode mode;
  final DateTime? sessionStartedAt;
  final DateTime? segmentStartedAt;
  final int accumulatedSeconds;
  final int? targetSeconds;
  final int? linkedEventId;
  final String? linkedTaskTitle;
  final FocusTimerState state;
  final bool completedNaturally;

  bool get isActive =>
      state == FocusTimerState.running || state == FocusTimerState.paused;

  int elapsedSecondsAt(DateTime now) {
    if (!isActive) return accumulatedSeconds;
    if (state == FocusTimerState.paused) return accumulatedSeconds;
    if (segmentStartedAt == null) return accumulatedSeconds;
    return accumulatedSeconds +
        now.difference(segmentStartedAt!).inSeconds.clamp(0, 86400);
  }

  int? remainingSecondsAt(DateTime now) {
    if (targetSeconds == null) return null;
    final remaining = targetSeconds! - elapsedSecondsAt(now);
    return remaining.clamp(0, targetSeconds!);
  }

  FocusRuntimeSession copyWith({
    FocusMode? mode,
    DateTime? sessionStartedAt,
    DateTime? segmentStartedAt,
    bool clearSegmentStartedAt = false,
    int? accumulatedSeconds,
    int? targetSeconds,
    bool clearTargetSeconds = false,
    int? linkedEventId,
    String? linkedTaskTitle,
    bool clearLinkedEventId = false,
    bool clearLinkedTaskTitle = false,
    FocusTimerState? state,
    bool? completedNaturally,
  }) {
    return FocusRuntimeSession(
      mode: mode ?? this.mode,
      sessionStartedAt: sessionStartedAt ?? this.sessionStartedAt,
      segmentStartedAt: clearSegmentStartedAt
          ? null
          : (segmentStartedAt ?? this.segmentStartedAt),
      accumulatedSeconds: accumulatedSeconds ?? this.accumulatedSeconds,
      targetSeconds:
          clearTargetSeconds ? null : (targetSeconds ?? this.targetSeconds),
      linkedEventId: clearLinkedEventId
          ? null
          : (linkedEventId ?? this.linkedEventId),
      linkedTaskTitle: clearLinkedTaskTitle
          ? null
          : (linkedTaskTitle ?? this.linkedTaskTitle),
      state: state ?? this.state,
      completedNaturally: completedNaturally ?? this.completedNaturally,
    );
  }
}

/// Result returned when a focus session ends (manual or countdown complete).
class FocusCompletionResult {
  const FocusCompletionResult({
    required this.mode,
    required this.sessionStartedAt,
    required this.endedAt,
    required this.elapsedSeconds,
    required this.completed,
    this.plannedDurationSeconds,
    this.linkedEventId,
    this.linkedTaskTitle,
  });

  final FocusMode mode;
  final DateTime sessionStartedAt;
  final DateTime endedAt;
  final int elapsedSeconds;
  final bool completed;
  final int? plannedDurationSeconds;
  final int? linkedEventId;
  final String? linkedTaskTitle;
}

enum FocusDurationDisplayMode { hour, minute }
