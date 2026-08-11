/// Internal storage for recurring-series end dates (not user-visible notes).
class RepeatUntilStorage {
  RepeatUntilStorage._();

  static final _parsePattern = RegExp(r'#repeatUntil:(\d{4}-\d{2}-\d{2})');
  static final _stripPattern = RegExp(r'\n?#repeatUntil:\d{4}-\d{2}-\d{2}');

  static String? parseFromNote(String? note) {
    if (note == null || note.isEmpty) return null;
    return _parsePattern.firstMatch(note)?.group(1);
  }

  static String? stripFromNote(String? note) {
    if (note == null) return null;
    final cleaned = note.replaceAll(_stripPattern, '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  static String? userNote(String? note, {String? repeatUntil}) {
    return stripFromNote(note);
  }
}
