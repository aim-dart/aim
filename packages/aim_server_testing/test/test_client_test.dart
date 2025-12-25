import 'package:aim_server/aim_server.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  group('TestClient', () {
    late Aim app;
    late TestClient client;

    setUp(() {
      app = Aim();
      client = TestClient(app);
    });

    test('GET request returns 200', () async {
      app.get('/hello', (c) async => c.text('Hello, World!'));

      final response = await client.get('/hello');

      expect(response.statusCode, equals(200));
      expect(await response.bodyAsString(), equals('Hello, World!'));
    });

    test('GET request with path parameter', () async {
      app.get('/users/:id', (c) async {
        final id = c.param('id');
        return c.json({'id': id, 'name': 'Alice'});
      });

      final response = await client.get('/users/123');

      expect(response, hasStatus(200));
      final json = await response.bodyAsJson();
      expect(json['id'], equals('123'));
      expect(json['name'], equals('Alice'));
    });

    test('POST request with JSON body', () async {
      app.post('/users', (c) async {
        final data = await c.req.json();
        return c.json(
          {'id': '1', 'name': data['name']},
          statusCode: 201,
        );
      });

      final response = await client.post(
        '/users',
        body: {'name': 'Bob'},
      );

      expect(response, hasStatus(201));
      expect(response, isSuccessful());

      final json = await response.bodyAsJson();
      expect(json['name'], equals('Bob'));
    });

    test('DELETE request returns 204', () async {
      app.delete('/users/:id', (c) async {
        return c.text('', statusCode: 204);
      });

      final response = await client.delete('/users/123');

      expect(response, hasStatus(204));
    });

    test('404 when route not found', () async {
      app.get('/existing', (c) async => c.text('OK'));

      final response = await client.get('/nonexistent');

      expect(response, hasStatus(404));
      expect(response, isClientError());
    });

    test('PUT request with JSON body', () async {
      app.put('/users/:id', (c) async {
        final id = c.param('id');
        final data = await c.req.json();
        return c.json({'id': id, 'name': data['name']});
      });

      final response = await client.put(
        '/users/123',
        body: {'name': 'Updated'},
      );

      expect(response, hasStatus(200));
      final json = await response.bodyAsJson();
      expect(json['id'], equals('123'));
      expect(json['name'], equals('Updated'));
    });

    test('PATCH request', () async {
      app.patch('/users/:id', (c) async {
        return c.json({'status': 'patched'});
      });

      final response = await client.patch('/users/123');

      expect(response, hasStatus(200));
    });

    test('HEAD request', () async {
      app.head('/status', (c) async {
        return c.text('', statusCode: 200);
      });

      final response = await client.head('/status');

      expect(response, hasStatus(200));
    });

    test('OPTIONS request', () async {
      app.options('/api', (c) async {
        c.header('Allow', 'GET, POST, OPTIONS');
        return c.text('', statusCode: 204);
      });

      final response = await client.options('/api');

      expect(response, hasStatus(204));
      expect(response.header('Allow'), equals('GET, POST, OPTIONS'));
    });

    test('custom headers', () async {
      app.get('/api', (c) async {
        final auth = c.headers['authorization'];
        if (auth == 'Bearer token123') {
          return c.json({'authenticated': true});
        }
        return c.json({'authenticated': false}, statusCode: 401);
      });

      final response = await client.get(
        '/api',
        headers: {'authorization': 'Bearer token123'},
      );

      expect(response, hasStatus(200));
      final json = await response.bodyAsJson();
      expect(json['authenticated'], equals(true));
    });

    test('query parameters', () async {
      app.get('/search', (c) async {
        final query = c.queryParam('q');
        final page = c.queryParam('page', '1');
        return c.json({'query': query, 'page': page});
      });

      final response = await client.get(
        '/search',
        query: {'q': 'test', 'page': '2'},
      );

      expect(response, hasStatus(200));
      final json = await response.bodyAsJson();
      expect(json['query'], equals('test'));
      expect(json['page'], equals('2'));
    });
  });
}
