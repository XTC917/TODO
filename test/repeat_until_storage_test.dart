import 'package:flutter_test/flutter_test.dart';
import 'package:soft_schedule/core/utils/repeat_until_storage.dart';

void main() {
  test('parses and strips legacy repeatUntil note marker', () {
    const raw = 'Team sync\n#repeatUntil:2026-03-15';
    expect(RepeatUntilStorage.parseFromNote(raw), '2026-03-15');
    expect(RepeatUntilStorage.stripFromNote(raw), 'Team sync');
    expect(RepeatUntilStorage.userNote(raw), 'Team sync');
  });

  test('note-only repeatUntil marker strips to null user note', () {
    const raw = '#repeatUntil:2026-03-15';
    expect(RepeatUntilStorage.userNote(raw), isNull);
  });
}
