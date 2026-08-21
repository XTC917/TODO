import '../../l10n/app_localizations.dart';

enum AutostartGuideType {
  xiaomi,
  huawei,
  oppo,
  vivo,
  samsung,
  generic;

  static AutostartGuideType fromStorage(String? raw) {
    return switch (raw) {
      'xiaomi' => AutostartGuideType.xiaomi,
      'huawei' => AutostartGuideType.huawei,
      'oppo' => AutostartGuideType.oppo,
      'vivo' => AutostartGuideType.vivo,
      'samsung' => AutostartGuideType.samsung,
      _ => AutostartGuideType.generic,
    };
  }
}

String autostartManualGuide(AppLocalizations l10n, AutostartGuideType type) {
  return switch (type) {
    AutostartGuideType.xiaomi => l10n.autostartManualGuideXiaomi,
    AutostartGuideType.huawei => l10n.autostartManualGuideHuawei,
    AutostartGuideType.oppo => l10n.autostartManualGuideOppo,
    AutostartGuideType.vivo => l10n.autostartManualGuideVivo,
    AutostartGuideType.samsung => l10n.autostartManualGuideSamsung,
    AutostartGuideType.generic => l10n.autostartManualGuideGeneric,
  };
}

class AutostartOpenResult {
  const AutostartOpenResult({
    required this.opened,
    required this.destination,
  });

  final bool opened;
  final String destination;

  bool get openedDirectSettings =>
      opened && destination != 'app_details' && destination != 'failed';

  bool get openedAppDetails => opened && destination == 'app_details';

  factory AutostartOpenResult.fromMap(Object? raw) {
    if (raw is! Map) {
      return const AutostartOpenResult(opened: false, destination: 'failed');
    }
    return AutostartOpenResult(
      opened: raw['opened'] == true,
      destination: raw['destination'] as String? ?? 'failed',
    );
  }
}
