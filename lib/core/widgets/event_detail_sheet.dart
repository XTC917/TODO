import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/schedule/event_form_page.dart';
import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../models/reminder_config.dart';
import '../data/demo_data.dart';
import '../providers/app_providers.dart';
import '../utils/date_time_formats.dart';
import '../utils/event_display.dart';
import 'swipe_event_actions.dart';

Future<void> showEventDetailSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Event event,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return _EventDetailSheet(event: event);
    },
  );
}

class _EventDetailSheet extends ConsumerStatefulWidget {
  const _EventDetailSheet({required this.event});

  final Event event;

  @override
  ConsumerState<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends ConsumerState<_EventDetailSheet> {
  late bool _completed;

  @override
  void initState() {
    super.initState();
    _completed = widget.event.isCompleted;
  }

  Future<void> _edit() async {
    Navigator.of(context).pop();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EventFormPage(eventId: widget.event.id),
      ),
    );
  }

  Future<void> _delete() async {
    if (isDemoEvent(widget.event)) return;
    final ok = await confirmDeleteEvent(context);
    if (!ok || !mounted) return;
    try {
      await ref.read(eventActionsProvider).delete(widget.event.id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).saveFailedRetry),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final isDemo = isDemoEvent(event);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final scheme = theme.colorScheme;

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                event.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 16),
            _Row(
              label: l10n.detailType,
              value: event.isTodo ? l10n.detailTodo : l10n.detailSchedule,
            ),
            const SizedBox(height: 8),
            if (event.hasDate) ...[
              _Row(
                label: l10n.detailDate,
                value: DateTimeFormats.formatSectionDate(
                  DateTimeFormats.parseDate(event.date),
                  l10n,
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (eventTimeLabel(event, l10n).isNotEmpty) ...[
              _Row(
                label: l10n.detailTime,
                value: eventTimeLabel(event, l10n),
              ),
              const SizedBox(height: 8),
            ],
            if (event.isNoTimeTodo)
              _Row(label: l10n.detailType, value: l10n.longTermTask),
            if (event.hasReminder) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.notifications_none_rounded,
                      size: 18,
                      color: scheme.primary.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.detailReminder,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatReminderOffsetsSummary(
                            l10n,
                            event.reminderOffsetsSeconds,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (event.reminderAnchorDateTime != null) ...[
              const SizedBox(height: 8),
              _Row(
                label: l10n.detailTimeUntilStart,
                value: formatDurationUntil(
                  l10n,
                  event.reminderAnchorDateTime!.difference(DateTime.now()),
                ),
              ),
            ],
            if (event.note != null && event.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.detailNote, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                event.note!,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 20),
            if (!isDemo) ...[
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _completed,
                onChanged: (v) async {
                  if (v == null) return;
                  setState(() => _completed = v);
                  if (event.isTodo) {
                    await ref
                        .read(eventActionsProvider)
                        .toggleTodo(event.id, v);
                  } else {
                    await ref
                        .read(eventActionsProvider)
                        .toggleTimeline(event.id, v);
                  }
                },
                title: Text(_completed ? l10n.completedLabel : l10n.markComplete),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _edit,
                      child: Text(l10n.edit),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.error,
                        foregroundColor: scheme.onError,
                      ),
                      onPressed: _delete,
                      child: Text(l10n.delete),
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                l10n.demoSampleReadOnlyHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.55),
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5),
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }
}

String formatTodoSectionDate(String dateKey, AppLocalizations l10n) {
  return DateTimeFormats.formatSectionDate(
    DateTimeFormats.parseDate(dateKey),
    l10n,
  );
}
