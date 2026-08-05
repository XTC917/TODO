import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/enum_labels.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/event_constants.dart';
import '../../core/utils/theme_event_color.dart';
import '../../core/utils/date_time_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

class EventFormPage extends ConsumerStatefulWidget {
  const EventFormPage({
    super.key,
    this.eventId,
    this.initialDate,
    this.forceTaskType,
    this.forceTodoTimeMode,
  });

  final int? eventId;
  final DateTime? initialDate;
  final TaskType? forceTaskType;
  final TodoTimeMode? forceTodoTimeMode;

  bool get isEditing => eventId != null;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late TimeOfDay _deadline;
  late TaskType _taskType;
  late TodoTimeMode _todoTimeMode;
  late RepeatType _repeatType;
  late ReminderType _reminderType;
  Event? _existing;
  bool _loading = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTimeFormats.dateOnly(widget.initialDate ?? now);
    _start = TimeOfDay(hour: now.hour, minute: (now.minute ~/ 5) * 5);
    final endMinutes = _start.hour * 60 + _start.minute + 60;
    _end = TimeOfDay(hour: (endMinutes ~/ 60) % 24, minute: endMinutes % 60);
    _deadline = const TimeOfDay(hour: 18, minute: 0);
    _taskType = widget.forceTaskType ?? TaskType.todo;
    _todoTimeMode = widget.forceTodoTimeMode ?? TodoTimeMode.timeBlock;
    _repeatType = RepeatType.oneTime;
    _reminderType = ReminderType.none;

