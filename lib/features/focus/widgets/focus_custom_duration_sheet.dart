import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  late final TextEditingController _hoursController;
  late final TextEditingController _minutesController;

  @override
  void initState() {
    super.initState();
    final h = widget.initialSeconds ~/ 3600;
    final m = (widget.initialSeconds % 3600) ~/ 60;
    _hoursController = TextEditingController(text: '$h');
    _minutesController = TextEditingController(text: '$m');
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  int? _totalSeconds() {
    final h = int.tryParse(_hoursController.text.trim()) ?? 0;
    final m = int.tryParse(_minutesController.text.trim()) ?? 0;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    final total = h * 3600 + m * 60;
    return total > 0 ? total : null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final total = _totalSeconds();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          16 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.focusCustomDuration,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.focusHoursLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.focusMinutesFieldLabel,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: total == null
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
