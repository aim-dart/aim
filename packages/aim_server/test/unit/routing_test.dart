import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Routing - Exact path matching', () {
    test('Should match exact paths', () {
      final app = Aim();

      app.get('/users', (c) async {
        return c.text('Users');
      });

      final routes = app.routes;
      expect(routes, hasLength(1));
      expect(routes[0].path, equals('/users'));
      expect(routes[0].method, equals('GET'));
    });

    test('Should handle root path', () {
      final app = Aim();
      app.get('/', (c) async => c.text('Root'));

      final routes = app.routes;
      expect(routes[0].path, equals('/'));
    });

    test('Should handle nested paths', () {
      final app = Aim();
      app.get('/api/users/list', (c) async => c.text('List'));

      final routes = app.routes;
      expect(routes[0].path, equals('/api/users/list'));
    });

    test('Should handle paths with hyphens', () {
      final app = Aim();
      app.get('/user-profile', (c) async => c.text('Profile'));

      final routes = app.routes;
      expect(routes[0].path, equals('/user-profile'));
    });

    test('Should handle paths with numbers', () {
      final app = Aim();
      app.get('/api/v1/users', (c) async => c.text('V1 Users'));

      final routes = app.routes;
      expect(routes[0].path, equals('/api/v1/users'));
    });

    test('Should handle paths with underscores', () {
      final app = Aim();
      app.get('/user_profile', (c) async => c.text('Profile'));

      final routes = app.routes;
      expect(routes[0].path, equals('/user_profile'));
    });

    test('Should handle empty path segments', () {
      final app = Aim();
      app.get('/users//list', (c) async => c.text('List'));

      final routes = app.routes;
      expect(routes[0].path, equals('/users//list'));
    });
  });

  group('Routing - Named parameters', () {
    test('Should register route with single named parameter', () {
      final app = Aim();
      app.get('/users/:id', (c) async {
        final id = c.param('id');
        return c.text('User $id');
      });

      final routes = app.routes;
      expect(routes[0].path, equals('/users/:id'));
    });

    test('Should register route with multiple named parameters', () {
      final app = Aim();
      app.get('/users/:userId/posts/:postId', (c) async {
        final userId = c.param('userId');
        final postId = c.param('postId');
        return c.text('User $userId Post $postId');
      });

      final routes = app.routes;
      expect(routes[0].path, equals('/users/:userId/posts/:postId'));
    });

    test('Should handle parameters in different positions', () {
      final app = Aim();

      app.get('/:category/items', (c) async => c.text('Items'));
      app.get('/items/:id', (c) async => c.text('Item'));
      app.get('/items/:id/details', (c) async => c.text('Details'));

      expect(app.routes, hasLength(3));
      expect(app.routes[0].path, equals('/:category/items'));
      expect(app.routes[1].path, equals('/items/:id'));
      expect(app.routes[2].path, equals('/items/:id/details'));
    });

    test('Should handle parameter names with underscores', () {
      final app = Aim();
      app.get('/users/:user_id', (c) async {
        final userId = c.param('user_id');
        return c.text('User $userId');
      });

      final routes = app.routes;
      expect(routes[0].path, equals('/users/:user_id'));
    });

    test('Should handle parameters at root level', () {
      final app = Aim();
      app.get('/:id', (c) async {
        final id = c.param('id');
        return c.text('ID: $id');
      });

      final routes = app.routes;
      expect(routes[0].path, equals('/:id'));
    });
  });

  group('Routing - Regex constraints', () {
    test('Should register route with numeric constraint', () {
      final app = Aim();
      app.get('/users/:id(\\d+)', (c) async {
        final id = c.param('id');
        return c.text('User $id');
      });

      final routes = app.routes;
      expect(routes[0].path, equals('/users/:id(\\d+)'));
    });

    test('Should support multiple constrained parameters', () {
      final app = Aim();
      app.get('/users/:userId(\\d+)/posts/:postId(\\d+)', (c) async {
        return c.text('Match');
      });

      final routes = app.routes;
      expect(
        routes[0].path,
        equals('/users/:userId(\\d+)/posts/:postId(\\d+)'),
      );
    });

    test('Should handle complex regex patterns', () {
      final app = Aim();
      app.get('/files/:filename([a-z0-9-]+\\.pdf)', (c) async {
        return c.text('PDF');
      });

      final routes = app.routes;
      expect(routes[0].path, contains('[a-z0-9-]+\\.pdf'));
    });

    test('Should handle UUID pattern', () {
      final app = Aim();
      app.get(
        '/items/:uuid([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})',
        (c) async => c.text('UUID'),
      );

      final routes = app.routes;
      expect(routes[0].path, contains('[0-9a-f]{8}-'));
    });

    test('Should mix constrained and unconstrained parameters', () {
      final app = Aim();
      app.get('/api/:version(v\\d+)/:resource', (c) async {
        return c.text('Resource');
      });

      final routes = app.routes;
      expect(routes[0].path, equals('/api/:version(v\\d+)/:resource'));
    });
  });

  group('Routing - Wildcards', () {
    test('Should register route with trailing wildcard', () {
      final app = Aim();
      app.get('/files/*', (c) async => c.text('File'));

      final routes = app.routes;
      expect(routes[0].path, equals('/files/*'));
    });

    test('Should register route with wildcard parameter', () {
      final app = Aim();
      app.get('/static/*filepath', (c) async {
        final filepath = c.param('filepath');
        return c.text('File: $filepath');
      });

      final routes = app.routes;
      expect(routes[0].path, equals('/static/*filepath'));
    });

    test('Should handle wildcard at root', () {
      final app = Aim();
      app.get('/*', (c) async => c.text('Catch all'));

      final routes = app.routes;
      expect(routes[0].path, equals('/*'));
    });

    test('Should handle wildcard with prefix', () {
      final app = Aim();
      app.get('/public/*filepath', (c) async => c.text('Public'));

      final routes = app.routes;
      expect(routes[0].path, equals('/public/*filepath'));
    });
  });

  group('Routing - Route priority and order', () {
    test('Should register routes in order', () {
      final app = Aim();

      app.get('/first', (c) async => c.text('First'));
      app.get('/second', (c) async => c.text('Second'));
      app.get('/third', (c) async => c.text('Third'));

      expect(app.routes, hasLength(3));
      expect(app.routes[0].path, equals('/first'));
      expect(app.routes[1].path, equals('/second'));
      expect(app.routes[2].path, equals('/third'));
    });

    test('Should respect registration order for matching', () {
      final app = Aim();

      // First registered route should match first
      app.get('/:id', (c) async => c.text('Param'));
      app.get('/exact', (c) async => c.text('Exact'));

      expect(app.routes, hasLength(2));
      expect(app.routes[0].path, equals('/:id'));
      expect(app.routes[1].path, equals('/exact'));
    });

    test('Should allow same path with different methods', () {
      final app = Aim();

      app.get('/users', (c) async => c.text('Get users'));
      app.post('/users', (c) async => c.text('Create user'));
      app.delete('/users', (c) async => c.text('Delete users'));

      expect(app.routes, hasLength(3));
      expect(app.routes[0].method, equals('GET'));
      expect(app.routes[1].method, equals('POST'));
      expect(app.routes[2].method, equals('DELETE'));
    });

    test('Should handle many routes', () {
      final app = Aim();

      for (var i = 0; i < 100; i++) {
        app.get('/route$i', (c) async => c.text('Route $i'));
      }

      expect(app.routes, hasLength(100));
    });
  });

  group('Routing - HTTP methods', () {
    test('Should register GET route', () {
      final app = Aim();
      app.get('/test', (c) async => c.text('GET'));

      expect(app.routes[0].method, equals('GET'));
    });

    test('Should register POST route', () {
      final app = Aim();
      app.post('/test', (c) async => c.text('POST'));

      expect(app.routes[0].method, equals('POST'));
    });

    test('Should register PUT route', () {
      final app = Aim();
      app.put('/test', (c) async => c.text('PUT'));

      expect(app.routes[0].method, equals('PUT'));
    });

    test('Should register DELETE route', () {
      final app = Aim();
      app.delete('/test', (c) async => c.text('DELETE'));

      expect(app.routes[0].method, equals('DELETE'));
    });

    test('Should register PATCH route', () {
      final app = Aim();
      app.patch('/test', (c) async => c.text('PATCH'));

      expect(app.routes[0].method, equals('PATCH'));
    });

    test('Should register HEAD route', () {
      final app = Aim();
      app.head('/test', (c) async => c.text('HEAD'));

      expect(app.routes[0].method, equals('HEAD'));
    });

    test('Should register OPTIONS route', () {
      final app = Aim();
      app.options('/test', (c) async => c.text('OPTIONS'));

      expect(app.routes[0].method, equals('OPTIONS'));
    });
  });

  group('Routing - Method chaining', () {
    test('Should support method chaining', () {
      final app = Aim();

      final result = app
          .get('/route1', (c) async => c.text('1'))
          .post('/route2', (c) async => c.text('2'))
          .put('/route3', (c) async => c.text('3'));

      expect(result, same(app));
      expect(app.routes, hasLength(3));
    });

    test('Should chain different HTTP methods', () {
      final app = Aim();

      app
          .get('/users', (c) async => c.text('List'))
          .post('/users', (c) async => c.text('Create'))
          .put('/users/:id', (c) async => c.text('Update'))
          .delete('/users/:id', (c) async => c.text('Delete'));

      expect(app.routes, hasLength(4));
    });
  });

  group('Routing - Route metadata', () {
    test('Should support optional metadata', () {
      final app = Aim();

      app.get(
        '/users',
        (c) async => c.text('Users'),
        metadata: {'description': 'List all users'},
      );

      expect(app.routes[0].metadata, isNotNull);
      expect(
        (app.routes[0].metadata as Map)['description'],
        equals('List all users'),
      );
    });

    test('Should allow null metadata', () {
      final app = Aim();
      app.get('/test', (c) async => c.text('Test'));

      expect(app.routes[0].metadata, isNull);
    });

    test('Should support different metadata types', () {
      final app = Aim();

      app.get('/route1', (c) async => c.text('1'), metadata: 'string');
      app.get('/route2', (c) async => c.text('2'), metadata: 123);
      app.get('/route3', (c) async => c.text('3'), metadata: {'key': 'value'});

      expect(app.routes[0].metadata, equals('string'));
      expect(app.routes[1].metadata, equals(123));
      expect(app.routes[2].metadata, isA<Map>());
    });
  });

  group('Routing - Edge cases', () {
    test('Should handle paths with special characters', () {
      final app = Aim();
      app.get('/path-with-dash', (c) async => c.text('Dash'));

      expect(app.routes[0].path, equals('/path-with-dash'));
    });

    test('Should handle paths with dots', () {
      final app = Aim();
      app.get('/file.json', (c) async => c.text('JSON'));

      expect(app.routes[0].path, equals('/file.json'));
    });

    test('Should handle very long paths', () {
      final app = Aim();
      final longPath = '/a/b/c/d/e/f/g/h/i/j/k/l/m/n/o/p/q/r/s/t/u/v/w/x/y/z';
      app.get(longPath, (c) async => c.text('Long'));

      expect(app.routes[0].path, equals(longPath));
    });

    test('Should handle paths with consecutive slashes', () {
      final app = Aim();
      app.get('/path//with//slashes', (c) async => c.text('Slashes'));

      expect(app.routes[0].path, equals('/path//with//slashes'));
    });

    test('Should handle parameter-only path', () {
      final app = Aim();
      app.get('/:param', (c) async => c.text('Param'));

      expect(app.routes[0].path, equals('/:param'));
    });
  });

  group('Routing - Routes list', () {
    test('Should provide unmodifiable routes list', () {
      final app = Aim();
      app.get('/test', (c) async => c.text('Test'));

      final routes = app.routes;
      expect(routes, hasLength(1));

      // Should be unmodifiable
      expect(routes, isA<List<Route>>());
    });

    test('Should return current state of routes', () {
      final app = Aim();

      expect(app.routes, isEmpty);

      app.get('/route1', (c) async => c.text('1'));
      expect(app.routes, hasLength(1));

      app.get('/route2', (c) async => c.text('2'));
      expect(app.routes, hasLength(2));
    });

    test('Should expose route details', () {
      final app = Aim();
      app.get('/users/:id', (c) async => c.text('User'), metadata: 'test');

      final route = app.routes[0];
      expect(route.path, equals('/users/:id'));
      expect(route.method, equals('GET'));
      expect(route.handler, isNotNull);
      expect(route.metadata, equals('test'));
    });
  });

  group('Routing - Parameter extraction patterns', () {
    test('Should handle alphanumeric parameters', () {
      final app = Aim();
      app.get('/items/:id', (c) async {
        final id = c.param('id');
        return c.text('Item $id');
      });

      expect(app.routes[0].path, equals('/items/:id'));
    });

    test('Should handle parameters with numbers', () {
      final app = Aim();
      app.get('/api/:v1/users', (c) async => c.text('Users'));

      expect(app.routes[0].path, equals('/api/:v1/users'));
    });

    test('Should handle camelCase parameters', () {
      final app = Aim();
      app.get('/items/:itemId', (c) async {
        final itemId = c.param('itemId');
        return c.text('Item $itemId');
      });

      expect(app.routes[0].path, equals('/items/:itemId'));
    });
  });
}
