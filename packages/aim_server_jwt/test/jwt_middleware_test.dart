import 'package:aim_server/aim_server.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  group('JWT Middleware', () {
    late Aim<JwtEnv> app;
    late TestClient client;
    late JwtOptions jwtOptions;
    late String validToken;

    setUp(() {
      jwtOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        excludedPaths: ['/login', '/public'],
      );

      app = Aim<JwtEnv>(
        envFactory: () => JwtEnv.create(jwtOptions),
      );
      client = TestClient(app);

      // Generate valid token
      final jwt = Jwt(options: jwtOptions);
      validToken = jwt.sign({'user_id': 1, 'role': 'admin'});
    });

    test('Should return 401 when Authorization header is missing', () async {
      app.use(jwt());
      app.get('/protected', (c) async => c.text('Secret'));

      final response = await client.get('/protected');

      expect(response.statusCode, equals(401));
      final json = await response.bodyAsJson();
      expect(json['error'], equals('Unauthorized'));
    });

    test('Should return 401 when Authorization header is not Bearer format',
        () async {
      app.use(jwt());
      app.get('/protected', (c) async => c.text('Secret'));

      final response = await client.get(
        '/protected',
        headers: {'authorization': 'Basic abcdefg'},
      );

      expect(response.statusCode, equals(401));
      final json = await response.bodyAsJson();
      expect(json['error'], equals('Unauthorized'));
    });

    test('Should access protected route with valid token', () async {
      app.use(jwt());
      app.get('/protected', (c) async {
        final payload = c.variables.jwtPayload;
        return c.json({
          'message': 'Success',
          'user_id': payload['user_id'],
          'role': payload['role'],
        });
      });

      final response = await client.get(
        '/protected',
        headers: {'authorization': 'Bearer $validToken'},
      );

      expect(response.statusCode, equals(200));
      final json = await response.bodyAsJson();
      expect(json['message'], equals('Success'));
      expect(json['user_id'], equals(1));
      expect(json['role'], equals('admin'));
    });

    test('Should return 401 with invalid signature', () async {
      app.use(jwt());
      app.get('/protected', (c) async => c.text('Secret'));

      final response = await client.get(
        '/protected',
        headers: {'authorization': 'Bearer invalid.token.signature'},
      );

      expect(response.statusCode, equals(401));
      final json = await response.bodyAsJson();
      expect(json['error'], equals('Invalid token'));
    });

    test('Should return 401 with expired token', () async {
      // Generate token with 1ms expiration
      final expiredOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        expiration: Duration(milliseconds: 1),
      );
      final expiredJwt = Jwt(options: expiredOptions);
      final expiredToken = expiredJwt.sign({'user_id': 1});

      // Wait for token to expire
      await Future.delayed(Duration(milliseconds: 10));

      app.use(jwt());
      app.get('/protected', (c) async => c.text('Secret'));

      final response = await client.get(
        '/protected',
        headers: {'authorization': 'Bearer $expiredToken'},
      );

      expect(response.statusCode, equals(401));
      final json = await response.bodyAsJson();
      expect(json['error'], equals('Invalid token'));
    });

    test('Should skip authentication for excluded paths', () async {
      app.use(jwt());
      app.get('/login', (c) async => c.text('Login page'));
      app.get('/public', (c) async => c.text('Public page'));

      // Access without Authorization header
      final loginResponse = await client.get('/login');
      expect(loginResponse.statusCode, equals(200));
      expect(await loginResponse.bodyAsString(), equals('Login page'));

      final publicResponse = await client.get('/public');
      expect(publicResponse.statusCode, equals(200));
      expect(await publicResponse.bodyAsString(), equals('Public page'));
    });

    test('Should require authentication for non-excluded paths', () async {
      app.use(jwt());
      app.get('/protected', (c) async => c.text('Secret'));

      // Access without Authorization header
      final response = await client.get('/protected');
      expect(response.statusCode, equals(401));
    });

    test('Should work correctly with multiple HTTP methods', () async {
      app.use(jwt());
      app.get('/resource', (c) async => c.text('GET'));
      app.post('/resource', (c) async => c.text('POST'));
      app.put('/resource', (c) async => c.text('PUT'));
      app.delete('/resource', (c) async => c.text('DELETE'));

      final headers = {'authorization': 'Bearer $validToken'};

      final getResponse = await client.get('/resource', headers: headers);
      expect(getResponse.statusCode, equals(200));
      expect(await getResponse.bodyAsString(), equals('GET'));

      final postResponse = await client.post('/resource', headers: headers);
      expect(postResponse.statusCode, equals(200));
      expect(await postResponse.bodyAsString(), equals('POST'));

      final putResponse = await client.put('/resource', headers: headers);
      expect(putResponse.statusCode, equals(200));
      expect(await putResponse.bodyAsString(), equals('PUT'));

      final deleteResponse = await client.delete('/resource', headers: headers);
      expect(deleteResponse.statusCode, equals(200));
      expect(await deleteResponse.bodyAsString(), equals('DELETE'));
    });

    test('Should set payload correctly in context', () async {
      // Generate token with custom payload
      final customJwt = Jwt(options: jwtOptions);
      final customToken = customJwt.sign({
        'user_id': 123,
        'username': 'alice',
        'permissions': ['read', 'write', 'delete'],
      });

      app.use(jwt());
      app.get('/user-info', (c) async {
        final payload = c.variables.jwtPayload;
        return c.json({
          'user_id': payload['user_id'],
          'username': payload['username'],
          'permissions': payload['permissions'],
        });
      });

      final response = await client.get(
        '/user-info',
        headers: {'authorization': 'Bearer $customToken'},
      );

      expect(response.statusCode, equals(200));
      final json = await response.bodyAsJson();
      expect(json['user_id'], equals(123));
      expect(json['username'], equals('alice'));
      expect(json['permissions'], equals(['read', 'write', 'delete']));
    });

    test('Should return 401 when extra whitespace after Bearer', () async {
      app.use(jwt());
      app.get('/protected', (c) async => c.text('Success'));

      final response = await client.get(
        '/protected',
        headers: {'authorization': 'Bearer  $validToken'}, // Extra whitespace
      );

      // RFC 6750 specifies only one space between "Bearer" and "token"
      expect(response.statusCode, equals(401));
    });

    test('Should work correctly in middleware chain', () async {
      final executionOrder = <String>[];

      app.use((c, next) async {
        executionOrder.add('middleware1');
        await next();
      });

      app.use(jwt());

      app.use((c, next) async {
        executionOrder.add('middleware2');
        await next();
      });

      app.get('/protected', (c) async {
        executionOrder.add('handler');
        return c.text('Success');
      });

      final response = await client.get(
        '/protected',
        headers: {'authorization': 'Bearer $validToken'},
      );

      expect(response.statusCode, equals(200));
      expect(
        executionOrder,
        equals(['middleware1', 'middleware2', 'handler']),
      );
    });

    test('Should not execute subsequent middleware on authentication failure',
        () async {
      final executionOrder = <String>[];

      app.use(jwt());

      app.use((c, next) async {
        executionOrder.add('should-not-execute');
        await next();
      });

      app.get('/protected', (c) async {
        executionOrder.add('handler');
        return c.text('Success');
      });

      final response = await client.get('/protected'); // No token

      expect(response.statusCode, equals(401));
      expect(executionOrder, isEmpty);
    });

    test('Should work with path parameters', () async {
      app.use(jwt());
      app.get('/users/:id', (c) async {
        final id = c.param('id');
        final payload = c.variables.jwtPayload;
        return c.json({
          'user_id': id,
          'authenticated_as': payload['user_id'],
        });
      });

      final response = await client.get(
        '/users/42',
        headers: {'authorization': 'Bearer $validToken'},
      );

      expect(response.statusCode, equals(200));
      final json = await response.bodyAsJson();
      expect(json['user_id'], equals('42'));
      expect(json['authenticated_as'], equals(1));
    });

    test('Should work with query parameters', () async {
      app.use(jwt());
      app.get('/search', (c) async {
        final query = c.req.uri.queryParameters['q'];
        final payload = c.variables.jwtPayload;
        return c.json({
          'query': query,
          'user_id': payload['user_id'],
        });
      });

      final response = await client.get(
        '/search?q=test',
        headers: {'authorization': 'Bearer $validToken'},
      );

      expect(response.statusCode, equals(200));
      final json = await response.bodyAsJson();
      expect(json['query'], equals('test'));
      expect(json['user_id'], equals(1));
    });

    test('Should verify correctly when issuer is set', () async {
      final issuerOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        issuer: 'test-issuer',
      );

      final issuerApp = Aim<JwtEnv>(
        envFactory: () => JwtEnv.create(issuerOptions),
      );
      final issuerClient = TestClient(issuerApp);

      final issuerJwt = Jwt(options: issuerOptions);
      final issuerToken = issuerJwt.sign({'user_id': 1});

      issuerApp.use(jwt());
      issuerApp.get('/protected', (c) async => c.text('Success'));

      final response = await issuerClient.get(
        '/protected',
        headers: {'authorization': 'Bearer $issuerToken'},
      );

      expect(response.statusCode, equals(200));
    });

    test('Should verify correctly when audience is set', () async {
      final audienceOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        audience: 'api.example.com',
      );

      final audienceApp = Aim<JwtEnv>(
        envFactory: () => JwtEnv.create(audienceOptions),
      );
      final audienceClient = TestClient(audienceApp);

      final audienceJwt = Jwt(options: audienceOptions);
      final audienceToken = audienceJwt.sign({'user_id': 1});

      audienceApp.use(jwt());
      audienceApp.get('/protected', (c) async => c.text('Success'));

      final response = await audienceClient.get(
        '/protected',
        headers: {'authorization': 'Bearer $audienceToken'},
      );

      expect(response.statusCode, equals(200));
    });
  });
}
