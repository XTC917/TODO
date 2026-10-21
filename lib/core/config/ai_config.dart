/// Compile-time configuration for the private Gemini "AI Smart Add" build.
///
/// Values are injected through `--dart-define` or
/// `--dart-define-from-file=dev_config.json`. Everything defaults to the
/// public prod behavior, so a plain build never enables AI features and never
/// ships an API key.
///
/// Note: `--dart-define` only keeps the key out of Dart source control. It can
/// still be extracted from a compiled APK, so builds that include a real key
/// are for private devices only and must never be distributed.
class AiConfig {
  AiConfig._();

  /// `prod` (default) or `private`. Only `private` enables AI Smart Add.
  static const flutterFlavor =
      String.fromEnvironment('APP_FLAVOR', defaultValue: 'prod');

  /// Gemini API key. Empty unless supplied by the local dev config file.
  /// The public prod build never injects this value.
  static const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  /// Single source of truth for the model name; override only via dart-define.
  static const model = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.5-flash-lite',
  );

  static const _endpointBase =
      'https://generativelanguage.googleapis.com/v1beta';

  /// 3–5s is the target; hard-fail at 10s so the UI can offer a retry.
  static const requestTimeout = Duration(seconds: 10);

  /// `dev` is accepted as a legacy alias so older local config files keep
  /// working after the flavor was renamed to `private`.
  static bool get isPrivateFlavor =>
      flutterFlavor == 'private' || flutterFlavor == 'dev';

  /// Gate for every AI entry point, network call and UI affordance.
  static bool get isEnabled => isPrivateFlavor;

  static bool get hasApiKey => apiKey.trim().isNotEmpty;

  static Uri generateContentUri({String? modelOverride}) {
    final resolved = (modelOverride == null || modelOverride.isEmpty)
        ? model
        : modelOverride;
    return Uri.parse('$_endpointBase/models/$resolved:generateContent');
  }
}
