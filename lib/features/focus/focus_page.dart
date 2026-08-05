import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/enum_labels.dart';
import '../../core/providers/app_providers.dart';
import '../../core/providers/focus_providers.dart';
import '../../core/utils/date_time_formats.dart';
import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

class FocusPage extends ConsumerStatefulWidget {
  const FocusPage({super.key});

  @override
  ConsumerState<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends ConsumerState<FocusPage> {
  FocusMode _mode = FocusMode.pomodoro;
  int _pomodoroMinutes = 25;
  final int _customMinutes = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleLaunch());
  }

  void _handleLaunch() {
    final launch = ref.read(focusLaunchProvider);
    if (launch == null) return;
    ref.read(focusLaunchProvider.notifier).state = null;
    if (launch.autoStart) {
      ref.read(focusTimerProvider.notifier).start(
            mode: launch.mode,
            targetMinutes: launch.durationMinutes,
            linkedEventId: launch.eventId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FocusLaunchConfig?>(focusLaunchProvider, (_, next) {
      if (next != null) _handleLaunch();
    });

    final session = ref.watch(focusTimerProvider);
    final elapsed = session.elapsedSeconds;
    final target = session.targetSeconds;
    final l10n = AppLocalizations.of(context);

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
                          style:
                              Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
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
                              : (s) => setState(() => _mode = s.first),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _mode == FocusMode.pomodoro && target != null
                          ? DateTimeFormats.formatStopwatch(
                              (target - elapsed).clamp(0, target),
                            )
                          : DateTimeFormats.formatStopwatch(elapsed),
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                    ),
                    if (!session.isActive && _mode == FocusMode.pomodoro) ...[
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [25, 45, 60, 90].map((m) {
                          return ChoiceChip(
                            label: Text(l10n.focusMinutes(m)),
                            selected: _pomodoroMinutes == m,
                            onSelected: (_) =>
                                setState(() => _pomodoroMinutes = m),
                          );
                        }).toList()
                          ..add(
                            ChoiceChip(
                              label: Text(l10n.focusCustom(_customMinutes)),
                              selected: _pomodoroMinutes == _customMinutes,
                              onSelected: (_) => setState(
                                () => _pomodoroMinutes = _customMinutes,
                              ),
                            ),
                          ),
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
                            onPressed: () {
                              ref.read(focusTimerProvider.notifier).start(
                                    mode: _mode,
                                    targetMinutes: _mode == FocusMode.pomodoro
                                        ? _pomodoroMinutes
                                        : null,
                                  );
                            },
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(l10n.focusStart),
                          ),
                        if (session.state == FocusTimerState.running) ...[
                          OutlinedButton(
                            onPressed: () =>
                                ref.read(focusTimerProvider.notifier).pause(),
                            child: Text(l10n.focusPause),
                          ),
                          FilledButton(
                            onPressed: _finish,
                            child: Text(l10n.focusEnd),
                          ),
                        ],
                        if (session.state == FocusTimerState.paused) ...[
                          OutlinedButton(
                            onPressed: () =>
                                ref.read(focusTimerProvider.notifier).resume(),
                            child: Text(l10n.focusResume),
                          ),
                          FilledButton(
                            onPressed: _finish,
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

  Future<void> _finish() async {
    final ended = ref.read(focusTimerProvider.notifier).stop();
    if (ended != null && ended.elapsedSeconds > 0) {
      await ref.read(focusActionsProvider).saveSession(ended);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).focusSaved(
              DateTimeFormats.formatDuration(ended.elapsedSeconds),
            ),
          ),
        ),
      );
    }
  }
}
