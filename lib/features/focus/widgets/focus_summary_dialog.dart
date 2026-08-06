import 'package:flutter/material.dart';

import '../../../core/utils/date_time_formats.dart';
import '../../../core/utils/focus_display.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/focus_session.dart';

Future<void> showFocusSummaryDialog({
  required BuildContext context,
  required FocusCompletionResult result,
}) {
  final l10n = AppLocalizations.of(context);

  return showDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: true,
    builder: (ctx) {
      final size = MediaQuery.sizeOf(ctx);
      final taskLabel = result.linkedTaskTitle?.isNotEmpty == true
          ? result.linkedTaskTitle!
          : l10n.focusNoTask;
      final durationLabel = FocusDisplayFormatter.formatDurationLabel(
        l10n,
        result.elapsedSeconds,
        FocusDurationDisplayMode.hour,
      );

      return AlertDialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: size.width < 600 ? 24 : size.width * 0.15,
          vertical: 24,
        ),
        title: Text(l10n.focusCompletedTitle),
        content: SizedBox(
          width: size.width < 600 ? double.maxFinite : 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SummaryRow(label: l10n.focusSummaryTask, value: taskLabel),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: l10n.focusSummaryDuration,
                  value: durationLabel,
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: l10n.focusSummaryStart,
                  value:
                      DateTimeFormats.formatTimeOfDay(result.sessionStartedAt),
                ),
                const SizedBox(height: 10),
                _SummaryRow(
                  label: l10n.focusSummaryEnd,
                  value: DateTimeFormats.formatTimeOfDay(result.endedAt),
                ),
              ],
            ),
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(ctx, rootNavigator: true).pop(),
            child: Text(l10n.done),
          ),
        ],
      );
    },
  );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context)
              .colorScheme
              .onSurface
              .withValues(alpha: 0.55),
        );
    final valueStyle = Theme.of(context).textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: labelStyle),
        const SizedBox(height: 4),
        Text(value, style: valueStyle),
      ],
    );
  }
}
