import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soft_schedule/core/ai/ai_error.dart';
import 'package:soft_schedule/core/ai/ai_smart_add_service.dart';
import 'package:soft_schedule/core/ai/gemini_client.dart';
import 'package:soft_schedule/core/config/ai_config.dart';
import 'package:soft_schedule/core/providers/app_providers.dart';
import 'package:soft_schedule/core/utils/parsed_task.dart';
import 'package:soft_schedule/core/utils/parsed_task_draft.dart';
import 'package:soft_schedule/models/enums.dart';
import 'package:soft_schedule/models/event.dart';

/// Records the last request while always returning [status].
class _FakeTransport {
  _FakeTransport({
    this.status = 200,
    this.content,
    this.rawBody,
    this.delay,
    this.throwNetwork = false,
  });

  final int status;
  final Map<String, Object?>? content;
  final String? rawBody;
  final Duration? delay;
  final bool throwNetwork;

  GeminiHttpRequest? lastRequest;

  Future<GeminiHttpResponse> call(GeminiHttpRequest request) async {
    lastRequest = request;
    if (delay != null) await Future<void>.delayed(delay!);
    if (throwNetwork) {
      throw const SocketLikeException();
    }
    final body = rawBody ??
        jsonEncode({
          'candidates': [
            {
              'content': {
                'parts': [
                  {'text': jsonEncode(content ?? const <String, Object?>{})},
                ],
              },
            },
          ],
        });
    return GeminiHttpResponse(status, body);
  }
}

class SocketLikeException implements Exception {
  const SocketLikeException();
}

Map<String, Object?> _content({
  String title = '英语课',
  Object? date = '2026-11-01',
  Object? startTime = '15:00',
  Object? endTime = '17:40',
  Object? note = '301教室',
  String taskType = 'schedule',
  String todoTimeMode = 'timeBlock',
  List<Object?> reminders = const [1800, 3600],
}) {
  return {
    'title': title,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'note': note,
    'taskType': taskType,
    'todoTimeMode': todoTimeMode,
    'reminders': reminders,
  };
}

AiSmartAddService _service(_FakeTransport transport, {String apiKey = 'test-key'}) {
  return AiSmartAddService(
    apiKey: apiKey,
    model: 'test-model',
    transport: transport.call,
    timeout: const Duration(milliseconds: 200),
  );
}

