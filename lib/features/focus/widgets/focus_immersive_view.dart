import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

class FocusImmersiveView extends StatelessWidget {
  const FocusImmersiveView({
    super.key,
    required this.taskTitle,
    required this.timerLabel,
    required this.onExit,
  });

  final String? taskTitle;
  final String timerLabel;
  final VoidCallback onExit;

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
                    bottom: constraints.maxHeight - centerY + timerFontSize * 0.5 + _taskGap,
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
