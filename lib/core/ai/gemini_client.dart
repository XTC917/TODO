import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/ai_config.dart';
import 'ai_error.dart';

/// Minimal HTTP request description so tests can run without a network.
class GeminiHttpRequest {
  const GeminiHttpRequest({
    required this.uri,
    required this.headers,
    required this.jsonBody,
  });

  final Uri uri;
  final Map<String, String> headers;
  final Map<String, Object?> jsonBody;

  String get encodedBody => jsonEncode(jsonBody);
}

class GeminiHttpResponse {
  const GeminiHttpResponse(this.statusCode, this.body);

  final int statusCode;
  final String body;
}

typedef GeminiTransport = Future<GeminiHttpResponse> Function(
  GeminiHttpRequest request,
);

/// Default transport — a single HTTPS POST via `package:http`.
Future<GeminiHttpResponse> defaultGeminiTransport(
  GeminiHttpRequest request,
) async {
  final response = await http.post(
    request.uri,
    headers: request.headers,
    body: request.encodedBody,
  );
  return GeminiHttpResponse(response.statusCode, response.body);
}

/// Thin Gemini REST client that requests a structured JSON object.
///
/// The API key travels in the `x-goog-api-key` header (never in the URL or
/// logs) so it cannot leak through request logging.
class GeminiClient {
  GeminiClient({
    GeminiTransport? transport,
    Duration? timeout,
    String? apiKey,
    String? model,
  })  : _transport = transport ?? defaultGeminiTransport,
        _timeout = timeout ?? AiConfig.requestTimeout,
        _apiKey = apiKey ?? AiConfig.apiKey,
        _model = model ?? AiConfig.model;

  final GeminiTransport _transport;
  final Duration _timeout;
  final String _apiKey;
  final String _model;

  bool get hasApiKey => _apiKey.trim().isNotEmpty;

  Future<Map<String, Object?>> generateJson({
    required String prompt,
    required Map<String, Object?> responseSchema,
  }) async {
    if (!hasApiKey) {
      _logDebug('missing api key, model=$_model');
      throw const AiSmartAddException(AiErrorKind.missingKey);
    }

    final request = GeminiHttpRequest(
      uri: AiConfig.generateContentUri(modelOverride: _model),
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _apiKey,
      },
      jsonBody: {
        'contents': [
          {
            'role': 'user',
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0,
          'responseMimeType': 'application/json',
          'responseSchema': responseSchema,
        },
      },
    );

    final GeminiHttpResponse response;
    try {
      response = await _transport(request).timeout(_timeout);
    } on TimeoutException {
      _logDebug('timeout after ${_timeout.inMilliseconds}ms, model=$_model');
      throw const AiSmartAddException(AiErrorKind.timeout);
    } on AiSmartAddException {
      rethrow;
    } catch (error) {
      // Only the exception type: never the message, which may echo the URL.
      _logDebug('transport failure type=${error.runtimeType}, model=$_model');
      throw AiSmartAddException(
        AiErrorKind.network,
        detail: error.runtimeType.toString(),
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      _logHttpFailure('unauthorized', response);
      throw AiSmartAddException(
        AiErrorKind.unauthorized,
        statusCode: response.statusCode,
        detail: 'http-${response.statusCode}',
      );
    }
    if (response.statusCode == 429) {
      _logHttpFailure('rateLimited', response);
      throw AiSmartAddException(
        AiErrorKind.rateLimited,
        statusCode: response.statusCode,
        detail: 'http-${response.statusCode}',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      _logHttpFailure('server', response);
      throw AiSmartAddException(
        AiErrorKind.server,
        statusCode: response.statusCode,
        detail: 'http-${response.statusCode}',
      );
    }

    _logDebug('HTTP ${response.statusCode} ok, model=$_model, parsing JSON');
    return _extractJsonObject(response.body);
  }

  /// Debug-only, privacy-safe diagnostics.
  ///
  /// Logs only the HTTP status, Gemini's structured error fields and a
  /// redacted/truncated message. Never logs the API key, request headers,
  /// request body, prompt, or user schedule content.
  void _logDebug(String message) {
    if (!kDebugMode) return;
    debugPrint('[JUJU-AI][gemini] $message');
  }

  void _logHttpFailure(String kind, GeminiHttpResponse response) {
    if (!kDebugMode) return;

    var code = '';
    var status = '';
    var messagePart = 'body_unparsed(len=${response.body.length})';
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['error'] is Map) {
        final error = decoded['error'] as Map;
        code = '${error['code'] ?? ''}';
        status = '${error['status'] ?? ''}';
        messagePart = _sanitize('${error['message'] ?? ''}');
      }
    } catch (_) {
      // Keep the non-sensitive fallback marker only.
    }

    _logDebug(
      'HTTP ${response.statusCode} kind=$kind model=$_model '
      'gemini.code=$code gemini.status=$status message=$messagePart',
    );
  }

  String _sanitize(String text) {
    if (text.isEmpty) return '';
    var sanitized = text
        .replaceAll(RegExp(r'AIza[0-9A-Za-z_\-]{10,}'), '[redacted-key]')
        .replaceAll(
          RegExp(r'key=[^&\s]+', caseSensitive: false),
          'key=[redacted]',
        )
        .replaceAll(RegExp(r'[\r\n\t]+'), ' ')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
    if (sanitized.length > 300) {
      sanitized = '${sanitized.substring(0, 300)}…';
    }
    return sanitized;
  }

  AiSmartAddException _invalid(String reason) {
    _logDebug('invalid response: $reason, model=$_model');
    return AiSmartAddException(AiErrorKind.invalidResponse, detail: reason);
  }

  Map<String, Object?> _extractJsonObject(String rawBody) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawBody);
    } catch (_) {
      throw _invalid('envelope_not_json(len=${rawBody.length})');
    }
    if (decoded is! Map) {
      throw _invalid('envelope_not_map');
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      final blockReason = decoded['promptFeedback'];
      final reason =
          blockReason is Map ? blockReason['blockReason'] : null;
      throw _invalid('no_candidates${reason == null ? '' : ' block=$reason'}');
    }

    final first = candidates.first;
    if (first is! Map) {
      throw _invalid('candidate_not_map');
    }
    final finishReason = first['finishReason'];
    final content = first['content'];
    if (content is! Map) {
      throw _invalid('no_content finish=$finishReason');
    }
    final parts = content['parts'];
    if (parts is! List) {
      throw _invalid('no_parts finish=$finishReason');
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }

    final text = _stripCodeFence(buffer.toString().trim());
    if (text.isEmpty) {
      throw _invalid('empty_text finish=$finishReason');
    }

    final Object? payload;
    try {
      payload = jsonDecode(text);
    } catch (_) {
      // Length only — never the model output, which may echo user content.
      throw _invalid('payload_not_json(len=${text.length})');
    }
    if (payload is! Map) {
      throw _invalid('payload_not_map type=${payload.runtimeType}');
    }
    final result = Map<String, Object?>.from(payload);
    _logDebug(
      'parsed JSON keys=${result.keys.length} finish=$finishReason',
    );
    return result;
  }

  String _stripCodeFence(String text) {
    if (!text.startsWith('```')) return text;
    var body = text;
    final firstNewline = body.indexOf('\n');
    if (firstNewline >= 0) {
      body = body.substring(firstNewline + 1);
    }
    final closing = body.lastIndexOf('```');
    if (closing >= 0) {
      body = body.substring(0, closing);
    }
    return body.trim();
  }
}
