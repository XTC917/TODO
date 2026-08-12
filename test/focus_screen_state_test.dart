import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/services/focus_screen_state.dart';

void main() {
  test('evaluateStrictLeaveSamples treats any lock sample as not leaving', () {
    expect(FocusScreenState.evaluateStrictLeaveSamples([false, true]), isFalse);
    expect(FocusScreenState.evaluateStrictLeaveSamples([true]), isFalse);
    expect(FocusScreenState.evaluateStrictLeaveSamples([false, false]), isTrue);
    expect(FocusScreenState.evaluateStrictLeaveSamples([]), isTrue);
  });
}
