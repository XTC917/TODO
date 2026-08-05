import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks multi-select batch mode per screen.
class BatchSelection {
  const BatchSelection({
    this.active = false,
    this.selectedIds = const {},
  });

  final bool active;
  final Set<int> selectedIds;

  BatchSelection copyWith({
    bool? active,
    Set<int>? selectedIds,
  }) {
    return BatchSelection(
      active: active ?? this.active,
      selectedIds: selectedIds ?? this.selectedIds,
    );
  }
}

class BatchSelectionController extends StateNotifier<BatchSelection> {
  BatchSelectionController() : super(const BatchSelection());

  void enterWith(int id) {
    state = BatchSelection(active: true, selectedIds: {id});
  }

  void toggle(int id) {
    if (!state.active) return;
    final next = Set<int>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  void cancel() => state = const BatchSelection();

  bool isSelected(int id) => state.selectedIds.contains(id);
}

final homeBatchProvider =
    StateNotifierProvider<BatchSelectionController, BatchSelection>((ref) {
  return BatchSelectionController();
});

final todoBatchProvider =
    StateNotifierProvider<BatchSelectionController, BatchSelection>((ref) {
  return BatchSelectionController();
});

final todoCompletedExpandedProvider = StateProvider<bool>((ref) => false);
