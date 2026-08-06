import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

void showDemoReadOnlySnackBar(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(AppLocalizations.of(context).demoSampleReadOnlyHint),
    ),
  );
}
