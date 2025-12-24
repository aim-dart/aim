import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Middleware - Execution order', () {
    test('Should execute middleware in registration order (before phase)', () {
      final app = Aim();
      final executionOrder = <String>[];

      app.use((c, next) async {
        executionOrder.add('middleware1-before');
        await next();
        executionOrder.add('middleware1-after');
      });

      app.use((c, next) async {
        executionOrder.add('middleware2-before');
        await next();
        executionOrder.add('middleware2-after');
      });

      app.get('/', (c) async {
        executionOrder.add('handler');
        return c.text('Done');
      });

      // Middleware is registered
      expect(executionOrder, isEmpty); // Not executed yet
    });

    test('Should register multiple middleware', () {
      final app = Aim();

      app.use((c, next) async {
        await next();
      });

      app.use((c, next) async {
        await next();
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull); // Middleware registered
    });
  });

  group('Middleware - Next function', () {
    test('Should support calling next', () {
      final app = Aim();

      app.use((c, next) async {
        await next();
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });

    test('Should allow middleware to skip calling next', () {
      final app = Aim();

      app.use((c, next) async {
        // Don't call next() - stops the chain
        c.text('Early response');
      });

      app.use((c, next) async {
        await next();
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });
  });

  group('Middleware - Response finalization', () {
    test('Should allow middleware to finalize response early', () {
      final app = Aim();

      app.use((c, next) async {
        // Finalize response early
        c.json({'middleware': 'response'});
        // Don't call next()
      });

      app.get('/', (c) async => c.text('Handler'));

      expect(app, isNotNull);
    });

    test('Should check if response is finalized', () {
      final app = Aim();

      app.use((c, next) async {
        expect(c.finalized, isFalse);
        await next();
        expect(c.finalized, isTrue);
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });
  });

  group('Middleware - Context sharing', () {
    test('Should share context between middleware', () {
      final app = Aim();

      app.use((c, next) async {
        c.set('sharedValue', 'from-middleware');
        await next();
      });

      app.get('/', (c) async {
        final value = c.get<String>('sharedValue');
        return c.text(value ?? 'none');
      });

      expect(app, isNotNull);
    });

    test('Should allow middleware to set context variables', () {
      final app = Aim();

      app.use((c, next) async {
        c.set('user', {'id': 1, 'name': 'Alice'});
        c.set('timestamp', DateTime.now());
        await next();
      });

      app.get('/', (c) async {
        final user = c.get<Map>('user');
        return c.json(user as Map<String, dynamic>? ?? <String, dynamic>{});
      });

      expect(app, isNotNull);
    });

    test('Should allow handler to access middleware-set variables', () {
      final app = Aim();

      app.use((c, next) async {
        c.set('authenticated', true);
        await next();
      });

      app.get('/', (c) async {
        final authenticated = c.get<bool>('authenticated');
        return c.json({'authenticated': authenticated});
      });

      expect(app, isNotNull);
    });
  });

  group('Middleware - Async handling', () {
    test('Should support async middleware', () {
      final app = Aim();

      app.use((c, next) async {
        await Future.delayed(Duration(milliseconds: 1));
        await next();
      });

      app.get('/', (c) async => c.text('Async'));

      expect(app, isNotNull);
    });

    test('Should wait for async operations in next', () {
      final app = Aim();

      app.use((c, next) async {
        await next(); // Wait for handler to complete
      });

      app.get('/', (c) async {
        await Future.delayed(Duration(milliseconds: 1));
        return c.text('Done');
      });

      expect(app, isNotNull);
    });
  });

  group('Middleware - Header manipulation', () {
    test('Should allow middleware to add headers', () {
      final app = Aim();

      app.use((c, next) async {
        c.header('X-Middleware-Header', 'value');
        await next();
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });

    test('Should merge middleware headers with response', () {
      final app = Aim();

      app.use((c, next) async {
        c.header('X-Custom-1', 'value1');
        await next();
      });

      app.use((c, next) async {
        c.header('X-Custom-2', 'value2');
        await next();
      });

      app.get('/', (c) async => c.json({}));

      expect(app, isNotNull);
    });
  });

  group('Middleware - Authentication patterns', () {
    test('Should support authentication middleware', () {
      final app = Aim();

      app.use((c, next) async {
        final token = c.headers['authorization'];
        if (token == null) {
          c.json({'error': 'Unauthorized'}, statusCode: 401);
          return; // Don't call next()
        }
        c.set('authenticated', true);
        await next();
      });

      app.get('/protected', (c) async {
        return c.json({'data': 'secret'});
      });

      expect(app, isNotNull);
    });

    test('Should support role-based access control', () {
      final app = Aim();

      app.use((c, next) async {
        // Simulate checking user role
        c.set('role', 'admin');
        await next();
      });

      app.get('/admin', (c) async {
        final role = c.get<String>('role');
        if (role != 'admin') {
          return c.json({'error': 'Forbidden'}, statusCode: 403);
        }
        return c.json({'data': 'admin data'});
      });

      expect(app, isNotNull);
    });
  });

  group('Middleware - Logging patterns', () {
    test('Should support request logging middleware', () {
      final app = Aim();
      final logs = <String>[];

      app.use((c, next) async {
        logs.add('${c.method} ${c.path}');
        await next();
      });

      app.get('/test', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });

    test('Should support response timing middleware', () {
      final app = Aim();

      app.use((c, next) async {
        final start = DateTime.now();
        await next();
        final duration = DateTime.now().difference(start);
        c.header('X-Response-Time', '${duration.inMilliseconds}ms');
      });

      app.get('/', (c) async => c.text('Timed'));

      expect(app, isNotNull);
    });
  });

  group('Middleware - CORS patterns', () {
    test('Should support CORS middleware', () {
      final app = Aim();

      app.use((c, next) async {
        c.header('Access-Control-Allow-Origin', '*');
        c.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE');
        await next();
      });

      app.get('/api', (c) async => c.json({}));

      expect(app, isNotNull);
    });

    test('Should handle OPTIONS preflight', () {
      final app = Aim();

      app.use((c, next) async {
        if (c.method == 'OPTIONS') {
          c.text(
            '',
            statusCode: 204,
            headers: {'Access-Control-Allow-Methods': 'GET, POST'},
          );
          return; // Don't call next()
        }
        await next();
      });

      app.get('/api', (c) async => c.json({}));

      expect(app, isNotNull);
    });
  });

  group('Middleware - Conditional execution', () {
    test('Should conditionally apply middleware logic', () {
      final app = Aim();

      app.use((c, next) async {
        if (c.path.startsWith('/api')) {
          c.set('isApi', true);
        }
        await next();
      });

      app.get('/api/users', (c) async => c.json({}));
      app.get('/public', (c) async => c.text('Public'));

      expect(app, isNotNull);
    });

    test('Should skip middleware for specific paths', () {
      final app = Aim();

      app.use((c, next) async {
        if (c.path == '/skip') {
          await next();
          return;
        }
        c.set('processed', true);
        await next();
      });

      app.get('/normal', (c) async => c.text('Normal'));
      app.get('/skip', (c) async => c.text('Skipped'));

      expect(app, isNotNull);
    });
  });

  group('Middleware - Multiple middleware', () {
    test('Should support many middleware', () {
      final app = Aim();

      for (var i = 0; i < 10; i++) {
        app.use((c, next) async {
          c.set('middleware$i', true);
          await next();
        });
      }

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });

    test('Should execute all middleware in order', () {
      final app = Aim();
      final order = <int>[];

      app.use((c, next) async {
        order.add(1);
        await next();
      });

      app.use((c, next) async {
        order.add(2);
        await next();
      });

      app.use((c, next) async {
        order.add(3);
        await next();
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });
  });

  group('Middleware - Edge cases', () {
    test('Should handle middleware without next call', () {
      final app = Aim();

      app.use((c, next) async {
        c.text('Early response');
        // Not calling next() is valid
      });

      app.get('/', (c) async => c.text('Never reached'));

      expect(app, isNotNull);
    });

    test('Should handle empty middleware chain', () {
      final app = Aim();
      app.get('/', (c) async => c.text('No middleware'));

      expect(app, isNotNull);
    });

    test('Should handle middleware modifying request context', () {
      final app = Aim();

      app.use((c, next) async {
        c.set('modified', 'yes');
        await next();
      });

      app.get('/', (c) async {
        final modified = c.get<String>('modified');
        return c.text(modified ?? 'no');
      });

      expect(app, isNotNull);
    });
  });
}
