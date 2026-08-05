import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import '../theme/app_colors.dart';
import '../../models/enums.dart';

/// Resolves task accent color from the current theme accent.
String themeEventColorHex(WidgetRef ref) {
  final accent = ref.read(accentColorProvider);
  return AppColors.toHex(accent.seed);
}

Color themeEventColor(BuildContext context) {
  return Theme.of(context).colorScheme.primary;
}
