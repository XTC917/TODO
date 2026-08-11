import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/services/focus_session_store.dart';

void main() {
  test('strict fail deadline is due after grace period', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final store = FocusSessionStore(prefs);

    final leftAt = DateTime(2026, 1, 1, 12, 0, 0);
    await store.setStrictBackgroundTracking(leftAt);

    expect(
      store.isStrictFailDue(leftAt.add(const Duration(seconds: 59))),
      isFalse,
    );
    expect(
      store.isStrictFailDue(leftAt.add(const Duration(seconds: 60))),
      isTrue,
    );

    await store.clearStrictBackgroundTracking();
    expect(store.isStrictFailDue(), isFalse);
  });
}
