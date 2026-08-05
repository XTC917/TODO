import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../../l10n/app_localizations.dart';
import '../providers/app_providers.dart';
import '../utils/date_time_formats.dart';
import '../utils/event_display.dart';

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

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
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
            if (event.note != null && event.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(l10n.detailNote, style: theme.textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                event.note!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            const SizedBox(height: 20),
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
          ],
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
