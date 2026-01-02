import 'dart:convert';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_basic_auth/aim_server_basic_auth.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  group('basicAuth middleware', () {
    late Aim<BasicAuthEnv> app;
    late TestClient client;
    late BasicAuthOptions options;

    setUp(() {
      options = BasicAuthOptions(
        realm: 'Test Realm',
        verify: (username, password) async {
          return username == 'admin' && password == 'secret123';
        },
      );

      app = Aim<BasicAuthEnv>(
        envFactory: () => BasicAuthEnv(options: options),
      );
      client = TestClient(app);

      app.use(basicAuth());

      app.get('/protected', (c) async {
        return c.json({
          'message': 'Protected resource',
          'username': c.variables.username,
        });
      });
    });

    group('Authentication failures', () {
      test('Should return 401 when Authorization header is missing', () async {
        final response = await client.get('/protected');

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
        final body = await response.bodyAsJson();
        expect(body['error'], equals('Unauthorized'));
      });

      test('Should return 401 when Authorization header is not Basic',
          () async {
        final response = await client.get(
          '/protected',
          headers: {'authorization': 'Bearer some-token'},
        );

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
        final body = await response.bodyAsJson();
        expect(body['error'], equals('Unauthorized'));
      });

      test('Should return 401 when Base64 encoding is invalid', () async {
        final response = await client.get(
          '/protected',
          headers: {'authorization': 'Basic invalid!!!base64'},
        );

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
        final body = await response.bodyAsJson();
        expect(body['error'], equals('Unauthorized'));
      });

      test('Should return 401 when credentials do not contain colon',
          () async {
        final credentials = base64Encode(utf8.encode('adminonly'));
        final response = await client.get(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
        final body = await response.bodyAsJson();
        expect(body['error'], equals('Unauthorized'));
      });

      test('Should return 401 when credentials are incorrect', () async {
        final credentials = base64Encode(utf8.encode('admin:wrongpassword'));
        final response = await client.get(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
        final body = await response.bodyAsJson();
        expect(body['error'], equals('Unauthorized'));
      });

      test('Should return 401 when username is incorrect', () async {
        final credentials = base64Encode(utf8.encode('wronguser:secret123'));
        final response = await client.get(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
        final body = await response.bodyAsJson();
        expect(body['error'], equals('Unauthorized'));
      });

      test('Should return 401 with extra whitespace after Basic', () async {
        final credentials = base64Encode(utf8.encode('admin:secret123'));
        final response = await client.get(
          '/protected',
          headers: {'authorization': 'Basic  $credentials'}, // Extra space
        );

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
      });
    });

    group('Authentication success', () {
      test('Should authenticate with correct credentials', () async {
        final credentials = base64Encode(utf8.encode('admin:secret123'));
        final response = await client.get(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(200));
        final body = await response.bodyAsJson();
        expect(body['message'], equals('Protected resource'));
        expect(body['username'], equals('admin'));
      });

      test('Should set username in context variables', () async {
        final credentials = base64Encode(utf8.encode('admin:secret123'));
        String? capturedUsername;

        app.get('/capture', (c) async {
          capturedUsername = c.variables.username;
          return c.text('OK');
        });

        final appClient = TestClient(app);
        await appClient.get(
          '/capture',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(capturedUsername, equals('admin'));
      });

      test('Should support password containing colons', () async {
        final appWithColon = Aim<BasicAuthEnv>(
          envFactory: () => BasicAuthEnv(
            options: BasicAuthOptions(
              realm: 'Test',
              verify: (username, password) async {
                return username == 'user' && password == 'pass:with:colons';
              },
            ),
          ),
        );

        appWithColon.use(basicAuth());
        appWithColon.get('/test', (c) async => c.text('OK'));

        final colonClient = TestClient(appWithColon);
        final credentials = base64Encode(utf8.encode('user:pass:with:colons'));
        final response = await colonClient.get(
          '/test',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(200));
      });

      test('Should support empty password', () async {
        final appWithEmptyPass = Aim<BasicAuthEnv>(
          envFactory: () => BasicAuthEnv(
            options: BasicAuthOptions(
              realm: 'Test',
              verify: (username, password) async {
                return username == 'user' && password == '';
              },
            ),
          ),
        );

        appWithEmptyPass.use(basicAuth());
        appWithEmptyPass.get('/test', (c) async => c.text('OK'));

        final emptyPassClient = TestClient(appWithEmptyPass);
        final credentials = base64Encode(utf8.encode('user:'));
        final response = await emptyPassClient.get(
          '/test',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(200));
      });

      test('Should support non-ASCII characters in credentials', () async {
        final appWithUnicode = Aim<BasicAuthEnv>(
          envFactory: () => BasicAuthEnv(
            options: BasicAuthOptions(
              realm: 'Test',
              verify: (username, password) async {
                return username == 'ユーザー' && password == 'パスワード';
              },
            ),
          ),
        );

        appWithUnicode.use(basicAuth());
        appWithUnicode.get('/test', (c) async => c.text('OK'));

        final unicodeClient = TestClient(appWithUnicode);
        final credentials =
            base64Encode(utf8.encode('ユーザー:パスワード'));
        final response = await unicodeClient.get(
          '/test',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(200));
      });
    });

    group('excludedPaths', () {
      late Aim<BasicAuthEnv> appWithExclusions;
      late TestClient exclusionsClient;

      setUp(() {
        appWithExclusions = Aim<BasicAuthEnv>(
          envFactory: () => BasicAuthEnv(
            options: BasicAuthOptions(
              realm: 'Test Realm',
              verify: (username, password) async {
                return username == 'admin' && password == 'secret123';
              },
              excludedPaths: ['/login', '/public', '/health'],
            ),
          ),
        );

        appWithExclusions.use(basicAuth());

        appWithExclusions.get('/login', (c) async {
          return c.json({'page': 'login'});
        });

        appWithExclusions.get('/public', (c) async {
          return c.json({'page': 'public'});
        });

        appWithExclusions.get('/protected', (c) async {
          return c.json({'page': 'protected'});
        });

        exclusionsClient = TestClient(appWithExclusions);
      });

      test('Should skip authentication for excluded paths', () async {
        final response = await exclusionsClient.get('/login');

        expect(response.statusCode, equals(200));
        final body = await response.bodyAsJson();
        expect(body['page'], equals('login'));
      });

      test('Should require authentication for non-excluded paths', () async {
        final response = await exclusionsClient.get('/protected');

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Test Realm"'),
        );
      });

      test('Should not set username on excluded paths', () async {
        String? capturedUsername;

        appWithExclusions.get('/health', (c) async {
          capturedUsername = c.variables.username;
          return c.text('OK');
        });

        final healthClient = TestClient(appWithExclusions);
        await healthClient.get('/health');

        expect(capturedUsername, isNull);
      });
    });

    group('HTTP methods', () {
      setUp(() {
        app.post('/protected', (c) async {
          return c.json({'method': 'POST', 'username': c.variables.username});
        });

        app.put('/protected', (c) async {
          return c.json({'method': 'PUT', 'username': c.variables.username});
        });

        app.delete('/protected', (c) async {
          return c.json({
            'method': 'DELETE',
            'username': c.variables.username,
          });
        });
      });

      test('Should authenticate POST requests', () async {
        final credentials = base64Encode(utf8.encode('admin:secret123'));
        final response = await client.post(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(200));
        final body = await response.bodyAsJson();
        expect(body['method'], equals('POST'));
        expect(body['username'], equals('admin'));
      });

      test('Should authenticate PUT requests', () async {
        final credentials = base64Encode(utf8.encode('admin:secret123'));
        final response = await client.put(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(200));
        final body = await response.bodyAsJson();
        expect(body['method'], equals('PUT'));
        expect(body['username'], equals('admin'));
      });

      test('Should authenticate DELETE requests', () async {
        final credentials = base64Encode(utf8.encode('admin:secret123'));
        final response = await client.delete(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(response.statusCode, equals(200));
        final body = await response.bodyAsJson();
        expect(body['method'], equals('DELETE'));
        expect(body['username'], equals('admin'));
      });
    });

    group('Realm configuration', () {
      test('Should use custom realm in WWW-Authenticate header', () async {
        final customApp = Aim<BasicAuthEnv>(
          envFactory: () => BasicAuthEnv(
            options: BasicAuthOptions(
              realm: 'Custom Admin Area',
              verify: (username, password) async => false,
            ),
          ),
        );

        customApp.use(basicAuth());
        customApp.get('/test', (c) async => c.text('OK'));

        final customClient = TestClient(customApp);
        final response = await customClient.get('/test');

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Custom Admin Area"'),
        );
      });

      test('Should use default realm when not specified', () async {
        final defaultApp = Aim<BasicAuthEnv>(
          envFactory: () => BasicAuthEnv(
            options: BasicAuthOptions(
              verify: (username, password) async => false,
            ),
          ),
        );

        defaultApp.use(basicAuth());
        defaultApp.get('/test', (c) async => c.text('OK'));

        final defaultClient = TestClient(defaultApp);
        final response = await defaultClient.get('/test');

        expect(response.statusCode, equals(401));
        expect(
          response.headers['WWW-Authenticate'],
          equals('Basic realm="Restricted Area"'),
        );
      });
    });

    group('Middleware chain', () {
      test('Should call next middleware after successful authentication',
          () async {
        var middlewareCalled = false;

        app.use((c, next) async {
          middlewareCalled = true;
          return next();
        });

        final credentials = base64Encode(utf8.encode('admin:secret123'));
        final chainClient = TestClient(app);
        await chainClient.get(
          '/protected',
          headers: {'authorization': 'Basic $credentials'},
        );

        expect(middlewareCalled, isTrue);
      });

      test('Should not call next middleware on authentication failure',
          () async {
        var middlewareCalled = false;

        app.use((c, next) async {
          middlewareCalled = true;
          return next();
        });

        final failClient = TestClient(app);
        await failClient.get('/protected');

        expect(middlewareCalled, isFalse);
      });
    });
  });
}
