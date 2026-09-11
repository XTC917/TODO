import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/app_providers.dart';
import '../../models/event.dart';

/// Unified in-memory data source for task search.
///
/// Watches the whole `events` table (history + future, todo + schedule),
/// so search never depends on which page opened it. Filtering, scoring and
/// recurring collapsing happen in `TaskSearchService`.
final allEventsForSearchProvider = StreamProvider<List<Event>>((ref) {
  return ref.watch(eventRepositoryProvider).watchAllEvents();
});