    if (widget.isEditing) {
      Future.microtask(_loadExisting);
    } else {
      _initialized = true;
    }
  }

  Future<void> _loadExisting() async {
    final event =
        await ref.read(eventRepositoryProvider).getById(widget.eventId!);
    if (!mounted) return;
    if (event == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _existing = event;
      _titleController.text = event.title;
      _noteController.text = event.note ?? '';
      _date = event.hasDate
          ? DateTimeFormats.parseDate(event.date)
          : DateTimeFormats.dateOnly(DateTime.now());
      if (event.startTime.isNotEmpty) {
        _start = _parseTime(event.startTime);
      }
      if (event.endTime.isNotEmpty) {
        _end = _parseTime(event.endTime);
        _deadline = _parseTime(event.endTime);
      }
      _taskType = event.taskType;
      _todoTimeMode = event.todoTimeMode;
      _repeatType = event.repeatType;
      _reminderType = event.reminderType;
      _initialized = true;
    });
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

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _showStartEnd =>
      _taskType == TaskType.schedule ||
      (_taskType == TaskType.todo && _todoTimeMode == TodoTimeMode.timeBlock);

  bool get _showDeadline =>
      _taskType == TaskType.todo && _todoTimeMode == TodoTimeMode.deadline;

  bool get _showNoTime =>
      _taskType == TaskType.todo && _todoTimeMode == TodoTimeMode.noTime;

  bool get _showDate => !_showNoTime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? l10n.editTitle : l10n.addTitle),
        actions: [
          if (widget.isEditing)
            IconButton(
              onPressed: _loading ? null : _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator.adaptive())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      children: _formFields(context),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: FilledButton(
                        onPressed: _loading ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(widget.isEditing ? l10n.save : l10n.create),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _formFields(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      TextFormField(
        controller: _titleController,
        decoration: InputDecoration(labelText: l10n.titleLabel),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return l10n.titleRequired;
          }
          return null;
        },
      ),
      const SizedBox(height: 10),
      if (widget.forceTaskType == null) ...[
        Text(l10n.typeLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SegmentedButton<TaskType>(
          segments: [
            ButtonSegment(value: TaskType.todo, label: Text(l10n.taskTypeTodo)),
            ButtonSegment(
              value: TaskType.schedule,
              label: Text(l10n.taskTypeSchedule),
            ),
          ],
          selected: {_taskType},
          onSelectionChanged: (s) => setState(() => _taskType = s.first),
        ),
        const SizedBox(height: 10),
      ],
      if (_taskType == TaskType.todo && widget.forceTodoTimeMode == null) ...[
        Text(l10n.timeModeLabel, style: Theme.of(context).textTheme.labelLarge),
        const SizedBox(height: 6),
        SegmentedButton<TodoTimeMode>(
          segments: [
            ButtonSegment(
              value: TodoTimeMode.timeBlock,
              label: Text(l10n.timeBlock),
            ),
            ButtonSegment(
              value: TodoTimeMode.deadline,
              label: Text(l10n.deadline),
            ),
            ButtonSegment(
              value: TodoTimeMode.noTime,
              label: Text(l10n.noTime),
            ),
          ],
          selected: {_todoTimeMode},
          onSelectionChanged: (s) => setState(() => _todoTimeMode = s.first),
        ),
        const SizedBox(height: 10),
      ],
      if (_showDate) ...[
        _PickerTile(
          label: l10n.dateLabel,
          value: DateTimeFormats.formatDate(_date),
          icon: Icons.calendar_today_rounded,
          onTap: _pickDate,
        ),
        const SizedBox(height: 8),
      ],
      if (_showStartEnd) ...[
        Row(
          children: [
            Expanded(
              child: _PickerTile(
                label: l10n.startLabel,
                value: _formatTime(_start),
                icon: Icons.schedule_rounded,
                onTap: () => _pickTime(isStart: true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PickerTile(
                label: l10n.endLabel,
                value: _formatTime(_end),
                icon: Icons.schedule_rounded,
                onTap: () => _pickTime(isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
      if (_showDeadline) ...[
        _PickerTile(
          label: l10n.deadlineLabel,
          value: _formatTime(_deadline),
          icon: Icons.access_time_rounded,
          onTap: _pickDeadline,
        ),
        const SizedBox(height: 8),
      ],
      TextFormField(
        controller: _noteController,
        minLines: 1,
        maxLines: 3,
        decoration: InputDecoration(labelText: l10n.noteLabel),
      ),
      const SizedBox(height: 8),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          l10n.moreOptions,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        children: [
          ...RepeatType.values.map(
            (r) => RadioListTile<RepeatType>(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: Text(repeatTypeLabel(l10n, r)),
              value: r,
              groupValue: _repeatType,
              onChanged: (v) => setState(() => _repeatType = v!),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DropdownButtonFormField<ReminderType>(
              initialValue: _reminderType,
              isDense: true,
              decoration: InputDecoration(labelText: l10n.reminderLabel),
              items: ReminderType.values
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(reminderTypeLabel(l10n, r)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _reminderType = v!),
            ),
          ),
        ],
      ),
    ];
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _date = DateTimeFormats.dateOnly(picked));
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  Future<void> _pickDeadline() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _deadline,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  (String date, String start, String end) _resolveFields() {
    if (_showNoTime) {
      return (kNoDate, '', '');
    }
    final dateStr = DateTimeFormats.formatDate(_date);
    if (_taskType == TaskType.schedule ||
        _todoTimeMode == TodoTimeMode.timeBlock) {
      return (dateStr, _formatTime(_start), _formatTime(_end));
    }
    if (_todoTimeMode == TodoTimeMode.deadline) {
      return (dateStr, '00:00', _formatTime(_deadline));
    }
    return (dateStr, '00:00', '00:00');
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).titleRequired)),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    if (_showStartEnd) {
      final startMin = _start.hour * 60 + _start.minute;
      final endMin = _end.hour * 60 + _end.minute;
      if (endMin <= startMin) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).endTimeAfterStart)),
        );
        return;
      }
    }

    setState(() => _loading = true);
    final actions = ref.read(eventActionsProvider);
    final fields = _resolveFields();
    final color = themeEventColorHex(ref);
    final todoMode =
        _taskType == TaskType.schedule ? TodoTimeMode.timeBlock : _todoTimeMode;

    try {
      if (widget.isEditing && _existing != null) {
        await actions.update(
          _existing!.copyWith(
            title: title,
            date: fields.$1,
            startTime: fields.$2,
            endTime: fields.$3,
            note: _noteController.text,
            color: color,
            taskType: _taskType,
            todoTimeMode: todoMode,
            repeatType: _repeatType,
            reminderType: _reminderType,
          ),
        );
      } else {
        await actions.create(
          EventDraft(
            title: title,
            date: fields.$1,
            startTime: fields.$2,
            endTime: fields.$3,
            note: _noteController.text,
            color: color,
            taskType: _taskType,
            todoTimeMode: todoMode,
            repeatType: _repeatType,
            reminderType: _reminderType,
          ),
        );
        if (fields.$1.isNotEmpty) {
          ref.read(homeSelectedDateProvider.notifier).state =
              DateTimeFormats.parseDate(fields.$1);
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveFailedRetry)),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(eventActionsProvider).delete(widget.eventId!);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context).textTheme.labelMedium),
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
