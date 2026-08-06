/// Sentinel value for todos without any date/time.
const kNoDate = '';

/// Max characters for event title and note (UI + validation).
const kMaxEventTitleLength = 50;
const kMaxEventNoteLength = 200;

extension EventDateX on String {
  bool get hasEventDate => isNotEmpty;
}
