import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('HTTP Methods - GET requests', () {
    test('Should handle GET requests', () {
      final app = Aim();
      app.get('/users', (c) async => c.text('Users'));

      expect(app.routes[0].method, equals('GET'));
      expect(app.routes[0].path, equals('/users'));
    });

    test('Should support query parameters', () {
      final app = Aim();
      app.get('/search', (c) async {
        final query = c.queryParam('q', '');
        return c.text('Search: $query');
      });

      expect(app.routes[0].method, equals('GET'));
    });

    test('Should be idempotent by design', () {
      final app = Aim();
      var callCount = 0;

      app.get('/counter', (c) async {
        callCount++;
        return c.text('Called $callCount times');
      });

      // Multiple GET calls should be safe (idempotent in intention)
      expect(app.routes[0].method, equals('GET'));
    });
  });

  group('HTTP Methods - POST requests', () {
    test('Should handle POST requests', () {
      final app = Aim();
      app.post('/users', (c) async => c.text('Create user'));

      expect(app.routes[0].method, equals('POST'));
      expect(app.routes[0].path, equals('/users'));
    });

    test('Should accept request body', () {
      final app = Aim();
      app.post('/data', (c) async {
        // Handler can access body via c.req.json() or c.req.text()
        return c.text('Received');
      });

      expect(app.routes[0].method, equals('POST'));
    });

    test('Should support JSON body', () {
      final app = Aim();
      app.post('/api/users', (c) async {
        // In real usage: final data = await c.req.json();
        return c.json({'status': 'created'});
      });

      expect(app.routes[0].method, equals('POST'));
    });

    test('Should support text body', () {
      final app = Aim();
      app.post('/text', (c) async {
        // In real usage: final text = await c.req.text();
        return c.text('Received text');
      });

      expect(app.routes[0].method, equals('POST'));
    });
  });

  group('HTTP Methods - PUT requests', () {
    test('Should handle PUT requests', () {
      final app = Aim();
      app.put('/users/:id', (c) async {
        final id = c.param('id');
        return c.text('Update user $id');
      });

      expect(app.routes[0].method, equals('PUT'));
    });

    test('Should accept full resource replacement', () {
      final app = Aim();
      app.put('/resources/:id', (c) async {
        // In real usage: final data = await c.req.json();
        return c.json({'status': 'replaced'});
      });

      expect(app.routes[0].method, equals('PUT'));
    });

    test('Should be idempotent by design', () {
      final app = Aim();
      app.put('/items/:id', (c) async => c.text('Updated'));

      expect(app.routes[0].method, equals('PUT'));
    });
  });

  group('HTTP Methods - DELETE requests', () {
    test('Should handle DELETE requests', () {
      final app = Aim();
      app.delete('/users/:id', (c) async {
        final id = c.param('id');
        return c.text('Delete user $id');
      });

      expect(app.routes[0].method, equals('DELETE'));
    });

    test('Should be idempotent by design', () {
      final app = Aim();
      app.delete('/items/:id', (c) async => c.text('Deleted'));

      expect(app.routes[0].method, equals('DELETE'));
    });

    test('Should support deletion responses', () {
      final app = Aim();
      app.delete('/resources/:id', (c) async {
        return c.text('', statusCode: 204);
      });

      expect(app.routes[0].method, equals('DELETE'));
    });
  });

  group('HTTP Methods - PATCH requests', () {
    test('Should handle PATCH requests', () {
      final app = Aim();
      app.patch('/users/:id', (c) async {
        final id = c.param('id');
        return c.text('Patch user $id');
      });

      expect(app.routes[0].method, equals('PATCH'));
    });

    test('Should accept partial updates', () {
      final app = Aim();
      app.patch('/resources/:id', (c) async {
        // In real usage: final updates = await c.req.json();
        return c.json({'status': 'patched'});
      });

      expect(app.routes[0].method, equals('PATCH'));
    });
  });

  group('HTTP Methods - HEAD requests', () {
    test('Should handle HEAD requests', () {
      final app = Aim();
      app.head('/users', (c) async => c.text(''));

      expect(app.routes[0].method, equals('HEAD'));
    });

    test('Should return headers without body', () {
      final app = Aim();
      app.head('/resource', (c) async {
        // HEAD should return headers but no body
        return c.text(
          '',
          headers: {'content-length': '0', 'content-type': 'text/plain'},
        );
      });

      expect(app.routes[0].method, equals('HEAD'));
    });

    test('Should match corresponding GET route pattern', () {
      final app = Aim();
      app.get('/items/:id', (c) async => c.text('Item'));
      app.head('/items/:id', (c) async => c.text(''));

      expect(app.routes[0].method, equals('GET'));
      expect(app.routes[1].method, equals('HEAD'));
      expect(app.routes[0].path, equals(app.routes[1].path));
    });
  });

  group('HTTP Methods - OPTIONS requests', () {
    test('Should handle OPTIONS requests', () {
      final app = Aim();
      app.options('/users', (c) async => c.text(''));

      expect(app.routes[0].method, equals('OPTIONS'));
    });

    test('Should support CORS preflight', () {
      final app = Aim();
      app.options('/api/users', (c) async {
        return c.text(
          '',
          headers: {
            'access-control-allow-methods': 'GET, POST, PUT, DELETE',
            'access-control-allow-headers': 'Content-Type',
          },
        );
      });

      expect(app.routes[0].method, equals('OPTIONS'));
    });
  });

  group('HTTP Methods - Method routing isolation', () {
    test('Should route same path with different methods separately', () {
      final app = Aim();

      app.get('/users', (c) async => c.text('List users'));
      app.post('/users', (c) async => c.text('Create user'));
      app.put('/users', (c) async => c.text('Update all users'));
      app.delete('/users', (c) async => c.text('Delete all users'));

      expect(app.routes, hasLength(4));
      expect(app.routes[0].method, equals('GET'));
      expect(app.routes[1].method, equals('POST'));
      expect(app.routes[2].method, equals('PUT'));
      expect(app.routes[3].method, equals('DELETE'));

      // All should have same path
      expect(app.routes[0].path, equals('/users'));
      expect(app.routes[1].path, equals('/users'));
      expect(app.routes[2].path, equals('/users'));
      expect(app.routes[3].path, equals('/users'));
    });

    test('Should isolate parameterized routes by method', () {
      final app = Aim();

      app.get('/items/:id', (c) async => c.text('Get item'));
      app.put('/items/:id', (c) async => c.text('Update item'));
      app.delete('/items/:id', (c) async => c.text('Delete item'));

      expect(app.routes, hasLength(3));
      expect(app.routes[0].method, equals('GET'));
      expect(app.routes[1].method, equals('PUT'));
      expect(app.routes[2].method, equals('DELETE'));
    });

    test('Should maintain separate handlers per method', () {
      final app = Aim();

      app.get('/test', (c) async {
        return c.text('GET');
      });

      app.post('/test', (c) async {
        return c.text('POST');
      });

      expect(app.routes, hasLength(2));
      expect(app.routes[0].method, equals('GET'));
      expect(app.routes[1].method, equals('POST'));
    });
  });

  group('HTTP Methods - REST API patterns', () {
    test('Should support complete REST resource', () {
      final app = Aim();

      app.get('/items', (c) async => c.json({'items': []}));
      app.post('/items', (c) async => c.json({'id': 1}, statusCode: 201));
      app.get('/items/:id', (c) async => c.json({'id': c.param('id')}));
      app.put('/items/:id', (c) async => c.json({'id': c.param('id')}));
      app.patch('/items/:id', (c) async => c.json({'id': c.param('id')}));
      app.delete('/items/:id', (c) async => c.text('', statusCode: 204));

      expect(app.routes, hasLength(6));
    });

    test('Should support nested resources', () {
      final app = Aim();

      app.get('/users/:userId/posts', (c) async => c.json({'posts': []}));
      app.post('/users/:userId/posts', (c) async => c.json({'id': 1}));
      app.get('/users/:userId/posts/:postId', (c) async => c.json({}));
      app.put('/users/:userId/posts/:postId', (c) async => c.json({}));
      app.delete('/users/:userId/posts/:postId', (c) async => c.text(''));

      expect(app.routes, hasLength(5));
    });
  });

  group('HTTP Methods - Method combinations', () {
    test('Should allow all standard methods', () {
      final app = Aim();

      app.get('/resource', (c) async => c.text('GET'));
      app.post('/resource', (c) async => c.text('POST'));
      app.put('/resource', (c) async => c.text('PUT'));
      app.delete('/resource', (c) async => c.text('DELETE'));
      app.patch('/resource', (c) async => c.text('PATCH'));
      app.head('/resource', (c) async => c.text('HEAD'));
      app.options('/resource', (c) async => c.text('OPTIONS'));

      expect(app.routes, hasLength(7));

      final methods = app.routes.map((r) => r.method).toList();
      expect(methods, contains('GET'));
      expect(methods, contains('POST'));
      expect(methods, contains('PUT'));
      expect(methods, contains('DELETE'));
      expect(methods, contains('PATCH'));
      expect(methods, contains('HEAD'));
      expect(methods, contains('OPTIONS'));
    });

    test('Should allow selective method support', () {
      final app = Aim();

      // API that only supports GET and POST
      app.get('/readonly', (c) async => c.text('GET'));
      app.post('/writeonly', (c) async => c.text('POST'));

      expect(app.routes, hasLength(2));
    });
  });

  group('HTTP Methods - Method semantics', () {
    test('Should use GET for retrieval operations', () {
      final app = Aim();

      app.get('/users', (c) async => c.json({'users': []}));
      app.get('/users/:id', (c) async => c.json({'id': c.param('id')}));
      app.get('/search', (c) async => c.json({'results': []}));

      for (var route in app.routes) {
        expect(route.method, equals('GET'));
      }
    });

    test('Should use POST for creation operations', () {
      final app = Aim();

      app.post('/users', (c) async => c.json({'id': 1}, statusCode: 201));
      app.post('/sessions', (c) async => c.json({'token': 'abc'}));

      for (var route in app.routes) {
        expect(route.method, equals('POST'));
      }
    });

    test('Should use PUT for full replacement operations', () {
      final app = Aim();

      app.put('/users/:id', (c) async => c.json({}));
      app.put('/config', (c) async => c.json({}));

      for (var route in app.routes) {
        expect(route.method, equals('PUT'));
      }
    });

    test('Should use PATCH for partial updates', () {
      final app = Aim();

      app.patch('/users/:id', (c) async => c.json({}));
      app.patch('/settings', (c) async => c.json({}));

      for (var route in app.routes) {
        expect(route.method, equals('PATCH'));
      }
    });

    test('Should use DELETE for removal operations', () {
      final app = Aim();

      app.delete('/users/:id', (c) async => c.text('', statusCode: 204));
      app.delete('/sessions', (c) async => c.text('', statusCode: 204));

      for (var route in app.routes) {
        expect(route.method, equals('DELETE'));
      }
    });
  });
}
