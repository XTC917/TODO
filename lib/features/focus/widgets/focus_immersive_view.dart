import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/providers/focus_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../l10n/app_localizations.dart';

class FocusImmersiveView extends ConsumerWidget {
  const FocusImmersiveView({
    super.key,
    required this.taskTitle,
    required this.timerLabel,
    required this.onExit,
  });

  final String? taskTitle;
  final String timerLabel;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(focusImmersiveDarkModeProvider);
    final palette = ref.watch(themePaletteProvider);
    final immersiveTheme = isDark
        ? AppTheme.dark(palette)
        : AppTheme.light(palette);

    return AnimatedTheme(
      data: immersiveTheme,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      child: Builder(
        builder: (context) => _ImmersiveContent(
          taskTitle: taskTitle,
          timerLabel: timerLabel,
          isDark: isDark,
          onExit: onExit,
          onToggleTheme: () {
            ref.read(focusImmersiveDarkModeProvider.notifier).state = !isDark;
          },
        ),
      ),
    );
  }
}

class _ImmersiveContent extends StatelessWidget {
  const _ImmersiveContent({
    required this.taskTitle,
    required this.timerLabel,
    required this.isDark,
    required this.onExit,
    required this.onToggleTheme,
  });

  final String? taskTitle;
  final String timerLabel;
  final bool isDark;
  final VoidCallback onExit;
  final VoidCallback onToggleTheme;

  static const _taskGap = 28.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final hasTask = taskTitle != null && taskTitle!.isNotEmpty;
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final timerFontSize = isLandscape ? 64.0 : 72.0;

    return Material(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final centerY = constraints.maxHeight / 2;

            return Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: 24,
                  right: 24,
                  top: centerY - timerFontSize * 0.5,
                  child: Text(
                    timerLabel,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 2,
                      height: 1.0,
                      fontSize: timerFontSize,
                    ),
                  ),
                ),
                if (hasTask)
                  Positioned(
                    left: 32,
                    right: 32,
                    bottom: constraints.maxHeight -
                        centerY +
                        timerFontSize * 0.5 +
                        _taskGap,
                    child: Text(
                      taskTitle!,
                      textAlign: TextAlign.center,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: muted,
                        height: 1.3,
                      ),
                    ),
                  ),
                Positioned(
                  left: 8,
                  bottom: 4,
                  child: IconButton(
                    onPressed: onToggleTheme,
                    tooltip: isDark ? l10n.themeLight : l10n.themeDark,
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_outlined
                          : Icons.dark_mode_outlined,
                      size: 20,
                    ),
                    color: muted,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: TextButton(
                    onPressed: onExit,
                    style: TextButton.styleFrom(
                      foregroundColor: muted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    child: Text(l10n.focusImmersiveExit),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
