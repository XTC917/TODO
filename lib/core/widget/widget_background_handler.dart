import 'package:flutter/widgets.dart';

import '../../database/app_database.dart';
import '../../database/event_repository.dart';
import 'home_widget_keys.dart';
import 'home_widget_snapshot.dart';

/// Handles widget background actions (e.g. toggle todo from home screen).
Future<void> handleWidgetBackgroundUri(Uri? uri) async {
  if (uri == null || uri.scheme != HomeWidgetUris.scheme) return;

  if (uri.host == 'todo' && uri.path == '/toggle') {
    final id = int.tryParse(uri.queryParameters['id'] ?? '');
    if (id == null) return;

    WidgetsFlutterBinding.ensureInitialized();
    final db = AppDatabase();
    try {
      final repo = EventRepository(db);
      final event = await repo.getById(id);
      if (event == null || !event.isTodo) return;
      await repo.toggleTimelineForOccurrence(
        event,
        completed: !event.isCompleted,
      );
      await HomeWidgetSnapshotWriter.syncFromDatabase();
    } catch (e, st) {
      debugPrint('Widget background toggle failed: $e\n$st');
    } finally {
      await db.close();
    }
    return;
  }

  if (uri.host == 'todo' && uri.path == '/sync') {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final dropCompleted = uri.queryParameters['drop'] == '1';
      await HomeWidgetSnapshotWriter.syncFromDatabase(
        dropCompletedFromWidget: dropCompleted,
      );
    } catch (e, st) {
      debugPrint('Widget background sync failed: $e\n$st');
    }
  }
}
