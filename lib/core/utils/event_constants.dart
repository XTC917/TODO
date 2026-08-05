/// Sentinel value for todos without any date/time.
const kNoDate = '';

extension EventDateX on String {
  bool get hasEventDate => isNotEmpty;
}
