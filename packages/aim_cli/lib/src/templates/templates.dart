/// String definitions for project templates
class Templates {
  static const projectPubspec = '''name: {{projectName}}
description: A web server built with Aim framework
version: 1.0.0

environment:
  sdk: ^3.10.0

dependencies:
  aim_server:
    git:
      url: https://github.com/yourusername/aim.git
      path: packages/aim_server
      # For development, use local path:
      # path: ../aim/packages/aim_server

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6

aim:
  entry: bin/server.dart
''';

  static const projectReadme = '''# {{projectName}}

A web server project built with Aim framework.

## Setup

Install dependencies:
```bash
dart pub get
```

## Run

Development mode (JIT):
```bash
dart run bin/server.dart
```

Production mode (AOT):
```bash
dart compile exe bin/server.dart -o server
./server
```

## Test

```bash
dart test
```

## Project Structure

- `bin/server.dart` - Server entry point
- `lib/src/server.dart` - Server implementation
- `test/{{projectName}}_test.dart` - Test files

## About Aim Framework

For more details, see [Aim Documentation](https://github.com/yourusername/aim).
''';

  static const binServer = '''import 'dart:io';
import 'package:{{projectName}}/src/server.dart';

void main() async {
  final app = createApp();

  // Start server
  final server = await app.serve(
    host: InternetAddress.anyIPv4,
    port: 8080,
  );

  print('🚀 Server started: http://\${server.host}:\${server.port}');
}
''';

  static const libSrcServer = '''import 'dart:io';
import 'package:aim_server/aim_server.dart';

/// Create Aim application
Aim createApp() {
  final app = Aim();

  // Logging middleware
  app.use((c, next) async {
    print('[\${DateTime.now()}] \${c.method} \${c.path}');
    await next();
  });

  // Route definitions
  app
      // Home page
      .get('/', (c) async {
    return c.json({
      'message': 'Welcome to {{projectName}}!',
      'framework': 'Aim',
      'timestamp': DateTime.now().toIso8601String(),
    });
  })

      // GET request with parameters
      .get('/users/:id', (c) async {
    final id = c.param('id');
    return c.json({
      'userId': id,
      'name': 'User \$id',
    });
  })

      // Query parameter example
      .get('/search', (c) async {
    final query = c.queryParam('q', '');
    final page = c.queryParam('page', '1');

    return c.json({
      'query': query,
      'page': int.parse(page),
      'results': [],
    });
  })

      // POST request (JSON)
      .post('/api/users', (c) async {
    final data = await c.req.json();

    return c.json({
      'message': 'User created',
      'user': data,
      'id': 'user-\${DateTime.now().millisecondsSinceEpoch}',
    });
  })

      // Redirect
      .get('/old-path', (c) async {
    return c.redirect('/');
  });

  // 404 handler
  app.notFound((c) async {
    return c.json({
      'error': 'Not Found',
      'path': c.path,
    }, statusCode: 404);
  });

  // Error handler
  app.onError((error, c) async {
    print('Error: \$error');
    return c.json({
      'error': error.toString(),
    }, statusCode: 500);
  });

  return app;
}
''';

  static const testTest = '''import 'package:test/test.dart';

void main() {
  test('sample test', () {
    expect(true, isTrue);
  });

  // Future test examples:
  // - API endpoint tests
  // - Middleware tests
  // - Business logic tests
}
''';

  static const gitignore = '''
# Dart
.dart_tool/
.packages
build/
pubspec.lock

# IDE
.idea/
.vscode/
*.iml
''';
}
