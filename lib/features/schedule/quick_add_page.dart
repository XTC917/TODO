import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/ai/ai_error.dart';
import '../../core/ai/ai_smart_add_service.dart';
import '../../core/config/ai_config.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/l10n_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../core/utils/parsed_task.dart';
import '../../core/utils/parsed_task_draft.dart';
import '../../core/utils/quick_add_form_bridge.dart';
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
    this.aiService,
  });

  final DateTime? initialDate;
  final TaskType? forceTaskType;

  /// Injectable for tests; defaults to the Gemini-backed service.
  final AiSmartAddService? aiService;

  @override
  ConsumerState<QuickAddPage> createState() => _QuickAddPageState();
}

class _QuickAddPageState extends ConsumerState<QuickAddPage> {
  final _inputController = TextEditingController();
  AiSmartAddService? _aiServiceInstance;
  _QuickAddStep _step = _QuickAddStep.input;
  ParsedTask? _parsed;
  bool _saving = false;
  bool _aiLoading = false;
  bool _parsedByAi = false;

  /// Created on first dev-only use so prod never initializes Gemini.
  AiSmartAddService get _aiService =>
      _aiServiceInstance ??= (widget.aiService ?? AiSmartAddService());

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
      _parsedByAi = false;
      _step = _QuickAddStep.preview;
    });
  }

  Future<void> _goToPreviewAi() async {
    if (!AiConfig.isEnabled || _aiLoading) return;

    final l10n = AppLocalizations.of(context);
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.quickAddEmptyInput)),
      );
      return;
    }
    if (!_aiService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiSmartAddNoKey)),
      );
      return;
    }

    setState(() => _aiLoading = true);
    try {
      final parsed = await _aiService.parse(
        text,
        reference: DateTime.now(),
        languageCode:
            resolveAppLocale(ref.read(appLanguageProvider)).languageCode,
      );
      if (!mounted) return;
      setState(() {
        _aiLoading = false;
        _parsed = parsed;
        _parsedByAi = true;
        _step = _QuickAddStep.preview;
      });
    } on AiSmartAddException catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[JUJU-AI] smart add failed kind=${error.kind.name} '
          'status=${error.statusCode} detail=${error.detail}',
        );
      }
      if (!mounted) return;
      setState(() => _aiLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_aiErrorMessage(l10n, error.kind))),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _aiLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.aiSmartAddInvalidResponse)),
      );
    }
  }

  String _aiErrorMessage(AppLocalizations l10n, AiErrorKind kind) {
    return switch (kind) {
      AiErrorKind.missingKey => l10n.aiSmartAddNoKey,
      AiErrorKind.timeout => l10n.aiSmartAddTimeout,
      AiErrorKind.network => l10n.aiSmartAddNetworkError,
      AiErrorKind.unauthorized => l10n.aiSmartAddAuthError,
      AiErrorKind.rateLimited => l10n.aiSmartAddRateLimited,
      AiErrorKind.server => l10n.aiSmartAddServerError,
      AiErrorKind.invalidResponse => l10n.aiSmartAddInvalidResponse,
    };
  }

  Future<void> _confirmAdd() async {
    final parsed = _parsed;
    if (parsed == null) return;

    if (parsed.needsDateConfirmation) {
      _openEditor();
      return;
    }

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

  void _openEditor() {
    final parsed = _parsed;
    if (parsed == null) return;
    Navigator.of(context).pop(parsed);
  }

  void _switchTaskType(TaskType newType) {
    final parsed = _parsed;
    if (parsed == null || newType == parsed.taskType) return;
    setState(() {
      _parsed = QuickAddFormBridge.parsedForTaskType(
        parsed,
        newType,
        defaultOffsets: ref.read(defaultReminderOffsetsProvider),
      );
    });
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
                onPressed: () => setState(() {
                  _step = _QuickAddStep.input;
                  _parsedByAi = false;
                }),
              )
            : null,
      ),
      body: _step == _QuickAddStep.input
          ? _InputStep(
              controller: _inputController,
              hint: l10n.quickAddHint,
              aiEnabled: AiConfig.isEnabled,
              aiLoading: _aiLoading,
              onNext: _goToPreview,
              onAiRecognize: _goToPreviewAi,
            )
          : _PreviewStep(
              parsed: _parsed!,
              rawInput: _inputController.text.trim(),
              saving: _saving,
              parsedByAi: _parsedByAi,
              defaultReminderOffsets: ref.watch(defaultReminderOffsetsProvider),
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
    required this.aiEnabled,
    required this.aiLoading,
    required this.onNext,
    required this.onAiRecognize,
  });

  final TextEditingController controller;
  final String hint;
  final bool aiEnabled;
  final bool aiLoading;
  final VoidCallback onNext;
  final VoidCallback onAiRecognize;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (aiEnabled) ...[
                  FilledButton.tonalIcon(
                    onPressed: aiLoading ? null : onAiRecognize,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: aiLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome_rounded),
                    label: Text(
                      aiLoading
                          ? l10n.aiSmartAddRecognizing
                          : l10n.aiSmartAddButton,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                FilledButton(
                  onPressed: aiLoading ? null : onNext,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(l10n.quickAddNext),
                ),
              ],
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
    required this.parsedByAi,
    required this.defaultReminderOffsets,
    required this.onConfirm,
    required this.onEdit,
    required this.onSwitchTaskType,
  });

  final ParsedTask parsed;
  final String rawInput;
  final bool saving;
  final bool parsedByAi;
  final List<int> defaultReminderOffsets;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;
  final ValueChanged<TaskType> onSwitchTaskType;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final reminders = parsed.effectiveReminderOffsetsSeconds(
      defaultOffsets: defaultReminderOffsets,
    );

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
              Row(
                children: [
                  Text(
                    l10n.quickAddParseResult,
                    style: theme.textTheme.labelLarge,
                  ),
                  if (parsedByAi) ...[
                    const SizedBox(width: 8),
                    Chip(
                      avatar: const Icon(Icons.auto_awesome_rounded, size: 14),
                      label: Text(l10n.aiSmartAddBadge),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ],
                ],
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
                        )
                      else if (parsed.needsDateConfirmation)
                        _PreviewRow(
                          icon: Icons.error_outline_rounded,
                          text: l10n.quickAddDateUnresolved,
                        ),
                      if ((parsed.todoTimeMode == TodoTimeMode.deadline ||
                              (parsed.endTime != null &&
                                  parsed.startTime == null)) &&
                          parsed.endTime != null)
                        _PreviewRow(
                          icon: Icons.schedule_outlined,
                          text: _formatClock(parsed.endTime!),
                        )
                      else if (parsed.startTime != null &&
                          parsed.endTime == null)
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
                      if (reminders.isNotEmpty)
                        _PreviewRow(
                          icon: Icons.notifications_outlined,
                          text: formatReminderOffsetsSummary(l10n, reminders),
                        ),
                      if (parsed.note != null && parsed.note!.isNotEmpty)
                        _PreviewRow(
                          icon: Icons.notes_outlined,
                          text: '${l10n.noteLabel}: ${parsed.note}',
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
                          child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2),
                        )
                      : Text(
                          parsed.needsDateConfirmation
                              ? l10n.quickAddConfirmDate
                              : l10n.quickAddConfirm,
                        ),
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
