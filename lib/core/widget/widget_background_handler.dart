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
      await repo.toggleTodoComplete(id, completed: !event.isCompleted);
      await HomeWidgetSnapshotWriter.syncFromDatabase();
    } catch (e, st) {
      debugPrint('Widget background toggle failed: $e\n$st');
    } finally {
      await db.close();
    }
  }
}
