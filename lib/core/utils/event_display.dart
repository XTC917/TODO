import '../../l10n/app_localizations.dart';
import '../../models/event.dart';
import '../../models/enums.dart';

/// Localized subtitle shown on todo cards and detail sheets.
String eventTimeLabel(Event event, AppLocalizations l10n) {
  if (event.isNoTimeTodo) return '';
  if (event.isSchedule || event.todoTimeMode == TodoTimeMode.timeBlock) {
    if (event.startTime.isEmpty || event.endTime.isEmpty) return '';
    return '${event.startTime} – ${event.endTime}';
  }
  if (event.todoTimeMode == TodoTimeMode.deadline) {
    return event.endTime.isEmpty ? '' : '${l10n.deadline} ${event.endTime}';
  }
  return '';
}
