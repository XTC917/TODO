import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/enums.dart';
import 'app_colors.dart';
import 'theme_color_utils.dart';

enum BackgroundMode { followAccent, custom }

class ThemePalette {
  const ThemePalette({
    required this.seedColor,
    this.preset,
    this.backgroundMode = BackgroundMode.followAccent,
    this.customBackgroundLight,
    this.customBackgroundDark,
  });

  final Color seedColor;
  final AccentColor? preset;
  final BackgroundMode backgroundMode;
  final Color? customBackgroundLight;
  final Color? customBackgroundDark;

  bool get isCustomAccent => preset == null;

  Color backgroundFor(Brightness brightness) {
    if (backgroundMode == BackgroundMode.custom) {
      final custom = brightness == Brightness.light
          ? customBackgroundLight
          : customBackgroundDark;
      if (custom != null) return custom;
    }
    return ThemeColorUtils.deriveBackground(seedColor, brightness);
  }

  Color cardFor(Brightness brightness) {
    final background = backgroundFor(brightness);
    return ThemeColorUtils.deriveCard(seedColor, background, brightness);
  }

  Color inputFillFor(Brightness brightness) {
    final background = backgroundFor(brightness);
    return ThemeColorUtils.deriveInputFill(seedColor, background, brightness);
  }

  Color dividerFor(Brightness brightness) {
    final background = backgroundFor(brightness);
    return ThemeColorUtils.deriveDivider(seedColor, background, brightness);
  }

  Color customBackgroundFor(Brightness brightness) {
    final custom = brightness == Brightness.light
        ? customBackgroundLight
        : customBackgroundDark;
    return custom ?? ThemeColorUtils.deriveBackground(seedColor, brightness);
  }

  ThemePalette copyWith({
    Color? seedColor,
    AccentColor? preset,
    bool clearPreset = false,
    BackgroundMode? backgroundMode,
    Color? customBackgroundLight,
    Color? customBackgroundDark,
    bool clearCustomBackgroundLight = false,
    bool clearCustomBackgroundDark = false,
  }) {
    return ThemePalette(
      seedColor: seedColor ?? this.seedColor,
      preset: clearPreset ? null : (preset ?? this.preset),
      backgroundMode: backgroundMode ?? this.backgroundMode,
      customBackgroundLight: clearCustomBackgroundLight
          ? null
          : (customBackgroundLight ?? this.customBackgroundLight),
      customBackgroundDark: clearCustomBackgroundDark
          ? null
          : (customBackgroundDark ?? this.customBackgroundDark),
    );
  }

  static ThemePalette fromPrefs(SharedPreferences prefs) {
    const accentKey = 'accent_color';
    const bgModeKey = 'bg_mode';
    const bgLightKey = 'bg_custom_light';
    const bgDarkKey = 'bg_custom_dark';

    final accentRaw = prefs.getString(accentKey);
    Color seed;
    AccentColor? preset;

    if (accentRaw != null && accentRaw.startsWith('custom:')) {
      seed = AppColors.fromHex(accentRaw.substring(7));
      preset = null;
    } else {
      preset = AccentColorX.fromStorage(accentRaw);
      seed = preset.seed;
    }

    final bgMode = prefs.getString(bgModeKey) == 'custom'
        ? BackgroundMode.custom
        : BackgroundMode.followAccent;

    Color? bgLight;
    Color? bgDark;
    final lightRaw = prefs.getString(bgLightKey);
    final darkRaw = prefs.getString(bgDarkKey);
    if (lightRaw != null) bgLight = AppColors.fromHex(lightRaw);
    if (darkRaw != null) bgDark = AppColors.fromHex(darkRaw);

    return ThemePalette(
      seedColor: seed,
      preset: preset,
      backgroundMode: bgMode,
      customBackgroundLight: bgLight,
      customBackgroundDark: bgDark,
    );
  }
}
