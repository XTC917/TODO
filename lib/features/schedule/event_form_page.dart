import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/enum_labels.dart';
import '../../core/providers/app_providers.dart';
import '../../core/utils/event_constants.dart';
import '../../core/utils/theme_event_color.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/widgets/reminder_picker_sheet.dart';
import '../../core/widgets/repeat_scope_dialog.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/event.dart';
import '../../models/reminder_config.dart';

import '../../core/utils/parsed_task.dart';
import '../../core/utils/quick_add_form_bridge.dart';
import '../../core/utils/quick_add_parser.dart';
import 'quick_add_page.dart';

class EventFormPage extends ConsumerStatefulWidget {
  const EventFormPage({
    super.key,
    this.eventId,
    this.editingOccurrence,
    this.initialDate,
    this.initialTitle,
    this.initialStartTime,
    this.initialEndTime,
    this.initialTaskType,
    this.initialTodoTimeMode,
    this.forceTaskType,
    this.forceTodoTimeMode,
    this.initialReminderOffsetsSeconds,
  });

  final int? eventId;
  /// The occurrence shown in the list (date may differ from stored row).
  final Event? editingOccurrence;
  final DateTime? initialDate;
  final String? initialTitle;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final TaskType? initialTaskType;
  final TodoTimeMode? initialTodoTimeMode;
  final TaskType? forceTaskType;
  final TodoTimeMode? forceTodoTimeMode;
  final List<int>? initialReminderOffsetsSeconds;

  bool get isEditing => eventId != null;

  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();
  final _titleFocus = FocusNode();
  final _noteFocus = FocusNode();

  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late TimeOfDay _deadline;
  late TaskType _taskType;
  late TodoTimeMode _todoTimeMode;
  late RepeatType _repeatType;
  List<int> _reminderOffsetsSeconds = const [];
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
    _taskType =
        widget.forceTaskType ?? widget.initialTaskType ?? TaskType.todo;
    _todoTimeMode = widget.forceTodoTimeMode ??
        widget.initialTodoTimeMode ??
        TodoTimeMode.timeBlock;
    _repeatType = RepeatType.oneTime;
    _reminderOffsetsSeconds = const [];

    if (!widget.isEditing) {
      if (widget.initialTitle != null && widget.initialTitle!.isNotEmpty) {
        _titleController.text = widget.initialTitle!;
      }
      if (widget.initialStartTime != null) {
        _start = widget.initialStartTime!;
      }
      if (widget.initialEndTime != null) {
        _end = widget.initialEndTime!;
      } else if (widget.initialStartTime != null) {
        final startMin = _start.hour * 60 + _start.minute;
        final endMin = startMin + 60;
        _end = TimeOfDay(hour: (endMin ~/ 60) % 24, minute: endMin % 60);
      }
      if (widget.forceTodoTimeMode == TodoTimeMode.deadline ||
          widget.initialTodoTimeMode == TodoTimeMode.deadline) {
        if (widget.initialEndTime != null) {
          _deadline = widget.initialEndTime!;
        } else if (widget.initialStartTime != null) {
          _deadline = widget.initialStartTime!;
        }
      }
      if (widget.initialReminderOffsetsSeconds != null &&
          widget.initialReminderOffsetsSeconds!.isNotEmpty) {
        _reminderOffsetsSeconds = widget.initialReminderOffsetsSeconds!;
      }
    }

