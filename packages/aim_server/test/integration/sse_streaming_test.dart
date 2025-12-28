import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('SSE Streaming Integration', () {
    late Aim app;
    late AimHttpServer server;
    late int port;

    setUp(() async {
      app = Aim();
      // Use port 0 to let the OS assign an available port
      server = await app.serve(host: 'localhost', port: 0);
      port = server.port;
    });

    tearDown(() async {
      await server.close();
    });

    test('streams SSE events in real-time with bufferOutput disabled',
        () async {
      // Create an endpoint that returns SSE stream
      app.get('/events', (c) async {
        final controller = StreamController<List<int>>();

        // Send events with delay
        Future(() async {
          for (var i = 1; i <= 3; i++) {
            final event = 'data: Event $i\n\n';
            controller.add(utf8.encode(event));
            await Future.delayed(Duration(milliseconds: 100));
          }
          controller.close();
        });

        return c.stream(
          controller.stream,
          headers: {
            'content-type': 'text/event-stream; charset=utf-8',
            'cache-control': 'no-cache',
            'connection': 'keep-alive',
          },
        );
      });

      // Connect with HTTP client
      final client = HttpClient();
      final request = await client.get('localhost', port, '/events');
      final response = await request.close();

      // Verify headers
      expect(response.statusCode, 200);
      expect(
        response.headers.value('content-type'),
        contains('text/event-stream'),
      );

      // Collect events with timestamps
      final events = <String>[];
      final stopwatch = Stopwatch()..start();
      final timestamps = <int>[];

      await for (final chunk in response) {
        final text = utf8.decode(chunk);
        events.add(text);
        timestamps.add(stopwatch.elapsedMilliseconds);

        if (events.length >= 3) {
          break;
        }
      }

      client.close();

      // Verify events were received
      expect(events.length, 3);

      // Verify real-time streaming (not buffered)
      // First event should arrive quickly (within 150ms)
      expect(timestamps[0], lessThan(150));

      // Second event should arrive ~100ms after start
      expect(timestamps[1], greaterThan(80));
      expect(timestamps[1], lessThan(200));

      // Third event should arrive ~200ms after start
      expect(timestamps[2], greaterThan(180));
      expect(timestamps[2], lessThan(300));

      // Verify event contents
      expect(events.join(), contains('Event 1'));
      expect(events.join(), contains('Event 2'));
      expect(events.join(), contains('Event 3'));
    });

    test('buffers non-SSE responses normally', () async {
      // Create a regular JSON endpoint (not SSE)
      app.get('/json', (c) async {
        final controller = StreamController<List<int>>();

        // Send data with delay
        Future(() async {
          for (var i = 1; i <= 3; i++) {
            controller.add(utf8.encode('{"count":$i}'));
            await Future.delayed(Duration(milliseconds: 100));
          }
          controller.close();
        });

        return c.stream(
          controller.stream,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = HttpClient();
      final request = await client.get('localhost', port, '/json');
      final response = await request.close();

      expect(response.statusCode, 200);
      expect(response.headers.value('content-type'), 'application/json');

      // For non-SSE responses, buffering is enabled,
      // so we just verify the response is received correctly
      final body = await response.transform(utf8.decoder).join();
      expect(body, isNotEmpty);

      client.close();
    });
  });
}
