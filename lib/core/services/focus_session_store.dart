import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enums.dart';
import '../../models/focus_session.dart';

const activeFocusSessionKey = 'active_focus_session_v1';
const focusStrictBackgroundedAtKey = 'focus_strict_backgrounded_at';

/// Persists an in-progress focus session across process death.
class FocusSessionStore {
  FocusSessionStore(this._prefs);

  final SharedPreferences _prefs;

  Future<void> save(FocusRuntimeSession session) async {
    if (!session.isActive) {
      await clearSession();
      return;
    }
    await _prefs.setString(activeFocusSessionKey, jsonEncode(_encode(session)));
  }

  FocusRuntimeSession? loadSession() {
    final raw = _prefs.getString(activeFocusSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return _decode(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    await _prefs.remove(activeFocusSessionKey);
    await clearStrictBackgroundedAt();
  }

  DateTime? strictBackgroundedAt() {
    final raw = _prefs.getString(focusStrictBackgroundedAtKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> setStrictBackgroundedAt(DateTime? at) async {
    if (at == null) {
      await clearStrictBackgroundedAt();
      return;
    }
    await _prefs.setString(focusStrictBackgroundedAtKey, at.toIso8601String());
  }

  Future<void> clearStrictBackgroundedAt() async {
    await _prefs.remove(focusStrictBackgroundedAtKey);
  }

  Map<String, dynamic> _encode(FocusRuntimeSession session) {
    return {
      'mode': session.mode.storage,
      'sessionStartedAt': session.sessionStartedAt?.toIso8601String(),
      'segmentStartedAt': session.segmentStartedAt?.toIso8601String(),
      'accumulatedSeconds': session.accumulatedSeconds,
      'targetSeconds': session.targetSeconds,
      'linkedEventId': session.linkedEventId,
      'linkedTaskTitle': session.linkedTaskTitle,
      'state': session.state.name,
      'enforcementMode': session.enforcementMode.storage,
    };
  }

  FocusRuntimeSession? _decode(Map<String, dynamic> json) {
    final stateName = json['state'] as String?;
    final state = FocusTimerState.values.firstWhere(
      (s) => s.name == stateName,
      orElse: () => FocusTimerState.idle,
    );
    if (state == FocusTimerState.idle) return null;

    return FocusRuntimeSession(
      mode: FocusModeX.fromStorage(json['mode'] as String? ?? 'pomodoro'),
      sessionStartedAt: _parseDate(json['sessionStartedAt']),
      segmentStartedAt: _parseDate(json['segmentStartedAt']),
      accumulatedSeconds: (json['accumulatedSeconds'] as num?)?.toInt() ?? 0,
      targetSeconds: (json['targetSeconds'] as num?)?.toInt(),
      linkedEventId: (json['linkedEventId'] as num?)?.toInt(),
      linkedTaskTitle: json['linkedTaskTitle'] as String?,
      state: state,
      enforcementMode: FocusEnforcementModeX.fromStorage(
        json['enforcementMode'] as String? ?? 'normal',
      ),
    );
  }

  DateTime? _parseDate(Object? raw) {
    if (raw is! String) return null;
    return DateTime.tryParse(raw);
  }
}
