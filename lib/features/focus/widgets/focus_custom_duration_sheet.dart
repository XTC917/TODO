import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';

/// Returns total seconds, or null if dismissed.
Future<int?> showFocusCustomDurationSheet({
  required BuildContext context,
  int initialSeconds = 30 * 60,
}) async {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _FocusCustomDurationSheet(initialSeconds: initialSeconds),
  );
}

class _FocusCustomDurationSheet extends StatefulWidget {
  const _FocusCustomDurationSheet({required this.initialSeconds});

  final int initialSeconds;

  @override
  State<_FocusCustomDurationSheet> createState() =>
      _FocusCustomDurationSheetState();
}

class _FocusCustomDurationSheetState extends State<_FocusCustomDurationSheet> {
  static const _minuteSteps = [0, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];

  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late int _hourIndex;
  late int _minuteIndex;

  @override
  void initState() {
    super.initState();
    final h = widget.initialSeconds ~/ 3600;
    final m = (widget.initialSeconds % 3600) ~/ 60;
    _hourIndex = h.clamp(0, 23);
    _minuteIndex = _nearestMinuteIndex(m);
    _hourController = FixedExtentScrollController(initialItem: _hourIndex);
    _minuteController = FixedExtentScrollController(initialItem: _minuteIndex);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  int _nearestMinuteIndex(int minutes) {
    var best = 0;
    var diff = 999;
    for (var i = 0; i < _minuteSteps.length; i++) {
      final d = (minutes - _minuteSteps[i]).abs();
      if (d < diff) {
        diff = d;
        best = i;
      }
    }
    return best;
  }

  int get _totalSeconds =>
      _hourIndex * 3600 + _minuteSteps[_minuteIndex] * 60;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final total = _totalSeconds;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.focusCustomDuration,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.focusHoursLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: _hourController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() => _hourIndex = index);
                            },
                            children: List.generate(
                              24,
                              (i) => Center(
                                child: Text(
                                  '$i',
                                  style: theme.textTheme.titleLarge,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          l10n.focusMinutesFieldLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: _minuteController,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setState(() => _minuteIndex = index);
                            },
                            children: _minuteSteps
                                .map(
                                  (m) => Center(
                                    child: Text(
                                      m.toString().padLeft(2, '0'),
                                      style: theme.textTheme.titleLarge,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: total <= 0
                  ? null
                  : () => Navigator.pop(context, total),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
