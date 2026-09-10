import 'dart:async';

import 'package:aim_core/aim_core.dart';
import 'package:test/test.dart';

/// Runs [body] and returns everything printed inside it.
Future<(T, List<String>)> capturePrint<T>(Future<T> Function() body) async {
  final lines = <String>[];
  final result = await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return (result, lines);
}

void main() {
  group('Aim.handle() unhandled errors', () {
    test(
      'returns 500 without printing when no handler is registered',
      () async {
        final app = Aim();
        app.get('/boom', (c) async => throw Exception('boom'));

        final (response, printed) = await capturePrint(
          () => app.handle(Request('GET', Uri.parse('http://localhost/boom'))),
        );

        expect(response.statusCode, equals(500));
        expect(await response.readAsString(), contains('boom'));
        expect(printed, isEmpty);
      },
    );

    test('uses onUnhandledError when onError is not registered', () async {
      final app = Aim();
      app.get('/boom', (c) async => throw StateError('bad state'));
      Object? seenError;
      StackTrace? seenStack;

      final response = await app.handle(
        Request('GET', Uri.parse('http://localhost/boom')),
        onUnhandledError: (error, stackTrace, c) async {
          seenError = error;
          seenStack = stackTrace;
          return c.text('fallback', statusCode: 503);
        },
      );

      expect(response.statusCode, equals(503));
      expect(await response.readAsString(), equals('fallback'));
      expect(seenError, isA<StateError>());
      expect(seenStack, isNotNull);
    });

    test('registered onError takes precedence over onUnhandledError', () async {
      final app = Aim();
      app.get('/boom', (c) async => throw Exception('boom'));
      app.onError((error, c) async => c.text('registered', statusCode: 502));

      final response = await app.handle(
        Request('GET', Uri.parse('http://localhost/boom')),
        onUnhandledError: (_, _, c) async => c.text('fallback'),
      );

      expect(response.statusCode, equals(502));
      expect(await response.readAsString(), equals('registered'));
    });
  });
}
