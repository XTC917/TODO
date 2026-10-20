import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../utils/date_time_formats.dart';
import '../utils/todo_date_filter.dart';

/// Horizontal date-range chips for the Todo page.
///
/// Mirrors the search page chips (height 28, rounded 16, primary tint) so the
/// two list filters feel like the same component family.
class TodoFilterBar extends StatelessWidget {
  const TodoFilterBar({
    super.key,
    required this.state,
    required this.onPresetSelected,
    required this.onCustomTap,
  });

  final TodoViewState state;

  /// Called for every non-custom preset.
  final ValueChanged<TodoRangePreset> onPresetSelected;

  /// Called when the user taps the custom range chip (always opens the picker).
  final VoidCallback onCustomTap;

  static const _options = [
    TodoRangePreset.today,
    TodoRangePreset.next7,
    TodoRangePreset.next30,
    TodoRangePreset.all,
    TodoRangePreset.custom,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final customRange = _customRangeLabel();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 2),
      child: SizedBox(
        height: 28,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final option in _options)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: TodoFilterChip(
                    label: option == TodoRangePreset.custom &&
                            state.preset == TodoRangePreset.custom &&
                            customRange != null
                        ? customRange
                        : _label(l10n, option),
                    selected: state.preset == option,
                    onTap: () {
                      if (option == TodoRangePreset.custom) {
                        onCustomTap();
                      } else {
                        onPresetSelected(option);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String? _customRangeLabel() {
    final start = normalizeDateKey(state.customStart);
    final end = normalizeDateKey(state.customEnd);
    if (start == null || end == null) return null;
    final startDate = DateTimeFormats.parseDate(start);
    final endDate = DateTimeFormats.parseDate(end);
    // Keep the chip compact, but show years when the range crosses a year.
    if (startDate.year != endDate.year) {
      return '${DateTimeFormats.sectionDate.format(startDate)}'
          '–${DateTimeFormats.sectionDate.format(endDate)}';
    }
    return '${DateTimeFormats.formatMonthDay(startDate)}'
        '–${DateTimeFormats.formatMonthDay(endDate)}';
  }

  String _label(AppLocalizations l10n, TodoRangePreset option) {
    return switch (option) {
      TodoRangePreset.today => l10n.todoRangeToday,
      TodoRangePreset.next7 => l10n.todoRangeNext7,
      TodoRangePreset.next30 => l10n.todoRangeNext30,
      TodoRangePreset.all => l10n.todoRangeAll,
      TodoRangePreset.custom => l10n.todoRangeCustom,
    };
  }
}

class TodoFilterChip extends StatelessWidget {
  const TodoFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.16)
          : scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: selected
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.5),
                    width: 1,
                  ),
                )
              : null,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? scheme.primary
                  : scheme.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }
}
