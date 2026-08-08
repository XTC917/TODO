import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_colors.dart';

/// Resolves task accent color from the current theme accent.
String themeEventColorHex(WidgetRef ref) {
  final palette = ref.read(themePaletteProvider);
  return AppColors.toHex(palette.seedColor);
}

Color themeEventColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}
