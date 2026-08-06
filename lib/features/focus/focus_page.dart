import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/providers/focus_providers.dart';
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

class _FocusPageState extends ConsumerState<FocusPage> {
  FocusMode _mode = FocusMode.pomodoro;
  bool _deleteMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleLaunch();
      _syncIdleConfig();
    });
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

  Future<void> _onStartPressed() async {
    final selection = await showFocusTaskPickerSheet(
      context: context,
      ref: ref,
    );
    if (!mounted || selection == null) return;

    final targetSeconds = _mode == FocusMode.pomodoro
        ? ref.read(selectedCountdownSecondsProvider)
        : null;

    await _startSession(
      mode: _mode,
      targetSeconds: targetSeconds,
      eventId: selection.eventId,
      taskTitle: selection.title,
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

  int _displaySeconds(FocusRuntimeSession session) {
    final now = DateTime.now();
    if (session.isActive) {
      if (_mode == FocusMode.pomodoro && session.targetSeconds != null) {
        return session.remainingSecondsAt(now) ?? 0;
      }
      return session.elapsedSecondsAt(now);
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
    final l10n = AppLocalizations.of(context);
    final displayMode = ref.watch(focusDisplayModeProvider);
    final presets = ref.watch(focusPresetsProvider);
    final selectedSeconds = ref.watch(selectedCountdownSecondsProvider);
    final displaySeconds = _displaySeconds(session);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          l10n.focusTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 24),
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
                          onSelectionChanged: session.isActive
                              ? null
                              : (s) {
                                  setState(() {
                                    _mode = s.first;
                                    _deleteMode = false;
                                  });
                                  _syncIdleConfig();
                                },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: session.isActive
                          ? null
                          : () => ref
                              .read(focusDisplayModeProvider.notifier)
                              .toggle(),
                      child: Column(
                        children: [
                          Text(
                            FocusDisplayFormatter.formatClock(displaySeconds),
                            style: Theme.of(context)
                                .textTheme
                                .displayMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                          ),
                          if (!session.isActive &&
                              _mode == FocusMode.pomodoro) ...[
                            const SizedBox(height: 8),
                            Text(
                              l10n.focusTapToToggleDisplay,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.45),
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!session.isActive && _mode == FocusMode.pomodoro) ...[
                      const SizedBox(height: 24),
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
                                  ref
                                      .read(selectedCountdownSecondsProvider
                                          .notifier)
                                      .state = updated.first;
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
                            onPressed: _deleteMode
                                ? () => setState(() => _deleteMode = false)
                                : _addCustomPreset,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        if (!session.isActive)
                          FilledButton.icon(
                            onPressed: _onStartPressed,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.focusStart),
                          ),
                        if (session.state == FocusTimerState.running) ...[
                          OutlinedButton(
                            onPressed: () => ref
                                .read(focusTimerProvider.notifier)
                                .pause(),
                            child: Text(l10n.focusPause),
                          ),
                          FilledButton(
                            onPressed: _onEndPressed,
                            child: Text(l10n.focusEnd),
                          ),
                        ],
                        if (session.state == FocusTimerState.paused) ...[
                          OutlinedButton(
                            onPressed: () => ref
                                .read(focusTimerProvider.notifier)
                                .resume(),
                            child: Text(l10n.focusResume),
                          ),
                          FilledButton(
                            onPressed: _onEndPressed,
                            child: Text(l10n.focusEnd),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
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
