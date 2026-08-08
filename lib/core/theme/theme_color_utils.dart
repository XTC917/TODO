import 'package:flutter/material.dart';

/// Derives scaffold, card, and input colors from an accent seed.
class ThemeColorUtils {
  ThemeColorUtils._();

  static Color deriveBackground(Color seed, Brightness brightness) {
    final hsl = HSLColor.fromColor(seed);
    if (brightness == Brightness.light) {
      return hsl
          .withSaturation((hsl.saturation * 0.32).clamp(0.06, 0.42))
          .withLightness(0.965)
          .toColor();
    }
    return hsl
        .withSaturation((hsl.saturation * 0.38).clamp(0.08, 0.48))
        .withLightness(0.115)
        .toColor();
  }

  static Color deriveCard(Color seed, Color background, Brightness brightness) {
    if (brightness == Brightness.light) {
      return Color.alphaBlend(
        HSLColor.fromColor(seed)
            .withSaturation(0.12)
            .withLightness(0.995)
            .toColor()
            .withValues(alpha: 0.55),
        background,
      );
    }
    return Color.alphaBlend(
      HSLColor.fromColor(seed)
          .withSaturation(0.18)
          .withLightness(0.22)
          .toColor()
          .withValues(alpha: 0.45),
      background,
    );
  }

  static Color deriveInputFill(
    Color seed,
    Color background,
    Brightness brightness,
  ) {
    if (brightness == Brightness.light) {
      return Color.alphaBlend(
        seed.withValues(alpha: 0.14),
        background,
      );
    }
    return Color.alphaBlend(
      seed.withValues(alpha: 0.12),
      deriveCard(seed, background, brightness),
    );
  }

  static Color deriveDivider(
    Color seed,
    Color background,
    Brightness brightness,
  ) {
    if (brightness == Brightness.light) {
      return Color.alphaBlend(
        seed.withValues(alpha: 0.12),
        background,
      );
    }
    return Color.alphaBlend(
      seed.withValues(alpha: 0.18),
      background,
    );
  }
}
