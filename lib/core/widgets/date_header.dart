import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/date_time_formats.dart';

/// Date display header (swipe handled by parent page).
class DateHeader extends StatelessWidget {
  const DateHeader({
    super.key,
    required this.selected,
    this.onBackToToday,
  });

  final DateTime selected;
  final VoidCallback? onBackToToday;

  static const _backButtonWidth = 72.0;
  static const _backButtonHeight = 32.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isToday = DateTimeFormats.isSameDay(selected, DateTime.now());
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(width: _backButtonWidth),
          Expanded(
            child: Column(
              children: [
                Text(
                  DateTimeFormats.formatHeader(selected),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.swipeHint,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: _backButtonWidth,
            height: _backButtonHeight,
            child: Opacity(
              opacity: isToday ? 0 : 1,
              child: IgnorePointer(
                ignoring: isToday,
                child: TextButton(
                  onPressed: onBackToToday,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.backToToday,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
