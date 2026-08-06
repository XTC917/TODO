import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_time_formats.dart';
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

  List<Event> _todayTasks(List<Event> events, String dateKey) {
    return events
        .where(
          (e) =>
              !e.isCompleted &&
              e.hasDate &&
              e.date == dateKey &&
              (e.isTodo || e.isSchedule),
        )
        .toList()
      ..sort((a, b) {
        final typeOrder = a.isSchedule == b.isSchedule
            ? 0
            : (a.isSchedule ? -1 : 1);
        if (typeOrder != 0) return typeOrder;
        return a.title.compareTo(b.title);
      });
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
    return size.height * 0.62;
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
            maxLength: 30,
            decoration: InputDecoration(
              hintText: l10n.focusCustomTaskHint,
              counterText: '',
              border: const OutlineInputBorder(),
            ),
            inputFormatters: [LengthLimitingTextInputFormatter(30)],
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
    required AsyncValue<List<Event>> eventsAsync,
    required String dateKey,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
          child: Text(
            l10n.focusTodayTasks,
            style: theme.textTheme.labelLarge?.copyWith(color: muted),
          ),
        ),
        Expanded(
          child: eventsAsync.when(
            data: (events) {
              final tasks = _todayTasks(events, dateKey);
              if (tasks.isEmpty) {
                return Center(
                  child: Text(
                    l10n.noTodosForDay,
                    style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 12),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final selected = _selectedEventId == task.id;
                  return ListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    selected: selected,
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
                      task.isSchedule
                          ? l10n.taskTypeSchedule
                          : l10n.taskTypeTodo,
                      style: theme.textTheme.labelSmall,
                    ),
                    onTap: () => Navigator.pop(
                      context,
                      FocusTaskSelection(
                        eventId: task.id,
                        title: task.title,
                      ),
                    ),
                  );
                },
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
    final today = DateTimeFormats.dateOnly(DateTime.now());
    final dateKey = DateTimeFormats.formatDate(today);
    final eventsAsync = ref.watch(eventsForDateProvider(today));
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
                eventsAsync: eventsAsync,
                dateKey: dateKey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
