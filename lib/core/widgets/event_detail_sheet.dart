import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/event.dart';
import '../providers/app_providers.dart';
import '../utils/date_time_formats.dart';

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
    _completed = widget.event.isTodo
        ? widget.event.isCompleted
        : widget.event.isTimelineDone(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final theme = Theme.of(context);

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
            if (event.hasDate) ...[
              _Row(label: 'Date', value: _formatDateLabel(event.date)),
              const SizedBox(height: 8),
            ],
            if (event.timeLabel.isNotEmpty) ...[
              _Row(label: 'Time', value: event.timeLabel),
              const SizedBox(height: 8),
            ],
            if (event.isNoTimeTodo)
              _Row(label: 'Type', value: 'No time'),
            if (event.note != null && event.note!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Note', style: theme.textTheme.labelLarge),
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
              title: Text(_completed ? 'Completed' : 'Mark complete'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateLabel(String date) {
    final d = DateTime.parse(date);
    final today = DateTimeFormats.dateOnly(DateTime.now());
    if (DateTimeFormats.isSameDay(d, today)) return 'Today';
    if (DateTimeFormats.isSameDay(d, today.add(const Duration(days: 1)))) {
      return 'Tomorrow';
    }
    return DateTimeFormats.formatDate(d);
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

String formatTodoSectionDate(String dateKey) {
  final d = DateTime.parse(dateKey);
  final today = DateTimeFormats.dateOnly(DateTime.now());
  if (DateTimeFormats.isSameDay(d, today)) return 'Today';
  if (DateTimeFormats.isSameDay(d, today.add(const Duration(days: 1)))) {
    return 'Tomorrow';
  }
  return DateTimeFormats.formatHeader(d);
}
