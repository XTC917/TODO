import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/enum_labels.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/utils/focus_display.dart';
import '../../../core/widgets/swipe_event_actions.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/event.dart';
import '../../../models/focus_session.dart';
import 'focus_record_edit_sheet.dart';
import 'swipe_focus_record.dart';

Future<void> showFocusRecordsSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  await showModalBottomSheet<void>(
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
    builder: (ctx) => const _FocusRecordsSheet(),
  );
}

class _FocusRecordsSheet extends ConsumerWidget {
  const _FocusRecordsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final recordsAsync = ref.watch(allFocusRecordsProvider);
    final isLandscape =
        MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
    final sheetHeight =
        MediaQuery.sizeOf(context).height * (isLandscape ? 0.94 : 0.72);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: sheetHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                l10n.focusRecordsTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: recordsAsync.when(
                data: (records) {
                  if (records.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.focusRecordsEmpty,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: records.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final record = records[index];
                      return SwipeFocusRecord(
                        recordId: record.id,
                        onEdit: () => _editRecord(context, ref, record),
                        onDelete: () => _deleteRecord(context, ref, record),
                        child: _FocusRecordTile(record: record, muted: muted),
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
        ),
      ),
    );
  }

  Future<void> _editRecord(
    BuildContext context,
    WidgetRef ref,
    FocusRecord record,
  ) async {
    final updated = await showFocusRecordEditSheet(
      context: context,
      record: record,
    );
    if (updated == null) return;
    await ref.read(focusActionsProvider).updateRecord(record, updated);
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    FocusRecord record,
  ) async {
    final ok = await confirmDeleteEvent(context);
    if (!ok) return;
    await ref.read(focusActionsProvider).deleteRecord(record);
  }
}

class _FocusRecordTile extends StatelessWidget {
  const _FocusRecordTile({
    required this.record,
    required this.muted,
  });

  final FocusRecord record;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final taskLabel = record.taskTitle?.isNotEmpty == true
        ? record.taskTitle!
        : l10n.focusNoTask;
    final durationLabel = FocusDisplayFormatter.formatDurationLabel(
      l10n,
      record.durationSeconds,
      FocusDurationDisplayMode.hour,
    );

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              taskLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${record.date} · ${record.startTime}–${record.endTime}',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  durationLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  focusModeLabel(l10n, record.mode),
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
                const SizedBox(width: 8),
                Text(
                  record.durationSeconds <= 0 && !record.completed
                      ? l10n.focusRecordStrictFailed
                      : focusEnforcementLabel(l10n, record.enforcementMode),
                  style: theme.textTheme.labelSmall?.copyWith(color: muted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
