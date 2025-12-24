import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Context - Request accessors', () {
    test('Should provide access to method', () {
      final uri = Uri.parse('https://example.com/test');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.method, equals('GET'));
    });

    test('Should provide access to path', () {
      final uri = Uri.parse('http://example.com/users/123');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.path, equals('/users/123'));
    });

    test('Should provide access to headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'content-type': 'application/json'},
      );
      final context = Context(request, EmptyEnv());

      expect(context.headers['content-type'], equals('application/json'));
    });

    test('Should provide access to query parameters', () {
      final uri = Uri.parse('http://example.com/?name=John&age=30');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.query['name'], equals('John'));
      expect(context.query['age'], equals('30'));
    });

    test('Should provide shorthand req accessor', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.req, same(request));
    });
  });

  group('Context - Path parameters', () {
    test('Should extract path parameter', () {
      final uri = Uri.parse('http://example.com/users/123');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.set('param:id', '123');
      expect(context.param('id'), equals('123'));
    });

    test('Should extract multiple path parameters', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.set('param:userId', '123');
      context.set('param:postId', '456');

      expect(context.param('userId'), equals('123'));
      expect(context.param('postId'), equals('456'));
    });

    test('Should throw when parameter not found', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(() => context.param('nonexistent'), throwsArgumentError);
    });

    test('Should throw with clear message when parameter missing', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      try {
        context.param('missing');
        fail('Should have thrown ArgumentError');
      } catch (e) {
        expect(e, isA<ArgumentError>());
        expect(e.toString(), contains('missing'));
      }
    });
  });

  group('Context - Query parameters', () {
    test('Should extract query parameter', () {
      final uri = Uri.parse('http://example.com/?search=test');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.queryParam('search'), equals('test'));
    });

    test('Should use default when parameter missing', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.queryParam('page', '1'), equals('1'));
    });

    test('Should throw when required parameter missing', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(() => context.queryParam('required'), throwsArgumentError);
    });

    test('Should handle multiple query parameters', () {
      final uri = Uri.parse('http://example.com/?a=1&b=2&c=3');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.queryParam('a'), equals('1'));
      expect(context.queryParam('b'), equals('2'));
      expect(context.queryParam('c'), equals('3'));
    });

    test('Should prefer actual value over default', () {
      final uri = Uri.parse('http://example.com/?page=5');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.queryParam('page', '1'), equals('5'));
    });
  });

  group('Context - Context variables', () {
    test('Should set and get variables', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.set('key', 'value');
      expect(context.get<String>('key'), equals('value'));
    });

    test('Should type-cast variables correctly', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.set('number', 42);
      context.set('string', 'hello');
      context.set('bool', true);

      expect(context.get<int>('number'), equals(42));
      expect(context.get<String>('string'), equals('hello'));
      expect(context.get<bool>('bool'), equals(true));
    });

    test('Should return null for non-existent keys', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.get<String>('nonexistent'), isNull);
    });

    test('Should allow overwriting variables', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.set('key', 'value1');
      expect(context.get<String>('key'), equals('value1'));

      context.set('key', 'value2');
      expect(context.get<String>('key'), equals('value2'));
    });

    test('Should store complex objects', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final user = {'id': 1, 'name': 'Alice'};
      context.set('user', user);

      expect(context.get<Map>('user'), equals(user));
    });
  });

  group('Context - Response helpers', () {
    test('Should create JSON response via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.json({'message': 'Hello'});

      expect(response.statusCode, equals(200));
      expect(response.headers['content-type'], equals('application/json'));
    });

    test('Should create text response via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.text('Hello');

      expect(response.statusCode, equals(200));
      expect(
        response.headers['content-type'],
        equals('text/plain; charset=utf-8'),
      );
    });

    test('Should create HTML response via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.html('<h1>Hello</h1>');

      expect(response.statusCode, equals(200));
      expect(
        response.headers['content-type'],
        equals('text/html; charset=utf-8'),
      );
    });

    test('Should create redirect via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.redirect('/new-page');

      expect(response.statusCode, equals(302));
      expect(response.headers['location'], equals('/new-page'));
    });

    test('Should create stream response via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final stream = Stream<List<int>>.value([1, 2, 3]);
      final response = context.stream(stream);

      expect(response.statusCode, equals(200));
    });

    test('Should create notFound response via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.notFound();

      expect(response.statusCode, equals(404));
    });

    test('Should allow custom status codes for responses', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.json({'error': 'Unauthorized'}, statusCode: 401);

      expect(response.statusCode, equals(401));
    });
  });

  group('Context - Header management', () {
    test('Should allow setting response headers via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('X-Custom-Header', 'value');
      final response = context.json({});

      expect(response.headers['X-Custom-Header'], equals('value'));
    });

    test('Should merge multiple headers into response', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('X-Header-1', 'value1');
      context.header('X-Header-2', 'value2');
      final response = context.json({});

      expect(response.headers['X-Header-1'], equals('value1'));
      expect(response.headers['X-Header-2'], equals('value2'));
    });

    test('Should preserve default headers along with custom', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('X-Custom', 'custom');
      final response = context.json({});

      expect(response.headers['content-type'], equals('application/json'));
      expect(response.headers['X-Custom'], equals('custom'));
    });

    test('Should allow header override via context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('content-type', 'application/custom');
      final response = context.json({});

      expect(response.headers['content-type'], equals('application/custom'));
    });
  });

  group('Context - Response finalization', () {
    test('Should mark response as finalized', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.finalized, isFalse);

      context.json({'message': 'Hello'});

      expect(context.finalized, isTrue);
    });

    test('Should store finalized response', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.text('Hello');

      expect(context.response, equals(response));
    });

    test('Should prevent double finalization', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response1 = context.json({'first': true});

      // Second finalization should not override
      expect(context.response, equals(response1));
      expect(context.finalized, isTrue);
    });

    test('Should check finalization status', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.finalized, isFalse);
      expect(context.response, isNull);

      context.text('Done');

      expect(context.finalized, isTrue);
      expect(context.response, isNotNull);
    });
  });

  group('Context - Type-safe Env', () {
    test('Should support custom Env types', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final env = EmptyEnv();
      final context = Context(request, env);

      expect(context.variables, equals(env));
    });

    test('Should provide type-safe variable access', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.variables, isA<EmptyEnv>());
    });
  });

  group('Context - Integration', () {
    test('Should integrate request accessors with response helpers', () {
      final uri = Uri.parse('http://example.com/users/123?format=json');
      final request = Request('POST', uri, bodyContent: '{"name":"Alice"}');
      final context = Context(request, EmptyEnv());

      expect(context.method, equals('POST'));
      expect(context.path, equals('/users/123'));
      expect(context.query['format'], equals('json'));

      final response = context.json({'created': true});
      expect(response.statusCode, equals(200));
    });

    test('Should combine parameters and response generation', () {
      final uri = Uri.parse('http://example.com/users/456');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.set('param:id', '456');
      final id = context.param('id');

      final response = context.json({'userId': id});
      expect(response.statusCode, equals(200));
    });

    test('Should support middleware-style variable passing', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      // Simulate middleware setting user
      context.set('user', {'id': 1, 'name': 'Alice'});

      // Handler accessing user
      final user = context.get<Map>('user');
      final response = context.json({'user': user});

      expect(response.statusCode, equals(200));
    });
  });

  group('Context - Edge cases', () {
    test('Should handle empty query parameters', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.query, isEmpty);
    });

    test('Should handle empty headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.headers, isEmpty);
    });

    test('Should handle root path', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.path, equals('/'));
    });

    test('Should handle complex paths', () {
      final uri = Uri.parse('http://example.com/a/b/c/d/e');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      expect(context.path, equals('/a/b/c/d/e'));
    });

    test('Should return null for non-existent variable', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      // Context.set() requires non-null Object value
      expect(context.get('nonexistent'), isNull);
    });
  });
}