void main() {
  final reference = DateTime(2026, 10, 20, 9, 30);
  const input = '11.1下午三点到五点四十上英语课，提前半小时和一小时通知我，备注一下在301教室';

  group('AiConfig', () {
    test('defaults to prod with no key for public builds and tests', () {
      expect(AiConfig.isPrivateFlavor, isFalse);
      expect(AiConfig.isEnabled, isFalse);
      expect(AiConfig.hasApiKey, isFalse);
      expect(AiConfig.model, isNotEmpty);
    });
  });

  group('Gemini structured output request', () {
    test('sends key in header (not URL), schema and reference date', () async {
      final transport = _FakeTransport(content: _content());
      final service = _service(transport);

      await service.parse(input, reference: reference, languageCode: 'zh');

      final request = transport.lastRequest!;
      expect(request.headers['x-goog-api-key'], 'test-key');
      expect(request.uri.toString(), isNot(contains('test-key')));
      expect(request.uri.toString(), contains('test-model'));

      final config =
          request.jsonBody['generationConfig'] as Map<String, Object?>;
      expect(config['responseMimeType'], 'application/json');
      expect(config['responseSchema'], isA<Map<String, Object?>>());

      final prompt = (request.jsonBody['contents'] as List)
          .first['parts'][0]['text'] as String;
      expect(prompt, contains('2026-10-20'));
      expect(prompt, contains('UTC'));
      expect(prompt, contains('11.1'));
    });
  });

  group('ParsedTask extraction', () {
    test('maps the full example onto schedule fields', () async {
      final transport = _FakeTransport(content: _content());
      final service = _service(transport);

      final parsed =
          await service.parse(input, reference: reference, languageCode: 'zh');

      expect(parsed.title, '英语课');
      expect(parsed.date, DateTime(2026, 11, 1));
      expect(parsed.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(parsed.endTime, const TimeOfDay(hour: 17, minute: 40));
      expect(parsed.note, '301教室');
      expect(parsed.taskType, TaskType.schedule);
      expect(parsed.todoTimeMode, TodoTimeMode.timeBlock);
      expect(parsed.reminderOffsetsSeconds, [3600, 1800]);
      expect(parsed.needsDateConfirmation, isFalse);
    });

    test('schedule with only a start time keeps the end empty', () async {
      final transport = _FakeTransport(
        content: _content(
          title: '开会',
          date: '2026-11-01',
          startTime: '15:00',
          endTime: null,
          note: null,
          reminders: const [],
        ),
      );
      final service = _service(transport);

      final parsed =
          await service.parse(input, reference: reference, languageCode: 'zh');

      expect(parsed.taskType, TaskType.schedule);
      expect(parsed.startTime, const TimeOfDay(hour: 15, minute: 0));
      expect(parsed.endTime, isNull);
    });

    test('missing date with time requires confirmation, never "today"',
        () async {
      final transport = _FakeTransport(
        content: _content(date: null, reminders: const [1800]),
      );
      final service = _service(transport);

      final parsed =
          await service.parse(input, reference: reference, languageCode: 'zh');

      expect(parsed.date, isNull);
      expect(parsed.needsDateConfirmation, isTrue);
      expect(parsed.reminderOffsetsSeconds, [1800]);
    });

    test('rejects an impossible date instead of saving silently', () async {
      final transport = _FakeTransport(content: _content(date: '2026-02-30'));
      final service = _service(transport);

      await expectLater(
        service.parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.invalidResponse),
        ),
      );
    });

    test('drops invalid reminders, dedupes and sorts descending', () async {
      final transport = _FakeTransport(
        content: _content(reminders: const [1800, 1800, -10, 3600, '600']),
      );
      final service = _service(transport);

      final parsed =
          await service.parse(input, reference: reference, languageCode: 'zh');

      expect(parsed.reminderOffsetsSeconds, [3600, 1800, 600]);
    });

    test('normalizes a deadline todo onto endTime', () async {
      final transport = _FakeTransport(
        content: _content(
          title: '交作业',
          startTime: '18:00',
          endTime: null,
          note: null,
          taskType: 'todo',
          todoTimeMode: 'deadline',
          reminders: const [600],
        ),
      );
      final service = _service(transport);

      final parsed =
          await service.parse(input, reference: reference, languageCode: 'zh');

      expect(parsed.taskType, TaskType.todo);
      expect(parsed.todoTimeMode, TodoTimeMode.deadline);
      expect(parsed.startTime, isNull);
      expect(parsed.endTime, const TimeOfDay(hour: 18, minute: 0));
      expect(parsed.reminderOffsetsSeconds, [600]);
    });

    test('empty title is rejected', () async {
      final transport = _FakeTransport(content: _content(title: '   '));
      final service = _service(transport);

      await expectLater(
        service.parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.invalidResponse),
        ),
      );
    });
  });

  group('Failure handling', () {
    test('missing key fails friendly without a network call', () async {
      final transport = _FakeTransport(content: _content());
      final service = _service(transport, apiKey: '');

      await expectLater(
        service.parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.missingKey),
        ),
      );
      expect(transport.lastRequest, isNull);
      expect(service.isConfigured, isFalse);
    });

    test('maps 401/403 to unauthorized', () async {
      for (final status in [401, 403]) {
        final transport = _FakeTransport(status: status);
        await expectLater(
          _service(transport)
              .parse(input, reference: reference, languageCode: 'zh'),
          throwsA(
            isA<AiSmartAddException>()
                .having((e) => e.kind, 'kind', AiErrorKind.unauthorized),
          ),
        );
      }
    });

    test('maps 429 to rateLimited', () async {
      final transport = _FakeTransport(status: 429);
      await expectLater(
        _service(transport)
            .parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.rateLimited),
        ),
      );
    });

    test('maps 5xx to server', () async {
      final transport = _FakeTransport(status: 503);
      await expectLater(
        _service(transport)
            .parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.server),
        ),
      );
    });

    test('maps malformed payload to invalidResponse', () async {
      final transport = _FakeTransport(rawBody: 'not-json');
      await expectLater(
        _service(transport)
            .parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.invalidResponse),
        ),
      );
    });

    test('times out after the configured budget', () async {
      final transport = _FakeTransport(
        content: _content(),
        delay: const Duration(milliseconds: 400),
      );
      final service = AiSmartAddService(
        apiKey: 'test-key',
        transport: transport.call,
        timeout: const Duration(milliseconds: 30),
      );

      await expectLater(
        service.parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.timeout),
        ),
      );
    });

    test('maps socket failures to network', () async {
      final transport = _FakeTransport(throwNetwork: true);
      await expectLater(
        _service(transport)
            .parse(input, reference: reference, languageCode: 'zh'),
        throwsA(
          isA<AiSmartAddException>()
              .having((e) => e.kind, 'kind', AiErrorKind.network),
        ),
      );
    });
  });

  group('Draft mapping', () {
    testWidgets('maps note and multiple reminders onto EventDraft',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final transport = _FakeTransport(content: _content());
      final parsed = await _service(transport)
          .parse(input, reference: reference, languageCode: 'zh');

      late EventDraft draft;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, providerRef, _) {
                draft = parsedTaskToDraft(parsed, providerRef);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(draft.title, '英语课');
      expect(draft.date, '2026-11-01');
      expect(draft.startTime, '15:00');
      expect(draft.endTime, '17:40');
      expect(draft.note, '301教室');
      expect(draft.taskType, TaskType.schedule);
      expect(draft.reminderOffsetsSeconds, [3600, 1800]);
    });

    testWidgets('start-only schedule maps to an empty EventDraft endTime',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final transport = _FakeTransport(
        content: _content(
          title: '开会',
          date: '2026-11-01',
          startTime: '15:00',
          endTime: null,
          note: null,
          reminders: const [],
        ),
      );
      final parsed = await _service(transport)
          .parse(input, reference: reference, languageCode: 'zh');

      late EventDraft draft;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, providerRef, _) {
                draft = parsedTaskToDraft(parsed, providerRef);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(draft.startTime, '15:00');
      expect(draft.endTime, isEmpty);
      expect(draft.taskType, TaskType.schedule);
    });

    testWidgets('unresolved date blocks direct save', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final transport = _FakeTransport(
        content: _content(date: null, reminders: const [1800]),
      );
      final ParsedTask parsed = await _service(transport)
          .parse(input, reference: reference, languageCode: 'zh');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: MaterialApp(
            home: Consumer(
              builder: (context, providerRef, _) {
                expect(
                  () => parsedTaskToDraft(parsed, providerRef),
                  throwsStateError,
                );
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(parsed.needsDateConfirmation, isTrue);
    });
  });
}
