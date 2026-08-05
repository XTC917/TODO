import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../../models/reminder_config.dart';

/// Bottom sheet for choosing one or more reminder offsets (seconds before start).
/// Returns [currentOffsetsSeconds] if dismissed without confirming.
Future<List<int>> showReminderPickerSheet({
  required BuildContext context,
  required List<int> currentOffsetsSeconds,
  DateTime? anchorDateTime,
}) async {
  final picked = await showModalBottomSheet<List<int>?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ReminderPickerSheet(
      currentOffsetsSeconds: currentOffsetsSeconds,
      anchorDateTime: anchorDateTime,
    ),
  );
  return picked ?? currentOffsetsSeconds;
}

class _ReminderPickerSheet extends StatefulWidget {
  const _ReminderPickerSheet({
    required this.currentOffsetsSeconds,
    this.anchorDateTime,
  });

  final List<int> currentOffsetsSeconds;
  final DateTime? anchorDateTime;

  @override
  State<_ReminderPickerSheet> createState() => _ReminderPickerSheetState();
}

class _ReminderPickerSheetState extends State<_ReminderPickerSheet> {
  late Set<int> _selected;
  /// Custom offsets visible as list rows this session; removed when unchecked.
  late Set<int> _visibleCustomOffsets;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentOffsetsSeconds.toSet();
    _visibleCustomOffsets =
        ReminderPresets.customOffsetsFrom(widget.currentOffsetsSeconds).toSet();
  }

  List<int> get _sortedVisibleCustoms {
    final list = _visibleCustomOffsets.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  void _toggle(int offset) {
    setState(() {
      if (_selected.contains(offset)) {
        _selected.remove(offset);
        if (!ReminderPresets.isPresetOffset(offset)) {
          _visibleCustomOffsets.remove(offset);
        }
      } else if (_selected.length < kMaxRemindersPerEvent) {
        _selected.add(offset);
      }
    });
  }

  Future<void> _addCustom() async {
    final custom = await showCustomReminderSheet(
      context: context,
      currentOffsetSeconds: null,
    );
    if (custom == null || !mounted) return;
    setState(() {
      if (_selected.length >= kMaxRemindersPerEvent) return;
      _selected.add(custom);
      if (!ReminderPresets.isPresetOffset(custom)) {
        _visibleCustomOffsets.add(custom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final anchor = widget.anchorDateTime;
    Duration? untilStart;
    if (anchor != null) {
      untilStart = anchor.difference(DateTime.now());
    }

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.reminderLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (untilStart != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    formatDurationUntil(l10n, untilStart),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (_selected.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    formatReminderOffsetsSummary(l10n, _selected.toList()),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                ListTile(
                  title: Text(l10n.reminderNone),
                  trailing: _selected.isEmpty
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => setState(() {
                    _selected.clear();
                    _visibleCustomOffsets.clear();
                  }),
                ),
                for (final value in ReminderPresets.selectableValues)
                  if (value != kReminderCustomPicker)
                    ListTile(
                      title: Text(formatReminderOffset(l10n, value)),
                      trailing: _selected.contains(value!)
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      onTap: () => _toggle(value),
                    ),
                for (final offset in _sortedVisibleCustoms)
                  ListTile(
                    title: Text(formatReminderOffset(l10n, offset)),
                    trailing: _selected.contains(offset)
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () => _toggle(offset),
                  ),
                ListTile(
                  title: Text(l10n.reminderCustomOption),
                  trailing: const Icon(Icons.add),
                  onTap: _addCustom,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: FilledButton(
              onPressed: () {
                final result = _selected.toList()..sort((a, b) => b.compareTo(a));
                Navigator.pop(context, result);
              },
              child: Text(l10n.done),
            ),
          ),
        ],
      ),
    );
  }
}

/// Two-step custom reminder: amount → unit.
Future<int?> showCustomReminderSheet({
  required BuildContext context,
  required int? currentOffsetSeconds,
}) async {
  return showModalBottomSheet<int?>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _CustomReminderSheet(
      initialOffsetSeconds: currentOffsetSeconds,
    ),
  );
}

enum _CustomReminderUnit { minutes, hours, days }

class _CustomReminderSheet extends StatefulWidget {
  const _CustomReminderSheet({required this.initialOffsetSeconds});

  final int? initialOffsetSeconds;

  @override
  State<_CustomReminderSheet> createState() => _CustomReminderSheetState();
}

class _CustomReminderSheetState extends State<_CustomReminderSheet> {
  late final TextEditingController _amountController;
  _CustomReminderUnit _unit = _CustomReminderUnit.minutes;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialOffsetSeconds;
    if (initial != null && initial > 0) {
      if (initial % (24 * 60 * 60) == 0) {
        _unit = _CustomReminderUnit.days;
        _amountController = TextEditingController(
          text: '${initial ~/ (24 * 60 * 60)}',
        );
      } else if (initial % (60 * 60) == 0) {
        _unit = _CustomReminderUnit.hours;
        _amountController = TextEditingController(
          text: '${initial ~/ (60 * 60)}',
        );
      } else {
        _amountController = TextEditingController(
          text: '${(initial / 60).round()}',
        );
      }
    } else {
      _amountController = TextEditingController(text: '15');
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? _computeOffset() {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return null;
    return switch (_unit) {
      _CustomReminderUnit.minutes => amount * 60,
      _CustomReminderUnit.hours => amount * 60 * 60,
      _CustomReminderUnit.days => amount * 24 * 60 * 60,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final preview = _computeOffset();

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
              l10n.reminderCustomTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: l10n.reminderEnterAmount,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            SegmentedButton<_CustomReminderUnit>(
              segments: [
                ButtonSegment(
                  value: _CustomReminderUnit.minutes,
                  label: Text(l10n.reminderUnitMinutes),
                ),
                ButtonSegment(
                  value: _CustomReminderUnit.hours,
                  label: Text(l10n.reminderUnitHours),
                ),
                ButtonSegment(
                  value: _CustomReminderUnit.days,
                  label: Text(l10n.reminderUnitDays),
                ),
              ],
              selected: {_unit},
              onSelectionChanged: (s) => setState(() => _unit = s.first),
            ),
            if (preview != null) ...[
              const SizedBox(height: 12),
              Text(
                formatReminderOffset(l10n, preview),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: preview == null
                  ? null
                  : () => Navigator.pop(context, preview),
              child: Text(l10n.save),
            ),
          ],
        ),
      ),
    );
  }
}
