import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enums.dart';

const _presetsKey = 'focus_countdown_presets';
const _displayModeKey = 'focus_duration_display_mode';

/// Default countdown presets in seconds.
const kDefaultFocusPresetsSeconds = [15 * 60, 25 * 60, 30 * 60, 45 * 60, 60 * 60];

/// Max saved custom duration presets.
const kMaxFocusPresets = 9;

class FocusPresetService {
  FocusPresetService(this._prefs);

  final SharedPreferences _prefs;

  List<int> loadPresets() {
    final raw = _prefs.getString(_presetsKey);
    if (raw == null || raw.isEmpty) {
      return [...kDefaultFocusPresetsSeconds];
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [...kDefaultFocusPresetsSeconds];
      final list = decoded
          .whereType<num>()
          .map((n) => n.toInt())
          .where((s) => s > 0)
          .toSet()
          .toList()
        ..sort();
      if (list.isEmpty) return [...kDefaultFocusPresetsSeconds];
      if (list.length > kMaxFocusPresets) {
        return list.sublist(0, kMaxFocusPresets);
      }
      return list;
    } catch (_) {
      return [...kDefaultFocusPresetsSeconds];
    }
  }

  Future<void> savePresets(List<int> presets) async {
    final unique = presets.where((s) => s > 0).toSet().toList()..sort();
    if (unique.length > kMaxFocusPresets) {
      unique.removeRange(kMaxFocusPresets, unique.length);
    }
    await _prefs.setString(_presetsKey, jsonEncode(unique));
  }

  /// Returns false when the preset cap is reached (duplicate values still ok).
  Future<bool> addPreset(int seconds) async {
    if (seconds <= 0) return false;
    final presets = loadPresets();
    if (presets.contains(seconds)) return true;
    if (presets.length >= kMaxFocusPresets) return false;
    presets.add(seconds);
    await savePresets(presets);
    return true;
  }

  Future<void> removePreset(int seconds) async {
    final presets = loadPresets()..remove(seconds);
    await savePresets(presets);
  }

  String loadDisplayMode() =>
      _prefs.getString(_displayModeKey) ?? 'hour';

  Future<void> saveDisplayMode(String mode) async {
    await _prefs.setString(_displayModeKey, mode);
  }

  static const _defaultCountdownKey = 'focus_default_countdown_seconds';
  static const _keepAwakeKey = 'focus_keep_screen_awake';
  static const _enforcementModeKey = 'focus_enforcement_mode';

  FocusEnforcementMode loadEnforcementMode() {
    final raw = _prefs.getString(_enforcementModeKey);
    if (raw == null) return FocusEnforcementMode.normal;
    return FocusEnforcementModeX.fromStorage(raw);
  }

  Future<void> saveEnforcementMode(FocusEnforcementMode mode) async {
    await _prefs.setString(_enforcementModeKey, mode.storage);
  }

  int loadDefaultCountdown(List<int> presets) {
    final stored = _prefs.getInt(_defaultCountdownKey);
    if (stored != null && stored > 0) return stored;
    if (presets.contains(25 * 60)) return 25 * 60;
    return presets.isNotEmpty ? presets.first : 25 * 60;
  }

  Future<void> saveDefaultCountdown(int seconds) async {
    await _prefs.setInt(_defaultCountdownKey, seconds);
  }

  bool loadKeepScreenAwake() => _prefs.getBool(_keepAwakeKey) ?? false;

  Future<void> saveKeepScreenAwake(bool enabled) async {
    await _prefs.setBool(_keepAwakeKey, enabled);
  }
}
