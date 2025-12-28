import 'dart:convert';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_sse/aim_server_sse.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  group('SSE', () {
    late Aim app;

    setUp(() {
      app = Aim();
    });

    test('sends basic SSE events', () async {
      app.get('/events', (c) async {
        return c.sse((stream) async {
          stream.send('Hello');
          stream.send('World');
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      expect(response.statusCode, 200);
      expect(response.headers['content-type'],
          'text/event-stream; charset=utf-8');
      expect(response.headers['cache-control'], 'no-cache');
      expect(response.headers['connection'], 'keep-alive');

      final body = await response.bodyAsString();
      expect(body, contains('data: Hello\n'));
      expect(body, contains('data: World\n'));
    });

    test('sends JSON events', () async {
      app.get('/events', (c) async {
        return c.sse((stream) async {
          stream.sendJson({'message': 'Hello'}, event: 'greeting', id: '1');
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      final body = await response.bodyAsString();
      expect(body, contains('event: greeting\n'));
      expect(body, contains('data: {"message":"Hello"}\n'));
      expect(body, contains('id: 1\n'));
    });

    test('sends keep-alive', () async {
      app.get('/events', (c) async {
        return c.sse((stream) async {
          stream.keepAlive();
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      final body = await response.bodyAsString();
      expect(body, contains(': \n'));
    });

    test('sends comments', () async {
      app.get('/events', (c) async {
        return c.sse((stream) async {
          stream.comment('debug info');
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      final body = await response.bodyAsString();
      expect(body, contains(': debug info\n'));
    });

    test('handles multi-line data', () async {
      app.get('/events', (c) async {
        return c.sse((stream) async {
          stream.send('line1\nline2\nline3');
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      final body = await response.bodyAsString();
      expect(body, contains('data: line1\n'));
      expect(body, contains('data: line2\n'));
      expect(body, contains('data: line3\n'));
    });

    test('sets retry interval', () async {
      app.get('/events', (c) async {
        return c.sse((stream) async {
          stream.send('Hello', retry: 5000);
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      final body = await response.bodyAsString();
      expect(body, contains('retry: 5000\n'));
    });

    test('closes stream after callback completes', () async {
      var completed = false;

      app.get('/events', (c) async {
        return c.sse((stream) async {
          stream.send('Start');
          await Future.delayed(Duration(milliseconds: 10));
          stream.send('End');
          completed = true;
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      await response.bodyAsString();
      await Future.delayed(Duration(milliseconds: 50));

      expect(completed, isTrue);
    });

    test('streams events in real-time', () async {
      app.get('/events', (c) async {
        return c.sse((stream) async {
          for (var i = 1; i <= 3; i++) {
            stream.send('Event $i');
            await Future.delayed(Duration(milliseconds: 100));
          }
        });
      });

      final client = TestClient(app);
      final response = await client.get('/events');

      final chunks = <String>[];
      final stopwatch = Stopwatch()..start();
      final timestamps = <int>[];

      // Response.read() を使ってストリームを読み取る
      await for (final chunk in response.response.read()) {
        final text = utf8.decode(chunk);
        chunks.add(text);
        timestamps.add(stopwatch.elapsedMilliseconds);

        // 3つのイベントを受信したら終了
        if (chunks.length >= 3) {
          break;
        }
      }

      // イベントが3つ受信されたことを確認
      expect(chunks.length, 3);

      // 最初のイベントはすぐに届く（150ms以内）
      expect(timestamps[0], lessThan(150));

      // 2つ目のイベントは約100ms後に届く
      expect(timestamps[1], greaterThan(80));
      expect(timestamps[1], lessThan(200));

      // 3つ目のイベントは約200ms後に届く
      expect(timestamps[2], greaterThan(180));
      expect(timestamps[2], lessThan(300));

      // 各チャンクに期待される内容が含まれることを確認
      expect(chunks.join(), contains('Event 1'));
      expect(chunks.join(), contains('Event 2'));
      expect(chunks.join(), contains('Event 3'));
    });
  });
}
