import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/utils/quick_add_form_bridge.dart';
import '../../core/utils/parsed_task.dart';
import '../../core/utils/parsed_task_draft.dart';
import '../../core/utils/quick_add_parser.dart';
import '../../l10n/app_localizations.dart';
import '../../models/reminder_config.dart';
import '../../models/enums.dart';

enum _QuickAddStep { input, preview }

class QuickAddPage extends ConsumerStatefulWidget {
  const QuickAddPage({
    super.key,
    this.initialDate,
    this.forceTaskType,
  });

  final DateTime? initialDate;
  final TaskType? forceTaskType;

  @override
  ConsumerState<QuickAddPage> createState() => _QuickAddPageState();
}

class _QuickAddPageState extends ConsumerState<QuickAddPage> {
  final _inputController = TextEditingController();
  _QuickAddStep _step = _QuickAddStep.input;
  ParsedTask? _parsed;
  bool _saving = false;

  QuickAddParserLanguage? get _parserLanguage =>
      resolveQuickAddParserLanguage(ref.read(appLanguageProvider));

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _goToPreview() {
    final l10n = AppLocalizations.of(context);
    final parserLanguage = _parserLanguage;
    if (parserLanguage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quickAddUnsupportedLanguage)),
      );
      return;
    }

    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quickAddEmptyInput)),
      );
      return;
    }

    final parsed = parseQuickAddInput(
      text,
      language: parserLanguage,
    );
    if (parsed.title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quickAddEmptyInput)),
      );
      return;
    }

    setState(() {
      _parsed = parsed;
      _step = _QuickAddStep.preview;
    });
  }

  Future<void> _confirmAdd() async {
    final parsed = _parsed;
    if (parsed == null) return;

    setState(() => _saving = true);
    try {
      final draft = parsedTaskToDraft(parsed, ref);
      await ref.read(eventActionsProvider).create(draft);
      if (draft.date.isNotEmpty) {
        try {
          ref.read(homeSelectedDateProvider.notifier).state =
              DateTimeFormats.parseDate(draft.date);
        } catch (_) {}
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).saveFailedRetry)),
      );
      setState(() => _saving = false);
    }
  }

  void _openFormForParsed(ParsedTask parsed, TaskType taskType) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => QuickAddFormBridge.formPageForTypeSwitch(
          parsed: parsed,
          targetType: taskType,
          fallbackDate: widget.initialDate,
          lockedForceTaskType: widget.forceTaskType,
        ),
      ),
    );
  }

  void _switchTaskType(TaskType newType) {
    final parsed = _parsed;
    if (parsed == null || newType == parsed.taskType) return;
    _openFormForParsed(parsed, newType);
  }

  void _openEditor() {
    final parsed = _parsed;
    if (parsed == null) return;
    _openFormForParsed(parsed, widget.forceTaskType ?? parsed.taskType);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.quickAddTitle),
        leading: _step == _QuickAddStep.preview
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => setState(() => _step = _QuickAddStep.input),
              )
            : null,
      ),
      body: _step == _QuickAddStep.input
          ? _InputStep(
              controller: _inputController,
              hint: l10n.quickAddHint,
              onNext: _goToPreview,
            )
          : _PreviewStep(
              parsed: _parsed!,
              rawInput: _inputController.text.trim(),
              saving: _saving,
              onConfirm: _confirmAdd,
              onEdit: _openEditor,
              onSwitchTaskType: _switchTaskType,
            ),
    );
  }
}

class _InputStep extends StatelessWidget {
  const _InputStep({
    required this.controller,
    required this.hint,
    required this.onNext,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                minLines: 3,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onNext(),
                decoration: InputDecoration(
                  hintText: hint,
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: FilledButton(
              onPressed: onNext,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(l10n.quickAddNext),
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep({
    required this.parsed,
    required this.rawInput,
    required this.saving,
    required this.onConfirm,
    required this.onEdit,
    required this.onSwitchTaskType,
  });

  final ParsedTask parsed;
  final String rawInput;
  final bool saving;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final ValueChanged<TaskType> onSwitchTaskType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            children: [
              Text(
                rawInput,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.quickAddParseResult,
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              SegmentedButton<TaskType>(
                segments: [
                  ButtonSegment(
                    value: TaskType.schedule,
                    label: Text(l10n.taskTypeSchedule),
                  ),
                  ButtonSegment(
                    value: TaskType.todo,
                    label: Text(l10n.taskTypeTodo),
                  ),
                ],
                selected: {parsed.taskType},
                onSelectionChanged: (selected) {
                  onSwitchTaskType(selected.first);
                },
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: theme.colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parsed.title,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (parsed.date != null)
                        _PreviewRow(
                          icon: Icons.calendar_today_outlined,
                          text: DateTimeFormats.formatSectionDate(
                            parsed.date!,
                            l10n,
                          ),
                        ),
                      if (parsed.startTime != null && parsed.endTime == null)
                        _PreviewRow(
                          icon: Icons.schedule_outlined,
                          text: _formatClock(parsed.startTime!),
                        ),
                      if (parsed.startTime != null && parsed.endTime != null)
                        _PreviewRow(
                          icon: Icons.schedule_outlined,
                          text:
                              '${_formatClock(parsed.startTime!)} – ${_formatClock(parsed.endTime!)}',
                        ),
                      if (parsed.hasReminders)
                        _PreviewRow(
                          icon: Icons.notifications_outlined,
                          text: formatReminderOffsetsSummary(
                            l10n,
                            parsed.reminderOffsetsSeconds,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: saving ? null : onConfirm,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                        )
                      : Text(l10n.quickAddConfirm),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: saving ? null : onEdit,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.quickAddEdit),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatClock(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }
}
