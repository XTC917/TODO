import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/utils/date_time_formats.dart';
import '../../../l10n/app_localizations.dart';

class FocusTaskSelection {
  const FocusTaskSelection({this.eventId, this.title});

  final int? eventId;
  final String? title;
}

Future<FocusTaskSelection?> showFocusTaskPickerSheet({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  return showModalBottomSheet<FocusTaskSelection>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => const _FocusTaskPickerSheet(),
  );
}

class _FocusTaskPickerSheet extends ConsumerWidget {
  const _FocusTaskPickerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final today = DateTimeFormats.dateOnly(DateTime.now());
    final eventsAsync = ref.watch(eventsForDateProvider(today));
    final todos = eventsAsync.valueOrNull
            ?.where((e) => e.isTodo && !e.isCompleted)
            .toList() ??
        [];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              l10n.focusSelectTask,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          ListTile(
            title: Text(l10n.focusNoTask),
            trailing: const Icon(Icons.block_rounded),
            onTap: () => Navigator.pop(
              context,
              const FocusTaskSelection(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              l10n.focusTodayTasks,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55),
                  ),
            ),
          ),
          Flexible(
            child: eventsAsync.when(
              data: (_) {
                if (todos.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        l10n.noTodosForDay,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.45),
                            ),
                      ),
                    ),
                  );
                }
                return ListView(
                  shrinkWrap: true,
                  children: [
                    for (final todo in todos)
                      ListTile(
                        title: Text(
                          todo.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(
                          context,
                          FocusTaskSelection(
                            eventId: todo.id,
                            title: todo.title,
                          ),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator.adaptive()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(24),
                child: Text(l10n.errorGeneric('$e')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
