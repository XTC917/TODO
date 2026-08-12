import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/date_time_formats.dart';
import '../../../core/utils/event_constants.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/event.dart';

Future<FocusRecord?> showFocusRecordEditSheet({
  required BuildContext context,
  required FocusRecord record,
}) async {
  return showModalBottomSheet<FocusRecord>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _FocusRecordEditSheet(record: record),
  );
}

class _FocusRecordEditSheet extends StatefulWidget {
  const _FocusRecordEditSheet({required this.record});

  final FocusRecord record;

  @override
  State<_FocusRecordEditSheet> createState() => _FocusRecordEditSheetState();
}

class _FocusRecordEditSheetState extends State<_FocusRecordEditSheet> {
  late final TextEditingController _titleController;
  late DateTime _date;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.record.taskTitle ?? '');
    _date = DateTimeFormats.parseDate(widget.record.date);
    _startTime = _parseTime(widget.record.startTime);
    _endTime = _parseTime(widget.record.endTime);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  int _durationSeconds() {
    var start = _combine(_date, _startTime);
    var end = _combine(_date, _endTime);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    return end.difference(start).inSeconds;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  void _save() {
    final title = _titleController.text.trim();
    final duration = _durationSeconds();
    if (duration <= 0) return;

    var end = _combine(_date, _endTime);
    final start = _combine(_date, _startTime);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    Navigator.pop(
      context,
      widget.record.copyWith(
        date: DateTimeFormats.formatDate(_date),
        startTime: _formatTime(_startTime),
        endTime: DateTimeFormats.formatTimeOfDay(end),
        durationSeconds: duration,
        taskTitle: title.isEmpty ? null : title,
        clearTaskTitle: title.isEmpty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final duration = _durationSeconds();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.focusEditRecord,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                maxLength: kMaxEventTitleLength,
                decoration: InputDecoration(
                  labelText: l10n.focusRecordTaskLabel,
                  counterText: '',
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kMaxEventTitleLength),
                ],
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.focusRecordDate),
                subtitle: Text(DateTimeFormats.formatDate(_date)),
                trailing: const Icon(Icons.calendar_today_outlined, size: 20),
                onTap: _pickDate,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.focusRecordStartTime),
                subtitle: Text(_formatTime(_startTime)),
                trailing: const Icon(Icons.schedule_outlined, size: 20),
                onTap: _pickStartTime,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.focusRecordEndTime),
                subtitle: Text(_formatTime(_endTime)),
                trailing: const Icon(Icons.schedule_outlined, size: 20),
                onTap: _pickEndTime,
              ),
              const SizedBox(height: 4),
              Text(
                '${l10n.focusSummaryDuration}: ${DateTimeFormats.formatDuration(duration > 0 ? duration : 0)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: duration > 0 ? _save : null,
                child: Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
