import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/providers/app_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

class SoftScheduleApp extends ConsumerWidget {
  const SoftScheduleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accent = ref.watch(accentColorProvider);

    return MaterialApp(
      title: 'Soft Schedule',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(accent),
      darkTheme: AppTheme.dark(accent),
      home: const MainShell(),
    );
  }
}
