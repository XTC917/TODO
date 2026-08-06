import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/focus_providers.dart';
import '../../../core/services/focus_timer_service.dart';
import '../../../core/utils/focus_display.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums.dart';
import '../../../models/event.dart';
import 'widgets/focus_custom_duration_sheet.dart';
import 'widgets/focus_summary_dialog.dart';
import 'widgets/focus_task_picker_sheet.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage>
    with WidgetsBindingObserver {
  FocusMode _mode = FocusMode.pomodoro;
  bool _deleteMode = false;
  int? _pendingEventId;
  String? _pendingTaskTitle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLaunch();
      _syncIdleConfig();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(focusTimerProvider.notifier).refreshDisplay();
    }
  }

  void _syncIdleConfig() {
    if (ref.read(focusTimerProvider).session.isActive) return;
    ref.read(focusTimerProvider.notifier).configureIdle(
          mode: _mode,
          targetSeconds: _mode == FocusMode.pomodoro
              ? ref.read(selectedCountdownSecondsProvider)
              : null,
        );
  }

  void _handleLaunch() {
    final launch = ref.read(focusLaunchProvider);
    if (launch == null) return;
    ref.read(focusLaunchProvider.notifier).state = null;
    if (launch.autoStart) {
      _startSession(
        mode: launch.mode,
        targetSeconds: launch.mode == FocusMode.pomodoro
            ? launch.durationMinutes * 60
            : null,
        eventId: launch.eventId,
        taskTitle: null,
      );
    }
  }

  Future<void> _handleCompletion(FocusCompletionResult result) async {
    await ref.read(focusActionsProvider).saveCompletion(result);
    if (!mounted) return;
    await showFocusSummaryDialog(context: context, result: result);
    ref.read(focusTimerProvider.notifier).clearCompletion();
    setState(() {
      _pendingEventId = null;
      _pendingTaskTitle = null;
    });
  }

  Future<void> _startSession({
    required FocusMode mode,
    int? targetSeconds,
    int? eventId,
    String? taskTitle,
  }) async {
    ref.read(focusTimerProvider.notifier).start(
          mode: mode,
          targetSeconds: targetSeconds,
          linkedEventId: eventId,
          linkedTaskTitle: taskTitle,
        );
  }

  Future<void> _pickTask() async {
    final selection = await showFocusTaskPickerSheet(
      context: context,
      ref: ref,
    );
    if (!mounted || selection == null) return;
    setState(() {
      _pendingEventId = selection.eventId;
      _pendingTaskTitle = selection.title;
    });
  }

  Future<void> _onStartPressed() async {
    final targetSeconds = _mode == FocusMode.pomodoro
        ? ref.read(selectedCountdownSecondsProvider)
        : null;

    await _startSession(
      mode: _mode,
      targetSeconds: targetSeconds,
      eventId: _pendingEventId,
      taskTitle: _pendingTaskTitle,
    );
  }

  Future<void> _onEndPressed() async {
    final result = ref.read(focusTimerProvider.notifier).stop();
    if (result != null) {
      await _handleCompletion(result);
    }
  }

  Future<void> _addCustomPreset() async {
    final seconds = await showFocusCustomDurationSheet(context: context);
    if (seconds == null || !mounted) return;
    await ref.read(focusPresetsProvider.notifier).addPreset(seconds);
    ref.read(selectedCountdownSecondsProvider.notifier).state = seconds;
    setState(() => _deleteMode = false);
  }

  int _displaySeconds(FocusTimerService service, FocusRuntimeSession session) {
    if (session.isActive) {
      if (_mode == FocusMode.pomodoro && session.targetSeconds != null) {
        return service.remainingSeconds() ?? 0;
      }
      return service.elapsedSeconds();
    }
    if (_mode == FocusMode.pomodoro) {
      return ref.read(selectedCountdownSecondsProvider);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FocusTimerTick>(focusTimerProvider, (prev, next) {
      final completion = next.completion;
      if (completion != null && completion != prev?.completion) {
        _handleCompletion(completion);
      }
    });

    ref.listen<FocusLaunchConfig?>(focusLaunchProvider, (_, next) {
      if (next != null) _handleLaunch();
    });

    final tick = ref.watch(focusTimerProvider);
    final session = tick.session;
    final timerService = ref.watch(focusTimerServiceProvider);
    final l10n = AppLocalizations.of(context);
    final displayMode = ref.watch(focusDisplayModeProvider);
    final presets = ref.watch(focusPresetsProvider);
    final selectedSeconds = ref.watch(selectedCountdownSecondsProvider);
    final displaySeconds = _displaySeconds(timerService, session);
    final timerLabel = FocusDisplayFormatter.formatMainDisplay(
      displaySeconds,
      displayMode,
    );
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;
            final isActive = session.isActive;
            final showPresets =
                !isActive && _mode == FocusMode.pomodoro;
            final showTaskPicker = !isActive;

            final gapL = isLandscape ? 16.0 : 32.0;
            final gapM = isLandscape ? 12.0 : 24.0;
            final gapS = isLandscape ? 8.0 : 16.0;
            final hPad = isLandscape ? 32.0 : 28.0;

            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - hPad * 2,
                      maxHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SegmentedButton<FocusMode>(
                          segments: [
                            ButtonSegment(
                              value: FocusMode.pomodoro,
                              label: Text(
                                focusModeLabel(l10n, FocusMode.pomodoro),
                              ),
                            ),
                            ButtonSegment(
                              value: FocusMode.stopwatch,
                              label: Text(
                                focusModeLabel(l10n, FocusMode.stopwatch),
                              ),
                            ),
                          ],
                          selected: {_mode},
                          onSelectionChanged: isActive
                              ? null
                              : (s) {
                                  setState(() {
                                    _mode = s.first;
                                    _deleteMode = false;
                                  });
                                  _syncIdleConfig();
                                },
                        ),
                        SizedBox(height: gapL),
                        GestureDetector(
                          onTap: () => ref
                              .read(focusDisplayModeProvider.notifier)
                              .toggle(),
                          behavior: HitTestBehavior.opaque,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                timerLabel,
                                textAlign: TextAlign.center,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                  letterSpacing: 1,
                                  height: 1.0,
                                  fontSize: isLandscape ? 56 : 64,
                                ),
                              ),
                              SizedBox(height: gapS * 0.5),
                              Text(
                                l10n.focusTapToToggleDisplay,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isActive &&
                            session.linkedTaskTitle != null &&
                            session.linkedTaskTitle!.isNotEmpty) ...[
                          SizedBox(height: gapM),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: constraints.maxWidth - hPad * 2,
                            ),
                            child: Text(
                              session.linkedTaskTitle!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: muted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                        SizedBox(height: gapL),
                        _SessionControls(
                          session: session,
                          compact: isLandscape,
                          onStart: _onStartPressed,
                          onPause: () =>
                              ref.read(focusTimerProvider.notifier).pause(),
                          onResume: () =>
                              ref.read(focusTimerProvider.notifier).resume(),
                          onEnd: _onEndPressed,
                          l10n: l10n,
                        ),
                        if (showPresets) ...[
                          SizedBox(height: gapM),
                          if (_deleteMode)
                            Padding(
                              padding: EdgeInsets.only(bottom: gapS * 0.5),
                              child: TextButton(
                                onPressed: () =>
                                    setState(() => _deleteMode = false),
                                child: Text(l10n.focusDoneDelete),
                              ),
                            ),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final seconds in presets)
                                _PresetChip(
                                  label: FocusDisplayFormatter.formatChipLabel(
                                    l10n,
                                    seconds,
                                    displayMode,
                                  ),
                                  selected: selectedSeconds == seconds,
                                  deleteMode: _deleteMode,
                                  onDelete: () async {
                                    await ref
                                        .read(focusPresetsProvider.notifier)
                                        .removePreset(seconds);
                                    final updated =
                                        ref.read(focusPresetsProvider);
                                    if (updated.isEmpty) return;
                                    if (selectedSeconds == seconds) {
                                      ref
                                          .read(
                                              selectedCountdownSecondsProvider
                                                  .notifier)
                                          .state = updated.first;
                                      _syncIdleConfig();
                                    }
                                  },
                                  onTap: () {
                                    ref
                                        .read(selectedCountdownSecondsProvider
                                            .notifier)
                                        .state = seconds;
                                    _syncIdleConfig();
                                  },
                                  onLongPress: () =>
                                      setState(() => _deleteMode = true),
                                ),
                              ActionChip(
                                avatar: const Icon(Icons.add, size: 18),
                                label: Text(l10n.focusAddPreset),
                                onPressed:
                                    _deleteMode ? null : _addCustomPreset,
                              ),
                            ],
                          ),
                        ],
                        if (showTaskPicker) ...[
                          SizedBox(height: gapM),
                          InkWell(
                            onTap: _pickTask,
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.task_alt_outlined,
                                    size: 18,
                                    color: muted,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      _pendingTaskTitle ??
                                          l10n.focusCurrentTask,
                                      textAlign: TextAlign.center,
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: _pendingTaskTitle != null
                                            ? theme.colorScheme.onSurface
                                            : muted,
                                      ),
                                    ),
                                  ),
                                  if (_pendingTaskTitle != null) ...[
                                    const SizedBox(width: 2),
                                    Icon(
                                      Icons.chevron_right,
                                      size: 18,
                                      color: muted,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionControls extends StatelessWidget {
  const _SessionControls({
    required this.session,
    required this.compact,
    required this.onStart,
    required this.onPause,
    required this.onResume,
    required this.onEnd,
    required this.l10n,
  });

  final FocusRuntimeSession session;
  final bool compact;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onEnd;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final btnH = compact ? 40.0 : 48.0;

    if (!session.isActive) {
      return FilledButton.icon(
        onPressed: onStart,
        icon: const Icon(Icons.play_arrow_rounded),
        label: Text(l10n.focusStart),
        style: FilledButton.styleFrom(
          minimumSize: Size(compact ? 140 : 160, btnH),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (session.state == FocusTimerState.running)
          OutlinedButton(
            onPressed: onPause,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(compact ? 100 : 120, btnH),
            ),
            child: Text(l10n.focusPause),
          ),
        if (session.state == FocusTimerState.paused)
          OutlinedButton(
            onPressed: onResume,
            style: OutlinedButton.styleFrom(
              minimumSize: Size(compact ? 100 : 120, btnH),
            ),
            child: Text(l10n.focusResume),
          ),
        FilledButton(
          onPressed: onEnd,
          style: FilledButton.styleFrom(
            minimumSize: Size(compact ? 100 : 120, btnH),
          ),
          child: Text(l10n.focusEnd),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.deleteMode,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  final String label;
  final bool selected;
  final bool deleteMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: deleteMode ? null : (_) => onTap(),
          ),
          if (deleteMode)
            Positioned(
              right: -4,
              top: -4,
              child: Material(
                color: Theme.of(context).colorScheme.error,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onDelete,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
