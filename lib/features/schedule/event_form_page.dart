import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_time_formats.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

class EventFormPage extends ConsumerStatefulWidget {
  const EventFormPage({
    super.key,
    this.eventId,
    this.initialDate,
    this.forceTaskType,
  });

  final int? eventId;
  final DateTime? initialDate;
  final TaskType? forceTaskType;

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
  late String _color;
  late TaskType _taskType;
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
    _color = AppColors.toHex(AppColors.eventPalette.first);
    _taskType = widget.forceTaskType ?? TaskType.schedule;
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
      _date = DateTimeFormats.parseDate(event.date);
      _start = _parseTime(event.startTime);
      _end = _parseTime(event.endTime);
      _color = event.color;
      _taskType = event.taskType;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit' : 'Add'),
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  if (widget.forceTaskType == null) ...[
                    Text('Task Type',
                        style: Theme.of(context).textTheme.titleSmall),
                    RadioListTile<TaskType>(
                      title: const Text('Schedule'),
                      value: TaskType.schedule,
                      groupValue: _taskType,
                      onChanged: (v) => setState(() => _taskType = v!),
                    ),
                    RadioListTile<TaskType>(
                      title: const Text('Todo'),
                      value: TaskType.todo,
                      groupValue: _taskType,
                      onChanged: (v) => setState(() => _taskType = v!),
                    ),
                  ],
                  _PickerTile(
                    label: 'Date',
                    value: DateTimeFormats.formatDate(_date),
                    icon: Icons.calendar_today_rounded,
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _PickerTile(
                          label: 'Start',
                          value: _formatTime(_start),
                          icon: Icons.schedule_rounded,
                          onTap: () => _pickTime(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PickerTile(
                          label: 'End',
                          value: _formatTime(_end),
                          icon: Icons.schedule_rounded,
                          onTap: () => _pickTime(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('Repeat',
                      style: Theme.of(context).textTheme.titleSmall),
                  ...RepeatType.values.map(
                    (r) => RadioListTile<RepeatType>(
                      title: Text(r.label),
                      value: r,
                      groupValue: _repeatType,
                      onChanged: (v) => setState(() => _repeatType = v!),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Reminder',
                      style: Theme.of(context).textTheme.titleSmall),
                  DropdownButtonFormField<ReminderType>(
                    value: _reminderType,
                    decoration: const InputDecoration(labelText: 'Reminder'),
                    items: ReminderType.values
                        .map((r) =>
                            DropdownMenuItem(value: r, child: Text(r.label)))
                        .toList(),
                    onChanged: (v) => setState(() => _reminderType = v!),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: AppColors.eventPalette.map((color) {
                      final hex = AppColors.toHex(color);
                      final selected = hex == _color;
                      return GestureDetector(
                        onTap: () => setState(() => _color = hex),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Note'),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _save,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(widget.isEditing ? 'Save' : 'Create'),
                  ),
                ],
              ),
            ),
    );
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final startMin = _start.hour * 60 + _start.minute;
    final endMin = _end.hour * 60 + _end.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    setState(() => _loading = true);
    final actions = ref.read(eventActionsProvider);
    final date = DateTimeFormats.formatDate(_date);

    try {
      if (widget.isEditing && _existing != null) {
        await actions.update(
          _existing!.copyWith(
            title: _titleController.text,
            date: date,
            startTime: _formatTime(_start),
            endTime: _formatTime(_end),
            note: _noteController.text,
            color: _color,
            taskType: _taskType,
            repeatType: _repeatType,
            reminderType: _reminderType,
          ),
        );
      } else {
        await actions.create(
          EventDraft(
            title: _titleController.text,
            date: date,
            startTime: _formatTime(_start),
            endTime: _formatTime(_end),
            note: _noteController.text,
            color: _color,
            taskType: _taskType,
            repeatType: _repeatType,
            reminderType: _reminderType,
          ),
        );
        ref.read(homeSelectedDateProvider.notifier).state = _date;
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
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
          padding: const EdgeInsets.all(14),
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
