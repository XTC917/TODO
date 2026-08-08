import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/enums.dart';
import '../../models/event.dart';

Future<RepeatScope?> pickRepeatScope(
  BuildContext context, {
  required RepeatScopeAction action,
  Event? event,
}) {
  if (event == null || !event.isRepeatSeriesOccurrence) {
    return Future.value(RepeatScope.onlyThis);
  }

  final l10n = AppLocalizations.of(context);
  return showDialog<RepeatScope>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: Text(_title(l10n, action)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final scope in RepeatScope.values)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_scopeLabel(l10n, scope)),
                subtitle: Text(_scopeHint(l10n, action, scope)),
                onTap: () => Navigator.pop(ctx, scope),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
        ],
      );
    },
  );
}

enum RepeatScopeAction { edit, delete }

String _title(AppLocalizations l10n, RepeatScopeAction action) {
  return switch (action) {
    RepeatScopeAction.edit => l10n.repeatScopeEditTitle,
    RepeatScopeAction.delete => l10n.repeatScopeDeleteTitle,
  };
}

String _scopeLabel(AppLocalizations l10n, RepeatScope scope) {
  return switch (scope) {
    RepeatScope.onlyThis => l10n.repeatScopeOnlyThis,
    RepeatScope.thisAndFuture => l10n.repeatScopeThisAndFuture,
    RepeatScope.all => l10n.repeatScopeAll,
  };
}

String _scopeHint(
  AppLocalizations l10n,
  RepeatScopeAction action,
  RepeatScope scope,
) {
  if (action == RepeatScopeAction.delete) {
    return switch (scope) {
      RepeatScope.onlyThis => l10n.repeatScopeDeleteOnlyThisHint,
      RepeatScope.thisAndFuture => l10n.repeatScopeDeleteFutureHint,
      RepeatScope.all => l10n.repeatScopeDeleteAllHint,
    };
  }
  return switch (scope) {
    RepeatScope.onlyThis => l10n.repeatScopeEditOnlyThisHint,
    RepeatScope.thisAndFuture => l10n.repeatScopeEditFutureHint,
    RepeatScope.all => l10n.repeatScopeEditAllHint,
  };
}

Future<bool> confirmDeleteOccurrence(
  BuildContext context, {
  required Event event,
}) async {
  final l10n = AppLocalizations.of(context);
  if (!event.isRepeatSeriesOccurrence) {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    return ok == true;
  }

  final scope = await pickRepeatScope(
    context,
    action: RepeatScopeAction.delete,
    event: event,
  );
  return scope != null;
}

Future<RepeatScope?> pickDeleteScope(
  BuildContext context, {
  required Event event,
}) async {
  if (!event.isRepeatSeriesOccurrence) {
    final ok = await confirmDeleteOccurrence(context, event: event);
    return ok ? RepeatScope.onlyThis : null;
  }
  return pickRepeatScope(
    context,
    action: RepeatScopeAction.delete,
    event: event,
  );
}
