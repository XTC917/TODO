import '../providers/app_providers.dart';
import '../providers/l10n_providers.dart';
import 'app_config.dart';

/// Picks the feedback form URL for the current app language setting.
String resolveFeedbackFormUrl(AppLanguage language) {
  final code = resolveAppLocale(language).languageCode;
  if (code == 'zh') return AppConfig.feedbackFormUrlZh;
  return AppConfig.feedbackFormUrlDefault;
}