    if (widget.isEditing) {
      Future.microtask(_loadExisting);
    } else {
      _initialized = true;
    }
  }

  Event? _occurrence;

  Future<void> _loadExisting() async {
    final event =
        await ref.read(eventRepositoryProvider).getById(widget.eventId!);
    if (!mounted) return;
    if (event == null) {
      Navigator.of(context).pop();
      return;
    }
    final display = widget.editingOccurrence ?? event;
    setState(() {
      _existing = event;
      _occurrence = display;
      _titleController.text = display.title;
      _noteController.text = display.note ?? '';
      _date = display.hasDate
          ? DateTimeFormats.parseDate(display.date)
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
      _reminderOffsetsSeconds = event.reminderOffsetsSeconds;
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
    _titleFocus.dispose();
    _noteFocus.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _applyQuickAddPrefill(ParsedTask parsed) {
    final prefill = QuickAddPrefill.fromParsed(
      parsed: parsed,
      fallbackDate: _date,
    );
    setState(() {
      _titleController.text = prefill.title;
      if (prefill.date != null) {
        _date = DateTimeFormats.dateOnly(prefill.date!);
      }
      if (widget.forceTaskType == null) {
        _taskType = prefill.taskType;
      }
      if (widget.forceTodoTimeMode == null) {
        _todoTimeMode = prefill.todoTimeMode;
      }
      if (prefill.startTime != null) {
        _start = prefill.startTime!;
      }
      if (prefill.endTime != null) {
        _end = prefill.endTime!;
      } else if (prefill.startTime != null) {
        final startMin = _start.hour * 60 + _start.minute;
        final endMin = startMin + 60;
        _end = TimeOfDay(hour: (endMin ~/ 60) % 24, minute: endMin % 60);
      }
      if (prefill.deadline != null) {
        _deadline = prefill.deadline!;
      }
      _reminderOffsetsSeconds = prefill.reminderOffsetsSeconds;
    });
  }

  Future<void> _openQuickAdd() async {
    if (resolveQuickAddParserLanguage(ref.read(appLanguageProvider)) == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).quickAddUnsupportedLanguage),
        ),
      );
      return;
    }

    final result = await Navigator.of(context).push<Object?>(
      MaterialPageRoute(
        builder: (_) => QuickAddPage(
          initialDate: _date,
          forceTaskType: widget.forceTaskType,
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (result is ParsedTask) {
      _applyQuickAddPrefill(result);
    }
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
      if (!widget.isEditing) ...[
        OutlinedButton.icon(
          onPressed: _openQuickAdd,
          icon: const Icon(Icons.bolt_outlined),
          label: Text(l10n.quickAddTitle),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(44),
            alignment: Alignment.centerLeft,
          ),
        ),
        const SizedBox(height: 12),
      ],
      TextFormField(
        controller: _titleController,
        focusNode: _titleFocus,
        maxLength: kMaxEventTitleLength,
        textInputAction: TextInputAction.next,
        onFieldSubmitted: (_) => _noteFocus.requestFocus(),
        decoration: InputDecoration(
          labelText: l10n.titleLabel,
          counterText: '',
          suffixIcon: IconButton(
            tooltip: MaterialLocalizations.of(context).okButtonLabel,
            icon: const Icon(Icons.check_rounded, size: 20),
            onPressed: _dismissKeyboard,
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) {
          if (v == null || v.trim().isEmpty) {
            return l10n.titleRequired;
          }
          if (v.length > kMaxEventTitleLength) {
            return l10n.titleTooLong(kMaxEventTitleLength);
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
        focusNode: _noteFocus,
        minLines: 1,
        maxLines: 5,
        maxLength: kMaxEventNoteLength,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _dismissKeyboard(),
        decoration: InputDecoration(
          labelText: l10n.noteLabel,
          alignLabelWithHint: true,
          suffixIcon: IconButton(
            tooltip: MaterialLocalizations.of(context).okButtonLabel,
            icon: const Icon(Icons.check_rounded, size: 20),
            onPressed: _dismissKeyboard,
          ),
        ),
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) {
          if (v != null && v.length > kMaxEventNoteLength) {
            return l10n.noteTooLong(kMaxEventNoteLength);
          }
          return null;
        },
      ),
      const SizedBox(height: 8),
      if (_showDate || _showStartEnd || _showDeadline)
        _PickerTile(
          label: l10n.reminderLabel,
          value: formatReminderOffsetsForTile(l10n, _reminderOffsetsSeconds),
          icon: Icons.notifications_none_rounded,
          onTap: _pickReminder,
        ),
      if (_showDate || _showStartEnd || _showDeadline)
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
          const SizedBox(height: 8),
        ],
      ),
    ];
  }

  DateTime? _reminderAnchorDateTime() {
    final fields = _resolveFields();
    final date = fields.$1;
    if (date.isEmpty) return null;
    if (_taskType == TaskType.todo && _todoTimeMode == TodoTimeMode.noTime) {
      return null;
    }
    if (_taskType == TaskType.todo && _todoTimeMode == TodoTimeMode.deadline) {
      final t = fields.$3;
      if (t.isEmpty) return null;
      final d = DateTime.parse(date);
      final parts = t.split(':');
      return DateTime(
        d.year,
        d.month,
        d.day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      );
    }
    final t = fields.$2;
    if (t.isEmpty) return null;
    final d = DateTime.parse(date);
    final parts = t.split(':');
    return DateTime(
      d.year,
      d.month,
      d.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> _pickReminder() async {
    _dismissKeyboard();
    final picked = await showReminderPickerSheet(
      context: context,
      currentOffsetsSeconds: _reminderOffsetsSeconds,
      anchorDateTime: _reminderAnchorDateTime(),
    );
    setState(() => _reminderOffsetsSeconds = picked);
  }

  Future<void> _pickDate() async {
    _dismissKeyboard();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2040),
    );
    if (picked != null) setState(() => _date = DateTimeFormats.dateOnly(picked));
  }

  Future<void> _pickTime({required bool isStart}) async {
    _dismissKeyboard();
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
    _dismissKeyboard();
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
        final updated = _existing!.copyWith(
          title: title,
          date: fields.$1,
          startTime: fields.$2,
          endTime: fields.$3,
          note: _noteController.text,
          color: color,
          taskType: _taskType,
          todoTimeMode: todoMode,
          repeatType: _repeatType,
          reminderOffsetsSeconds: _reminderOffsetsSeconds,
          clearReminderOffsets: _reminderOffsetsSeconds.isEmpty,
        );
        final occurrence = (_occurrence ?? _existing!).copyWith(date: fields.$1);
        if (occurrence.isRepeatSeriesOccurrence) {
          final scope = await pickRepeatScope(
            context,
            action: RepeatScopeAction.edit,
            event: occurrence,
          );
          if (scope == null) {
            if (mounted) setState(() => _loading = false);
            return;
          }
          await actions.updateWithScope(occurrence, updated, scope);
        } else {
          await actions.update(updated.copyWith(id: occurrence.id));
        }
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
            reminderOffsetsSeconds: _reminderOffsetsSeconds,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveFailedRetry)),
      );
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!widget.isEditing && fields.$1.isNotEmpty) {
      try {
        ref.read(homeSelectedDateProvider.notifier).state =
            DateTimeFormats.parseDate(fields.$1);
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() => _loading = false);
    Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    if (_existing == null) return;
    final occurrence = _occurrence ?? _existing!;
    final scope = await pickDeleteScope(context, event: occurrence);
    if (scope == null) return;
    try {
      await ref.read(eventActionsProvider).deleteWithScope(occurrence, scope);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveFailedRetry)),
      );
    }
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
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    Text(
                      value,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
