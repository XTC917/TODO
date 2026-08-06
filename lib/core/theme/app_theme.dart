import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/enums.dart';

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

class AppTheme {
  AppTheme._();

  static ThemeData light(AccentColor accent) => _build(accent, Brightness.light);

  static ThemeData dark(AccentColor accent) => _build(accent, Brightness.dark);

  static ThemeData _build(AccentColor accent, Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final seed = accent.seed;
    final scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      primary: seed,
      surface: isLight ? AppColors.cream : AppColors.creamDark,
      onSurface: isLight ? AppColors.textPrimary : const Color(0xFFF5F0EC),
    );

    final base = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: isLight ? AppColors.cream : AppColors.creamDark,
      textTheme: GoogleFonts.nunitoTextTheme(base),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isLight ? AppColors.cream : AppColors.creamDark,
        foregroundColor: isLight ? AppColors.textPrimary : const Color(0xFFF5F0EC),
        systemOverlayStyle:
            isLight ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: isLight ? AppColors.textPrimary : const Color(0xFFF5F0EC),
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: isLight ? AppColors.cardLight : AppColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: seed,
        foregroundColor: Colors.white,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? AppColors.cream : AppColors.creamDark,
        indicatorColor: seed.withValues(alpha: isLight ? 0.25 : 0.35),
        elevation: 0,
        height: 58,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? seed : AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? seed : AppColors.textSecondary,
          );
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight
            ? AppColors.softPink.withValues(alpha: 0.35)
            : AppColors.cardDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: seed, width: 1.4),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerColor: AppColors.divider,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
