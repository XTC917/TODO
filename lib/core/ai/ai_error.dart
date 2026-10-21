/// Failure categories for AI Smart Add, mapped to localized UI messages.
enum AiErrorKind {
  /// No API key in the dev config.
  missingKey,

  /// Request exceeded the configured timeout.
  timeout,

  /// No connectivity or the socket failed.
  network,

  /// 401 / 403 — bad or unauthorized key.
  unauthorized,

  /// 429 — quota / rate limit.
  rateLimited,

  /// 5xx or other unexpected HTTP status.
  server,

  /// Response was not valid JSON, or fields failed Dart validation.
  invalidResponse,
}

class AiSmartAddException implements Exception {
  const AiSmartAddException(this.kind, {this.detail, this.statusCode});

  final AiErrorKind kind;

  /// Short diagnostic. Never contains the API key.
  final String? detail;
  final int? statusCode;

  @override
  String toString() =>
      'AiSmartAddException(${kind.name}'
      '${statusCode == null ? '' : ', status: $statusCode'}'
      '${detail == null ? '' : ', detail: $detail'})';
}
