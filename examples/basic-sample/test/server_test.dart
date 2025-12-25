import 'package:aim_server/aim_server.dart';
import 'package:aim_server_cors/aim_server_cors.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  late Aim app;
  late TestClient client;
  late Map<String, Map<String, dynamic>> users;

  setUp(() {
    // Create the same app as in bin/main.dart
    app = Aim();
    users = <String, Map<String, dynamic>>{};

    // Middleware
    app.use(cors());

    // Simple routes
    app.get('/', (c) async {
      return c.json({'message': 'Hello, Aim Framework!'});
    });

    app.get('/ping', (c) async {
      return c.text('pong');
    });

    // User CRUD routes
    app.post('/users', (c) async {
      final data = await c.req.json();
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      users[id] = {'id': id, ...data};
      return c.json(users[id]!, statusCode: 201);
    });

    app.get('/users/:id', (c) async {
      final id = c.param('id');
      final user = users[id];
      if (user == null) {
        return c.json({'error': 'User not found'}, statusCode: 404);
      }
      return c.json(user);
    });

    app.put('/users/:id', (c) async {
      final id = c.param('id');
      if (!users.containsKey(id)) {
        return c.json({'error': 'User not found'}, statusCode: 404);
      }
      final data = await c.req.json();
      users[id] = {'id': id, ...data};
      return c.json(users[id]!);
    });

    app.patch('/users/:id', (c) async {
      final id = c.param('id');
      final user = users[id];
      if (user == null) {
        return c.json({'error': 'User not found'}, statusCode: 404);
      }
      final data = await c.req.json();
      users[id] = {...user, ...data};
      return c.json(users[id]!);
    });

    app.delete('/users/:id', (c) async {
      final id = c.param('id');
      if (!users.containsKey(id)) {
        return c.json({'error': 'User not found'}, statusCode: 404);
      }
      users.remove(id);
      return c.text('', statusCode: 204);
    });

    // Search with query parameters
    app.get('/search', (c) async {
      final query = c.req.queryParameters['q'];
      final limit = c.req.queryParameters['limit'] ?? '10';
      return c.json({'query': query, 'limit': int.parse(limit), 'results': []});
    });

    client = TestClient(app);
  });

  group('Basic Routes Tests', () {
    test('GET / returns welcome message', () async {
      final response = await client.get('/');

      expect(response, hasStatus(200));
      expect(response, isSuccessful());
      expect(response, hasHeader('content-type', 'application/json'));

      final json = await response.bodyAsJson();
      expect(json['message'], equals('Hello, Aim Framework!'));
    });

    test('GET /ping returns pong', () async {
      final response = await client.get('/ping');

      expect(response, hasStatus(200));
      expect(response, isSuccessful());

      final body = await response.bodyAsString();
      expect(body, equals('pong'));
    });

    test('GET /nonexistent returns 404', () async {
      final response = await client.get('/nonexistent');

      expect(response, hasStatus(404));
      expect(response, isClientError());
      expect(response.isClientError, isTrue);
    });
  });

  group('User CRUD Tests', () {
    test('POST /users creates a new user', () async {
      final response = await client.post(
        '/users',
        body: {'name': 'Alice', 'email': 'alice@example.com'},
      );

      expect(response, hasStatus(201));
      expect(response, isSuccessful());

      final json = await response.bodyAsJson();
      expect(json['name'], equals('Alice'));
      expect(json['email'], equals('alice@example.com'));
      expect(json['id'], isNotNull);
    });

    test('GET /users/:id returns user data', () async {
      // Create a user first
      users['123'] = {'id': '123', 'name': 'Bob', 'email': 'bob@example.com'};

      final response = await client.get('/users/123');

      expect(response, hasStatus(200));
      expect(response, isSuccessful());

      final json = await response.bodyAsJson();
      expect(json['id'], equals('123'));
      expect(json['name'], equals('Bob'));
      expect(json['email'], equals('bob@example.com'));
    });

    test('GET /users/:id returns 404 for non-existent user', () async {
      final response = await client.get('/users/999');

      expect(response, hasStatus(404));
      expect(response, isClientError());

      final json = await response.bodyAsJson();
      expect(json['error'], equals('User not found'));
    });

    test('PUT /users/:id updates entire user', () async {
      // Create a user first
      users['123'] = {
        'id': '123',
        'name': 'Charlie',
        'email': 'charlie@example.com',
      };

      final response = await client.put(
        '/users/123',
        body: {'name': 'Charlie Updated', 'email': 'charlie.new@example.com'},
      );

      expect(response, hasStatus(200));
      expect(response, isSuccessful());

      final json = await response.bodyAsJson();
      expect(json['id'], equals('123'));
      expect(json['name'], equals('Charlie Updated'));
      expect(json['email'], equals('charlie.new@example.com'));
    });

    test('PUT /users/:id returns 404 for non-existent user', () async {
      final response = await client.put('/users/999', body: {'name': 'Nobody'});

      expect(response, hasStatus(404));
      expect(response, isClientError());
    });

    test('PATCH /users/:id partially updates user', () async {
      // Create a user first
      users['123'] = {'id': '123', 'name': 'Dave', 'email': 'dave@example.com'};

      final response = await client.patch(
        '/users/123',
        body: {'name': 'Dave Updated'},
      );

      expect(response, hasStatus(200));
      expect(response, isSuccessful());

      final json = await response.bodyAsJson();
      expect(json['id'], equals('123'));
      expect(json['name'], equals('Dave Updated'));
      expect(json['email'], equals('dave@example.com')); // Email unchanged
    });

    test('PATCH /users/:id returns 404 for non-existent user', () async {
      final response = await client.patch(
        '/users/999',
        body: {'name': 'Nobody'},
      );

      expect(response, hasStatus(404));
      expect(response, isClientError());
    });

    test('DELETE /users/:id removes user', () async {
      // Create a user first
      users['123'] = {'id': '123', 'name': 'Eve'};

      final response = await client.delete('/users/123');

      expect(response, hasStatus(204));
      expect(response, isSuccessful());

      final body = await response.bodyAsString();
      expect(body, isEmpty);

      // Verify user was deleted
      expect(users.containsKey('123'), isFalse);
    });

    test('DELETE /users/:id returns 404 for non-existent user', () async {
      final response = await client.delete('/users/999');

      expect(response, hasStatus(404));
      expect(response, isClientError());
    });
  });

  group('Query Parameters Tests', () {
    test('GET /search handles query parameters', () async {
      final response = await client.get(
        '/search',
        query: {'q': 'test query', 'limit': '20'},
      );

      expect(response, hasStatus(200));
      expect(response, isSuccessful());

      final json = await response.bodyAsJson();
      expect(json['query'], equals('test query'));
      expect(json['limit'], equals(20));
      expect(json['results'], isEmpty);
    });

    test('GET /search uses default limit when not specified', () async {
      final response = await client.get('/search', query: {'q': 'test'});

      expect(response, hasStatus(200));

      final json = await response.bodyAsJson();
      expect(json['limit'], equals(10)); // Default value
    });
  });

  group('HTTP Methods Tests', () {
    test('OPTIONS / handles CORS preflight', () async {
      final response = await client.options(
        '/',
        headers: {
          'Origin': 'http://example.com',
          'Access-Control-Request-Method': 'GET',
        },
      );

      // CORS middleware handles OPTIONS requests
      expect(response.statusCode, lessThanOrEqualTo(204));
    });
  });

  group('CORS Tests', () {
    test('CORS headers are present with Origin header', () async {
      final response = await client.get(
        '/',
        headers: {'Origin': 'http://example.com'},
      );

      expect(response, hasStatus(200));
      expect(response.header('access-control-allow-origin'), equals('*'));
    });

    test('POST /users includes CORS headers', () async {
      final response = await client.post(
        '/users',
        headers: {'Origin': 'http://example.com'},
        body: {'name': 'CORS Test'},
      );

      expect(response, hasStatus(201));
      expect(response.header('access-control-allow-origin'), equals('*'));
    });
  });

  group('Custom Headers Tests', () {
    test('Custom request headers are processed', () async {
      final response = await client.get(
        '/',
        headers: {
          'X-Custom-Header': 'custom-value',
          'User-Agent': 'TestClient/1.0',
        },
      );

      expect(response, hasStatus(200));
      expect(response, isSuccessful());
    });
  });

  group('Response Format Tests', () {
    test('JSON responses have correct content-type', () async {
      final response = await client.get('/');

      expect(response.header('content-type'), contains('application/json'));

      final json = await response.bodyAsJson();
      expect(json, isA<Map<String, dynamic>>());
    });

    test('Text responses have correct content-type', () async {
      final response = await client.get('/ping');

      expect(response.header('content-type'), contains('text/plain'));
    });
  });

  group('TestResponse Helper Methods Tests', () {
    test('isSuccessful property works correctly', () async {
      final successResponse = await client.get('/');
      expect(successResponse.isSuccessful, isTrue);

      final notFoundResponse = await client.get('/nonexistent');
      expect(notFoundResponse.isSuccessful, isFalse);
    });

    test('isClientError property works correctly', () async {
      final clientErrorResponse = await client.get('/nonexistent');
      expect(clientErrorResponse.isClientError, isTrue);

      final successResponse = await client.get('/');
      expect(successResponse.isClientError, isFalse);
    });

    test('header method retrieves specific headers', () async {
      final response = await client.get('/');

      final contentType = response.header('content-type');
      expect(contentType, isNotNull);
      expect(contentType, contains('application/json'));
    });

    test('bodyAsString converts response body to string', () async {
      final response = await client.get('/ping');

      final body = await response.bodyAsString();
      expect(body, isA<String>());
      expect(body, equals('pong'));
    });

    test('bodyAsJson parses JSON response', () async {
      final response = await client.get('/');

      final json = await response.bodyAsJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json.containsKey('message'), isTrue);
    });
  });

  group('Integration Tests', () {
    test('Complete user lifecycle: create, read, update, delete', () async {
      // Create
      final createResponse = await client.post(
        '/users',
        body: {
          'name': 'Integration Test User',
          'email': 'integration@example.com',
        },
      );
      expect(createResponse, hasStatus(201));
      final createdUser = await createResponse.bodyAsJson();
      final userId = createdUser['id'] as String;

      // Read
      final readResponse = await client.get('/users/$userId');
      expect(readResponse, hasStatus(200));
      final readUser = await readResponse.bodyAsJson();
      expect(readUser['name'], equals('Integration Test User'));

      // Update
      final updateResponse = await client.put(
        '/users/$userId',
        body: {'name': 'Updated User', 'email': 'updated@example.com'},
      );
      expect(updateResponse, hasStatus(200));
      final updatedUser = await updateResponse.bodyAsJson();
      expect(updatedUser['name'], equals('Updated User'));

      // Partial Update
      final patchResponse = await client.patch(
        '/users/$userId',
        body: {'name': 'Patched User'},
      );
      expect(patchResponse, hasStatus(200));
      final patchedUser = await patchResponse.bodyAsJson();
      expect(patchedUser['name'], equals('Patched User'));
      expect(patchedUser['email'], equals('updated@example.com'));

      // Delete
      final deleteResponse = await client.delete('/users/$userId');
      expect(deleteResponse, hasStatus(204));

      // Verify deletion
      final verifyResponse = await client.get('/users/$userId');
      expect(verifyResponse, hasStatus(404));
    });
  });
}
