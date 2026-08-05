import 'package:flutter/material.dart';

/// Soft, calming palette used across cards and event colors.
class AppColors {
  AppColors._();

  static const cream = Color(0xFFFFF8F4);
  static const creamDark = Color(0xFF1C1917);
  static const softPink = Color(0xFFF8E8E8);
  static const softGray = Color(0xFFE8E4E1);
  static const textPrimary = Color(0xFF3D3835);
  static const textSecondary = Color(0xFF8A827C);
  static const cardLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF2A2624);
  static const divider = Color(0xFFEDE8E4);

  static const eventPalette = <Color>[
    Color(0xFFE8A0A0),
    Color(0xFFB8C9B8),
    Color(0xFFB5C7D9),
    Color(0xFFD4B5C7),
    Color(0xFFD9C9A8),
    Color(0xFFA8C9C5),
    Color(0xFFC9B8A8),
    Color(0xFFD4A8A8),
  ];

  static Color fromHex(String hex) {
    final cleaned = hex.replaceFirst('#', '');
    return Color(int.parse('FF$cleaned', radix: 16));
  }

  static String toHex(Color color) {
    int channel(double value) => (value * 255.0).round().clamp(0, 255);
    final r = channel(color.r).toRadixString(16).padLeft(2, '0');
    final g = channel(color.g).toRadixString(16).padLeft(2, '0');
    final b = channel(color.b).toRadixString(16).padLeft(2, '0');
    return '$r$g$b'.toUpperCase();
  }
}
