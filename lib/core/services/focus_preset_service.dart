import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

const _presetsKey = 'focus_countdown_presets';
const _displayModeKey = 'focus_duration_display_mode';

/// Default countdown presets in seconds.
const kDefaultFocusPresetsSeconds = [15 * 60, 25 * 60, 30 * 60, 45 * 60, 60 * 60];

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
      return list.isEmpty ? [...kDefaultFocusPresetsSeconds] : list;
    } catch (_) {
      return [...kDefaultFocusPresetsSeconds];
    }
  }

  Future<void> savePresets(List<int> presets) async {
    final unique = presets.where((s) => s > 0).toSet().toList()..sort();
    await _prefs.setString(_presetsKey, jsonEncode(unique));
  }

  Future<void> addPreset(int seconds) async {
    final presets = loadPresets()..add(seconds);
    await savePresets(presets);
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
