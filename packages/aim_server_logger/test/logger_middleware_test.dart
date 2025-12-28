import 'package:aim_server/aim_server.dart';
import 'package:aim_server_logger/aim_server_logger.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  group('Logger Middleware', () {
    late Aim app;
    late TestClient client;

    setUp(() {
      app = Aim();
      client = TestClient(app);
    });

    test('カスタムonRequestコールバックが呼ばれる', () async {
      var requestCalled = false;
      String? capturedMethod;
      String? capturedPath;

      app.use(logger(
        onRequest: (c) async {
          requestCalled = true;
          capturedMethod = c.req.method;
          capturedPath = c.req.uri.path;
        },
      ));

      app.get('/test', (c) async => c.text('OK'));

      await client.get('/test');

      expect(requestCalled, isTrue);
      expect(capturedMethod, equals('GET'));
      expect(capturedPath, equals('/test'));
    });

    test('カスタムonResponseコールバックが呼ばれる', () async {
      var responseCalled = false;
      int? capturedStatusCode;
      int? capturedDuration;

      app.use(logger(
        onResponse: (c, durationMs) async {
          responseCalled = true;
          capturedStatusCode = c.response?.statusCode;
          capturedDuration = durationMs;
        },
      ));

      app.get('/test', (c) async => c.text('OK'));

      await client.get('/test');

      expect(responseCalled, isTrue);
      expect(capturedStatusCode, equals(200));
      expect(capturedDuration, greaterThanOrEqualTo(0));
    });

    test('onRequestとonResponseの両方が呼ばれる', () async {
      var requestCalled = false;
      var responseCalled = false;
      final executionOrder = <String>[];

      app.use(logger(
        onRequest: (c) async {
          requestCalled = true;
          executionOrder.add('request');
        },
        onResponse: (c, durationMs) async {
          responseCalled = true;
          executionOrder.add('response');
        },
      ));

      app.get('/test', (c) async {
        executionOrder.add('handler');
        return c.text('OK');
      });

      await client.get('/test');

      expect(requestCalled, isTrue);
      expect(responseCalled, isTrue);
      expect(executionOrder, equals(['request', 'handler', 'response']));
    });

    test('レスポンスのステータスコードが正しく取得できる', () async {
      int? capturedStatusCode;

      app.use(logger(
        onResponse: (c, durationMs) async {
          capturedStatusCode = c.response?.statusCode;
        },
      ));

      app.get('/created', (c) async => c.json({'id': 1}, statusCode: 201));

      final response = await client.get('/created');

      expect(response.statusCode, equals(201));
      expect(capturedStatusCode, equals(201));
    });

    test('処理時間が計測される', () async {
      int? capturedDuration;

      app.use(logger(
        onResponse: (c, durationMs) async {
          capturedDuration = durationMs;
        },
      ));

      app.get('/delay', (c) async {
        await Future.delayed(Duration(milliseconds: 10));
        return c.text('Delayed');
      });

      await client.get('/delay');

      expect(capturedDuration, isNotNull);
      expect(capturedDuration, greaterThanOrEqualTo(10));
    });

    test('複数のHTTPメソッドで動作する', () async {
      final requestMethods = <String>[];

      app.use(logger(
        onRequest: (c) async {
          requestMethods.add(c.req.method);
        },
      ));

      app.get('/resource', (c) async => c.text('GET'));
      app.post('/resource', (c) async => c.text('POST'));
      app.put('/resource', (c) async => c.text('PUT'));
      app.delete('/resource', (c) async => c.text('DELETE'));

      await client.get('/resource');
      await client.post('/resource');
      await client.put('/resource');
      await client.delete('/resource');

      expect(requestMethods, equals(['GET', 'POST', 'PUT', 'DELETE']));
    });

    test('パスパラメータを含むリクエストで動作する', () async {
      String? capturedPath;

      app.use(logger(
        onRequest: (c) async {
          capturedPath = c.req.uri.path;
        },
      ));

      app.get('/users/:id', (c) async {
        final id = c.param('id');
        return c.json({'id': id});
      });

      final response = await client.get('/users/123');

      expect(capturedPath, equals('/users/123'));
      final json = await response.bodyAsJson();
      expect(json['id'], equals('123'));
    });

    test('エラーレスポンスも正しくログできる', () async {
      int? capturedStatusCode;

      app.use(logger(
        onResponse: (c, durationMs) async {
          capturedStatusCode = c.response?.statusCode;
        },
      ));

      app.get('/error', (c) async {
        return c.json({'error': 'Not Found'}, statusCode: 404);
      });

      final response = await client.get('/error');

      expect(response.statusCode, equals(404));
      expect(capturedStatusCode, equals(404));
    });

    test('デフォルト動作（コールバックなし）でもエラーにならない', () async {
      app.use(logger());
      app.get('/test', (c) async => c.text('OK'));

      final response = await client.get('/test');

      expect(response.statusCode, equals(200));
    });

    test('onRequestのみ指定してもonResponseはデフォルト動作する', () async {
      var requestCalled = false;

      app.use(logger(
        onRequest: (c) async {
          requestCalled = true;
        },
      ));

      app.get('/test', (c) async => c.text('OK'));

      final response = await client.get('/test');

      expect(requestCalled, isTrue);
      expect(response.statusCode, equals(200));
    });

    test('onResponseのみ指定してもonRequestはデフォルト動作する', () async {
      var responseCalled = false;

      app.use(logger(
        onResponse: (c, durationMs) async {
          responseCalled = true;
        },
      ));

      app.get('/test', (c) async => c.text('OK'));

      final response = await client.get('/test');

      expect(responseCalled, isTrue);
      expect(response.statusCode, equals(200));
    });
  });
}