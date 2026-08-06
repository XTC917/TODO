import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/focus_providers.dart';
import '../../../core/services/focus_timer_service.dart';
import '../../../core/utils/focus_display.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/enums.dart';
import '../../../models/event.dart';
import 'widgets/focus_custom_duration_sheet.dart';
import 'widgets/focus_immersive_view.dart';
import 'widgets/focus_records_sheet.dart';
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

  static const _animDuration = Duration(milliseconds: 280);

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
  void deactivate() {
    WakelockPlus.disable();
    ref.read(focusImmersiveModeProvider.notifier).state = false;
    ref.read(focusImmersiveDarkModeProvider.notifier).state = false;
    super.deactivate();
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
    _exitImmersive();
    await ref.read(focusActionsProvider).saveCompletion(result);
    if (!mounted) return;
    ref.read(focusTimerProvider.notifier).clearCompletion();
    await showFocusSummaryDialog(context: context, result: result);
    if (!mounted) return;
    setState(() {
      _pendingEventId = null;
      _pendingTaskTitle = null;
    });
  }

  void _startSession({
    required FocusMode mode,
    int? targetSeconds,
    int? eventId,
    String? taskTitle,
  }) {
    ref.read(focusTimerProvider.notifier).start(
          mode: mode,
          targetSeconds: targetSeconds,
          linkedEventId: eventId,
          linkedTaskTitle: taskTitle,
        );
    _syncWakelock();
  }

  Future<void> _pickTask() async {
    final session = ref.read(focusTimerProvider).session;
    final isActive = session.isActive;
    final selection = await showFocusTaskPickerSheet(
      context: context,
      ref: ref,
      initialTitle:
          isActive ? session.linkedTaskTitle : _pendingTaskTitle,
      initialEventId:
          isActive ? session.linkedEventId : _pendingEventId,
    );
    if (!mounted || selection == null) return;

    if (isActive) {
      ref.read(focusTimerProvider.notifier).updateLinkedTask(
            eventId: selection.eventId,
            taskTitle: selection.title,
          );
    } else {
      setState(() {
        _pendingEventId = selection.eventId;
        _pendingTaskTitle = selection.title;
      });
    }
  }

  void _onStartPressed() {
    final targetSeconds = _mode == FocusMode.pomodoro
        ? ref.read(selectedCountdownSecondsProvider)
        : null;

    _startSession(
      mode: _mode,
      targetSeconds: targetSeconds,
      eventId: _pendingEventId,
      taskTitle: _pendingTaskTitle,
    );
  }

  Future<void> _onEndPressed() async {
    _exitImmersive();
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

  void _syncWakelock() {
    final sessionActive = ref.read(focusTimerProvider).session.isActive;
    final immersive = ref.read(focusImmersiveModeProvider);
    final keepAwake = ref.read(focusKeepAwakeProvider);
    if (immersive || (sessionActive && keepAwake)) {
      WakelockPlus.enable();
    } else {
      WakelockPlus.disable();
    }
  }

  void _enterImmersive() {
    if (!ref.read(focusTimerProvider).session.isActive) return;
    ref.read(focusImmersiveDarkModeProvider.notifier).state =
        Theme.of(context).brightness == Brightness.dark;
    ref.read(focusImmersiveModeProvider.notifier).state = true;
    _syncWakelock();
  }

  void _exitImmersive() {
    if (!ref.read(focusImmersiveModeProvider)) return;
    ref.read(focusImmersiveModeProvider.notifier).state = false;
    ref.read(focusImmersiveDarkModeProvider.notifier).state = false;
    _syncWakelock();
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

  String? _taskTitle(FocusRuntimeSession session) {
    return session.isActive ? session.linkedTaskTitle : _pendingTaskTitle;
  }

  Future<void> _openRecords() async {
    await showFocusRecordsSheet(context: context, ref: ref);
  }

  Widget _buildRecordsLink({
    required AppLocalizations l10n,
    required ThemeData theme,
    required Color muted,
  }) {
    return InkWell(
      onTap: _openRecords,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 16, color: muted),
            const SizedBox(width: 6),
            Text(
              l10n.focusViewRecords,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted.withValues(alpha: 0.75),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskLink({
    required AppLocalizations l10n,
    required ThemeData theme,
    required Color muted,
    required String? taskTitle,
  }) {
    return InkWell(
      onTap: _pickTask,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt_outlined, size: 16, color: muted),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: Text(
                taskTitle ?? l10n.focusCurrentTask,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      taskTitle != null ? muted : muted.withValues(alpha: 0.75),
                ),
              ),
            ),
            Icon(Icons.chevron_right, size: 16, color: muted),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetsSection({
    required AppLocalizations l10n,
    required FocusDurationDisplayMode displayMode,
    required List<int> presets,
    required int selectedSeconds,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_deleteMode)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() => _deleteMode = false),
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
                  final updated = ref.read(focusPresetsProvider);
                  if (updated.isEmpty) return;
                  if (selectedSeconds == seconds) {
                    ref.read(selectedCountdownSecondsProvider.notifier).state =
                        updated.first;
                    _syncIdleConfig();
                  }
                },
                onTap: () {
                  ref.read(selectedCountdownSecondsProvider.notifier).state =
                      seconds;
                  _syncIdleConfig();
                },
                onLongPress: () => setState(() => _deleteMode = true),
              ),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(l10n.focusAddPreset),
              onPressed: _deleteMode ? null : _addCustomPreset,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainColumn({
    required ThemeData theme,
    required AppLocalizations l10n,
    required FocusRuntimeSession session,
    required String timerLabel,
    required bool isLandscape,
    required bool showPresets,
    required bool showTaskLink,
    required bool showModeSwitch,
    required FocusDurationDisplayMode displayMode,
    required List<int> presets,
    required int selectedSeconds,
    required Color muted,
    required String? taskTitle,
    required double gapL,
    required double gapM,
    required double gapS,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (showModeSwitch)
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SegmentedButton<FocusMode>(
              segments: [
                ButtonSegment(
                  value: FocusMode.pomodoro,
                  label: Text(focusModeLabel(l10n, FocusMode.pomodoro)),
                ),
                ButtonSegment(
                  value: FocusMode.stopwatch,
                  label: Text(focusModeLabel(l10n, FocusMode.stopwatch)),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (s) {
                setState(() {
                  _mode = s.first;
                  _deleteMode = false;
                });
                _syncIdleConfig();
              },
            ),
          ),
        if (showModeSwitch) SizedBox(height: gapL),
        GestureDetector(
          onTap: () =>
              ref.read(focusDisplayModeProvider.notifier).toggle(),
          onLongPress: session.isActive ? _enterImmersive : null,
          behavior: HitTestBehavior.opaque,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timerLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  letterSpacing: 1,
                  height: 1.0,
                  fontSize: isLandscape ? (session.isActive ? 44 : 52) : 64,
                ),
              ),
              SizedBox(height: gapS * 0.5),
              Text(
                session.isActive
                    ? l10n.focusLongPressImmersive
                    : l10n.focusTapToToggleDisplay,
                style: theme.textTheme.labelSmall?.copyWith(color: muted),
              ),
            ],
          ),
        ),
        if (session.isActive &&
            taskTitle != null &&
            taskTitle.isNotEmpty) ...[
          SizedBox(height: gapM),
          Text(
            taskTitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        SizedBox(height: gapL),
        _SessionControls(
          session: session,
          compact: isLandscape,
          onStart: _onStartPressed,
          onPause: () => ref.read(focusTimerProvider.notifier).pause(),
          onResume: () => ref.read(focusTimerProvider.notifier).resume(),
          onEnd: _onEndPressed,
          l10n: l10n,
        ),
        if (showPresets) ...[
          SizedBox(height: gapM),
          _buildPresetsSection(
            l10n: l10n,
            displayMode: displayMode,
            presets: presets,
            selectedSeconds: selectedSeconds,
          ),
        ],
        if (showTaskLink) ...[
          SizedBox(height: gapM),
          _buildTaskLink(
            l10n: l10n,
            theme: theme,
            muted: muted,
            taskTitle: taskTitle,
          ),
          SizedBox(height: gapS),
          _buildRecordsLink(l10n: l10n, theme: theme, muted: muted),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FocusTimerTick>(focusTimerProvider, (prev, next) {
      final completion = next.completion;
      if (completion != null && completion != prev?.completion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _handleCompletion(completion);
        });
      }
      final wasActive = prev?.session.isActive ?? false;
      if (wasActive != next.session.isActive) {
        _syncWakelock();
      }
    });

    ref.listen<bool>(focusKeepAwakeProvider, (_, __) => _syncWakelock());

    ref.listen<FocusLaunchConfig?>(focusLaunchProvider, (_, next) {
      if (next != null) _handleLaunch();
    });

    final tick = ref.watch(focusTimerProvider);
    final session = tick.session;
    final timerService = ref.watch(focusTimerServiceProvider);
    final immersive = ref.watch(focusImmersiveModeProvider);
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
    final taskTitle = _taskTitle(session);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;
                final isActive = session.isActive;
                final showPresets = !isActive && _mode == FocusMode.pomodoro;
                final showSplitLandscape = isLandscape && !isActive;

                final gapL = isLandscape ? (isActive ? 12.0 : 20.0) : 32.0;
                final gapM = isLandscape ? (isActive ? 10.0 : 14.0) : 24.0;
                final gapS = isLandscape ? 6.0 : 12.0;
                final hPad = isLandscape ? 20.0 : 28.0;

                final mainColumn = _buildMainColumn(
                  theme: theme,
                  l10n: l10n,
                  session: session,
                  timerLabel: timerLabel,
                  isLandscape: isLandscape,
                  showPresets: !showSplitLandscape && showPresets,
                  showTaskLink: !showSplitLandscape,
                  showModeSwitch: !isActive,
                  displayMode: displayMode,
                  presets: presets,
                  selectedSeconds: selectedSeconds,
                  muted: muted,
                  taskTitle: taskTitle,
                  gapL: gapL,
                  gapM: gapM,
                  gapS: gapS,
                );

                Widget body;
                if (showSplitLandscape) {
                  body = Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 12,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxHeight: constraints.maxHeight,
                                  maxWidth: constraints.maxWidth * 0.5,
                                ),
                                child: mainColumn,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: gapM),
                        Expanded(
                          flex: 10,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (showPresets) ...[
                                  _buildPresetsSection(
                                    l10n: l10n,
                                    displayMode: displayMode,
                                    presets: presets,
                                    selectedSeconds: selectedSeconds,
                                  ),
                                  SizedBox(height: gapM),
                                ],
                                _buildTaskLink(
                                  l10n: l10n,
                                  theme: theme,
                                  muted: muted,
                                  taskTitle: taskTitle,
                                ),
                                SizedBox(height: gapS),
                                _buildRecordsLink(
                                  l10n: l10n,
                                  theme: theme,
                                  muted: muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  body = Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: constraints.maxWidth - hPad * 2,
                            maxHeight: constraints.maxHeight - 8,
                          ),
                          child: mainColumn,
                        ),
                      ),
                    ),
                  );
                }

                return IgnorePointer(
                  ignoring: immersive,
                  child: body,
                );
              },
            ),
          ),
          AnimatedSwitcher(
            duration: _animDuration,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.96, end: 1).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                  ),
                  child: child,
                ),
              );
            },
            child: immersive
                ? FocusImmersiveView(
                    key: const ValueKey('immersive'),
                    taskTitle: taskTitle,
                    timerLabel: timerLabel,
                    onExit: _exitImmersive,
                  )
                : const SizedBox.shrink(key: ValueKey('normal')),
          ),
        ],
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
    final btnH = compact ? 42.0 : 48.0;

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
