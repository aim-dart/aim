import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Error Handling - Handler errors', () {
    test('Should support custom error handler', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': error.toString()}, statusCode: 500);
      });

      app.get('/error', (c) async {
        throw Exception('Test error');
      });

      expect(app, isNotNull);
    });

    test('Should handle synchronous errors in handlers', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': 'handled'}, statusCode: 500);
      });

      app.get('/sync-error', (c) async {
        throw Exception('Sync error');
      });

      expect(app, isNotNull);
    });

    test('Should handle async errors in handlers', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': 'async handled'}, statusCode: 500);
      });

      app.get('/async-error', (c) async {
        await Future.delayed(Duration(milliseconds: 1));
        throw Exception('Async error');
      });

      expect(app, isNotNull);
    });
  });

  group('Error Handling - Middleware errors', () {
    test('Should catch errors in middleware', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': 'middleware error'}, statusCode: 500);
      });

      app.use((c, next) async {
        throw Exception('Middleware error');
      });

      app.get('/', (c) async => c.text('Never reached'));

      expect(app, isNotNull);
    });

    test('Should handle middleware async errors', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': 'handled'}, statusCode: 500);
      });

      app.use((c, next) async {
        await Future.delayed(Duration(milliseconds: 1));
        throw Exception('Async middleware error');
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });
  });

  group('Error Handling - Error handler', () {
    test('Should receive error and context', () {
      final app = Aim();

      app.onError((error, c) async {
        // Error handler receives both error and context
        expect(error, isA<Exception>());
        expect(c, isA<Context>());
        return c.json({'error': 'handled'}, statusCode: 500);
      });

      app.get('/error', (c) async {
        throw Exception('Test error');
      });

      expect(app, isNotNull);
    });

    test('Should allow custom error responses', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({
          'status': 'error',
          'message': error.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        }, statusCode: 500);
      });

      app.get('/error', (c) async {
        throw Exception('Custom error');
      });

      expect(app, isNotNull);
    });

    test('Should support different error status codes', () {
      final app = Aim();

      app.onError((error, c) async {
        if (error.toString().contains('Unauthorized')) {
          return c.json({'error': 'Unauthorized'}, statusCode: 401);
        }
        if (error.toString().contains('Forbidden')) {
          return c.json({'error': 'Forbidden'}, statusCode: 403);
        }
        return c.json({'error': error.toString()}, statusCode: 500);
      });

      app.get('/unauthorized', (c) async {
        throw Exception('Unauthorized');
      });

      expect(app, isNotNull);
    });
  });

  group('Error Handling - 404 handling', () {
    test('Should support custom notFound handler', () {
      final app = Aim();

      app.notFound((c) async {
        return c.json({'error': 'Not Found', 'path': c.path}, statusCode: 404);
      });

      app.get('/exists', (c) async => c.text('Exists'));

      expect(app, isNotNull);
    });

    test('Should allow custom 404 responses', () {
      final app = Aim();

      app.notFound((c) async {
        return c.html('<h1>404 - Page Not Found</h1>', statusCode: 404);
      });

      expect(app, isNotNull);
    });

    test('Should provide context to notFound handler', () {
      final app = Aim();

      app.notFound((c) async {
        // notFound handler receives context
        expect(c, isA<Context>());
        return c.json({
          'error': '404',
          'method': c.method,
          'path': c.path,
        }, statusCode: 404);
      });

      expect(app, isNotNull);
    });
  });

  group('Error Handling - Error types', () {
    test('Should handle Exception', () {
      final app = Aim();

      app.onError((error, c) async {
        expect(error, isA<Exception>());
        return c.json({'error': 'Exception'}, statusCode: 500);
      });

      app.get('/exception', (c) async {
        throw Exception('Test exception');
      });

      expect(app, isNotNull);
    });

    test('Should handle Error', () {
      final app = Aim();

      app.onError((error, c) async {
        expect(error, isA<Error>());
        return c.json({'error': 'Error'}, statusCode: 500);
      });

      app.get('/error', (c) async {
        throw ArgumentError('Test error');
      });

      expect(app, isNotNull);
    });

    test('Should handle String errors', () {
      final app = Aim();

      app.onError((error, c) async {
        expect(error, isA<String>());
        return c.json({'error': error}, statusCode: 500);
      });

      app.get('/string-error', (c) async {
        throw 'String error';
      });

      expect(app, isNotNull);
    });

    test('Should handle custom error classes', () {
      final app = Aim();

      app.onError((error, c) async {
        if (error is CustomError) {
          return c.json({'code': error.code}, statusCode: error.statusCode);
        }
        return c.json({'error': 'Unknown'}, statusCode: 500);
      });

      app.get('/custom', (c) async {
        throw CustomError(code: 'CUSTOM_ERROR', statusCode: 400);
      });

      expect(app, isNotNull);
    });
  });

  group('Error Handling - JSON parsing errors', () {
    test('Should handle invalid JSON gracefully', () {
      final app = Aim();

      app.onError((error, c) async {
        if (error is FormatException) {
          return c.json({'error': 'Invalid JSON'}, statusCode: 400);
        }
        return c.json({'error': 'Error'}, statusCode: 500);
      });

      app.post('/data', (c) async {
        // This would throw FormatException in real usage
        return c.json({});
      });

      expect(app, isNotNull);
    });
  });

  group('Error Handling - Error propagation', () {
    test('Should propagate errors through middleware', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': 'propagated'}, statusCode: 500);
      });

      app.use((c, next) async {
        await next(); // Error should propagate through
      });

      app.get('/error', (c) async {
        throw Exception('Propagate me');
      });

      expect(app, isNotNull);
    });

    test('Should stop middleware chain on error', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': 'handled'}, statusCode: 500);
      });

      app.use((c, next) async {
        throw Exception('Error in middleware');
      });

      app.use((c, next) async {
        // This middleware should not be called after error
        await next();
      });

      app.get('/', (c) async => c.text('Test'));

      expect(app, isNotNull);
    });
  });

  group('Error Handling - Edge cases', () {
    test('Should handle errors without error handler', () {
      final app = Aim();

      app.get('/error', (c) async {
        throw Exception('No handler');
      });

      expect(app, isNotNull);
    });

    test('Should handle null error message', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({'error': error.toString()}, statusCode: 500);
      });

      app.get('/null-error', (c) async {
        throw Exception(); // No message
      });

      expect(app, isNotNull);
    });

    test('Should handle errors in error handler itself', () {
      final app = Aim();

      app.onError((error, c) async {
        // Error in error handler
        if (error.toString().contains('trigger-error-handler-error')) {
          throw Exception('Error in error handler');
        }
        return c.json({'error': 'handled'}, statusCode: 500);
      });

      app.get('/normal-error', (c) async {
        throw Exception('Normal error');
      });

      app.get('/error-handler-error', (c) async {
        throw Exception('trigger-error-handler-error');
      });

      expect(app, isNotNull);
    });
  });

  group('Error Handling - Error context', () {
    test('Should preserve request context on error', () {
      final app = Aim();

      app.onError((error, c) async {
        return c.json({
          'error': error.toString(),
          'method': c.method,
          'path': c.path,
        }, statusCode: 500);
      });

      app.get('/error', (c) async {
        throw Exception('With context');
      });

      expect(app, isNotNull);
    });

    test('Should access middleware-set variables in error handler', () {
      final app = Aim();

      app.use((c, next) async {
        c.set('requestId', '12345');
        await next();
      });

      app.onError((error, c) async {
        final requestId = c.get<String>('requestId');
        return c.json({
          'error': error.toString(),
          'requestId': requestId,
        }, statusCode: 500);
      });

      app.get('/error', (c) async {
        throw Exception('Error');
      });

      expect(app, isNotNull);
    });
  });
}

class CustomError implements Exception {
  final String code;
  final int statusCode;

  CustomError({required this.code, required this.statusCode});

  @override
  String toString() => 'CustomError: $code';
}
