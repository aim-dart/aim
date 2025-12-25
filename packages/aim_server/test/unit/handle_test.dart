import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Aim.handle()', () {
    test('handles GET request and returns response', () async {
      final app = Aim();
      app.get('/hello', (c) async => c.text('Hello'));

      final request = Request('GET', Uri.parse('http://localhost/hello'));
      final response = await app.handle(request);

      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      expect(body, equals('Hello'));
    });

    test('handles path parameters', () async {
      final app = Aim();
      app.get('/users/:id', (c) async => c.json({'id': c.param('id')}));

      final request = Request('GET', Uri.parse('http://localhost/users/123'));
      final response = await app.handle(request);

      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      expect(body, contains('"id":"123"'));
    });

    test('executes middleware chain', () async {
      final app = Aim();
      final executed = <String>[];

      app.use((c, next) async {
        executed.add('middleware');
        await next();
      });

      app.get('/test', (c) async {
        executed.add('handler');
        return c.text('OK');
      });

      final request = Request('GET', Uri.parse('http://localhost/test'));
      await app.handle(request);

      expect(executed, equals(['middleware', 'handler']));
    });

    test('handles errors with error handler', () async {
      final app = Aim();
      app.onError((e, c) async => c.json({'error': e.toString()}, statusCode: 500));
      app.get('/error', (c) async => throw Exception('Test error'));

      final request = Request('GET', Uri.parse('http://localhost/error'));
      final response = await app.handle(request);

      expect(response.statusCode, equals(500));
      final body = await response.readAsString();
      expect(body, contains('Test error'));
    });

    test('returns 404 for non-matching routes', () async {
      final app = Aim();
      app.get('/exists', (c) async => c.text('OK'));

      final request = Request('GET', Uri.parse('http://localhost/notfound'));
      final response = await app.handle(request);

      expect(response.statusCode, equals(404));
      final body = await response.readAsString();
      expect(body, equals('Not Found'));
    });

    test('handles POST request with JSON body', () async {
      final app = Aim();
      app.post('/data', (c) async {
        final data = await c.req.json();
        return c.json({'received': data['value']});
      });

      final request = Request(
        'POST',
        Uri.parse('http://localhost/data'),
        bodyContent: '{"value":"test"}',
        headers: {'content-type': 'application/json'},
      );
      final response = await app.handle(request);

      expect(response.statusCode, equals(200));
      final body = await response.readAsString();
      expect(body, contains('"received":"test"'));
    });

    test('middleware can modify context', () async {
      final app = Aim();

      app.use((c, next) async {
        c.set('user', 'Alice');
        await next();
      });

      app.get('/user', (c) async {
        final user = c.get<String>('user');
        return c.text('User: $user');
      });

      final request = Request('GET', Uri.parse('http://localhost/user'));
      final response = await app.handle(request);

      final body = await response.readAsString();
      expect(body, equals('User: Alice'));
    });

    test('custom 404 handler is used', () async {
      final app = Aim();
      app.notFound((c) async => c.json({'error': 'Custom not found'}, statusCode: 404));

      final request = Request('GET', Uri.parse('http://localhost/nowhere'));
      final response = await app.handle(request);

      expect(response.statusCode, equals(404));
      final body = await response.readAsString();
      expect(body, contains('Custom not found'));
    });

    test('handles different HTTP methods', () async {
      final app = Aim();
      app.get('/resource', (c) async => c.text('GET'));
      app.post('/resource', (c) async => c.text('POST'));
      app.put('/resource', (c) async => c.text('PUT'));
      app.delete('/resource', (c) async => c.text('DELETE'));

      final getResponse = await app.handle(
        Request('GET', Uri.parse('http://localhost/resource')),
      );
      expect(await getResponse.readAsString(), equals('GET'));

      final postResponse = await app.handle(
        Request('POST', Uri.parse('http://localhost/resource')),
      );
      expect(await postResponse.readAsString(), equals('POST'));

      final putResponse = await app.handle(
        Request('PUT', Uri.parse('http://localhost/resource')),
      );
      expect(await putResponse.readAsString(), equals('PUT'));

      final deleteResponse = await app.handle(
        Request('DELETE', Uri.parse('http://localhost/resource')),
      );
      expect(await deleteResponse.readAsString(), equals('DELETE'));
    });
  });
}
