import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../core/utils/event_constants.dart';
import '../../../core/utils/event_display.dart';
import '../../../core/utils/focus_task_picker_items.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/event.dart';

class FocusTaskSelection {
  const FocusTaskSelection({this.eventId, this.title});

  final int? eventId;
  final String? title;
}

enum _FocusTaskInputMode { todo, custom }

Future<FocusTaskSelection?> showFocusTaskPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
  String? initialTitle,
  int? initialEventId,
}) async {
  return showModalBottomSheet<FocusTaskSelection>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    showDragHandle: true,
    sheetAnimationStyle: const AnimationStyle(
      duration: Duration(milliseconds: 180),
      reverseDuration: Duration(milliseconds: 150),
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => _FocusTaskPickerSheet(
      initialTitle: initialTitle,
      initialEventId: initialEventId,
    ),
  );
}

class _FocusTaskPickerSheet extends ConsumerStatefulWidget {
  const _FocusTaskPickerSheet({
    this.initialTitle,
    this.initialEventId,
  });

  final String? initialTitle;
  final int? initialEventId;

  @override
  ConsumerState<_FocusTaskPickerSheet> createState() =>
      _FocusTaskPickerSheetState();
}

class _FocusTaskPickerSheetState extends ConsumerState<_FocusTaskPickerSheet> {
  late _FocusTaskInputMode _mode;
  late final TextEditingController _customController;
  late final FocusNode _customFocusNode;
  int? _selectedEventId;

  @override
  void initState() {
    super.initState();
    _selectedEventId = widget.initialEventId;
    _mode = _FocusTaskInputMode.todo;
    _customController = TextEditingController(text: widget.initialTitle ?? '');
    _customFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _customController.dispose();
    _customFocusNode.dispose();
    super.dispose();
  }

  void _onModeChanged(_FocusTaskInputMode? mode) {
    if (mode == null || mode == _mode) return;
    setState(() {
      _mode = mode;
      if (mode == _FocusTaskInputMode.custom &&
          _customController.text.isEmpty &&
          widget.initialTitle != null) {
        _customController.text = widget.initialTitle!;
      }
    });
    if (mode == _FocusTaskInputMode.custom) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _customFocusNode.requestFocus();
      });
    }
  }

  void _confirmCustom() {
    final text = _customController.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(context, FocusTaskSelection(title: text));
  }

  double _listSheetHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLandscape = size.width > size.height;
    if (isLandscape) return size.height * 0.94;
    return size.height * 0.72;
  }

  String _sectionTitle(
    AppLocalizations l10n,
    FocusTaskPickerSectionKind kind,
  ) {
    return switch (kind) {
      FocusTaskPickerSectionKind.todaySchedules => l10n.focusTodaySchedules,
      FocusTaskPickerSectionKind.todayTodos => l10n.focusTodayTodosSection,
      FocusTaskPickerSectionKind.longTermTodos =>
        l10n.focusLongTermTodosSection,
      FocusTaskPickerSectionKind.otherDateTodos => l10n.focusOtherDateTodos,
    };
  }

  String _taskSubtitle(AppLocalizations l10n, Event task) {
    if (task.isSchedule) return l10n.taskTypeSchedule;
    if (task.isNoTimeTodo) return l10n.longTermTask;
    final timeLabel = eventTimeLabel(task, l10n);
    if (task.date.isNotEmpty) {
      final dateLabel = DateTimeFormats.formatSectionDate(
        DateTime.parse(task.date),
        l10n,
      );
      if (timeLabel.isEmpty) return dateLabel;
      return '$dateLabel · $timeLabel';
    }
    if (timeLabel.isNotEmpty) return timeLabel;
    return l10n.taskTypeTodo;
  }

  Widget _buildHeader(AppLocalizations l10n, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            l10n.focusCurrentFocus,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SegmentedButton<_FocusTaskInputMode>(
            segments: [
              ButtonSegment(
                value: _FocusTaskInputMode.todo,
                label: Text(l10n.focusSelectTodo),
              ),
              ButtonSegment(
                value: _FocusTaskInputMode.custom,
                label: Text(l10n.focusTaskModeCustom),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => _onModeChanged(s.first),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildCustomInput(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _customController,
            focusNode: _customFocusNode,
            maxLength: kMaxEventTitleLength,
            decoration: InputDecoration(
              hintText: l10n.focusCustomTaskHint,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [
              LengthLimitingTextInputFormatter(kMaxEventTitleLength),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _confirmCustom(),
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed:
                _customController.text.trim().isEmpty ? null : _confirmCustom,
            child: Text(l10n.focusUseCustomTask),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList({
    required AppLocalizations l10n,
    required ThemeData theme,
    required Color muted,
    required AsyncValue<List<FocusTaskPickerSection>> sectionsAsync,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text(l10n.focusNoTask),
          trailing: const Icon(Icons.block_rounded, size: 20),
          onTap: () => Navigator.pop(
            context,
            const FocusTaskSelection(),
          ),
        ),
        Expanded(
          child: sectionsAsync.when(
            data: (sections) {
              final hasAny = sections.any((section) => section.items.isNotEmpty);
              if (!hasAny) {
                return Center(
                  child: Text(
                    l10n.noTodosForDay,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  for (final section in sections)
                    if (section.items.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                        child: Text(
                          _sectionTitle(l10n, section.kind),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: muted,
                          ),
                        ),
                      ),
                      for (final task in section.items)
                        ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          selected: _selectedEventId == task.id,
                          leading: Icon(
                            task.isSchedule
                                ? Icons.event_outlined
                                : Icons.check_circle_outline,
                            size: 20,
                          ),
                          title: Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            _taskSubtitle(l10n, task),
                            style: theme.textTheme.labelSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => Navigator.pop(
                            context,
                            FocusTaskSelection(
                              eventId: task.id,
                              title: task.title,
                            ),
                          ),
                        ),
                    ],
                ],
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
            error: (e, _) => Center(
              child: Text(l10n.errorGeneric('$e')),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final sectionsAsync = ref.watch(focusTaskPickerSectionsProvider);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    if (_mode == _FocusTaskInputMode.custom) {
      return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: Material(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(l10n, theme),
                  _buildCustomInput(l10n),
                  if (!keyboardOpen) const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        height: _listSheetHeight(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(l10n, theme),
            Expanded(
              child: _buildTaskList(
                l10n: l10n,
                theme: theme,
                muted: muted,
                sectionsAsync: sectionsAsync,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
