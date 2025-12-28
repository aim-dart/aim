/// String definitions for project templates
class Templates {
  static const projectPubspec = '''name: {{projectName}}
description: A web server built with Aim framework
version: 1.0.0

environment:
  sdk: ^3.10.0

dependencies:
  aim_server: ^0.0.6

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

## Development

Start development server with hot reload:
```bash
aim dev
```

Or run directly:
```bash
dart run bin/server.dart
```

## Production Build

### Option 1: Native Executable

Compile to a native executable:
```bash
aim build
```

Run the executable:
```bash
./build/server
```

With environment variables:
```bash
PORT=3000 ./build/server
```

Or using a `.env` file (if your app uses a dotenv package):
```bash
./build/server
```

### Option 2: Docker

Build Docker image:
```bash
docker build -t {{projectName}} .
```

Run container:
```bash
docker run -p 8080:8080 {{projectName}}
```

With environment variables:
```bash
docker run -p 8080:8080 -e PORT=3000 -e ENV=production {{projectName}}
```

Or using an env file:
```bash
docker run -p 8080:8080 --env-file .env {{projectName}}
```

## Test

```bash
dart test
```

## Project Structure

- `bin/server.dart` - Server entry point
- `lib/src/server.dart` - Server implementation
- `test/{{projectName}}_test.dart` - Test files
- `Dockerfile` - Docker configuration for production
- `.dockerignore` - Files to exclude from Docker build

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

  static const dockerfile =
      '''# Official Dart image: https://hub.docker.com/_/dart
FROM dart:stable AS build

WORKDIR /app

# Copy and resolve dependencies
COPY pubspec.* ./
RUN dart pub get

# Copy app source code
COPY . .

# Ensure packages are up-to-date
RUN dart pub get --offline

# Compile to native executable
RUN dart compile exe bin/server.dart -o bin/server

# Build minimal serving image from AOT-compiled binary
FROM scratch

# Copy runtime dependencies and compiled binary
COPY --from=build /runtime/ /
COPY --from=build /app/bin/server /app/bin/

# Expose port (default: 8080)
EXPOSE 8080

# Start server
CMD ["/app/bin/server"]
''';

  static const dockerignore = '''# Dockerfile
.dockerignore
Dockerfile

# Build outputs
build/
*.exe
*.app

# Dart
.dart_tool/
.packages

# Version control
.git/
.gitignore
.github/

# IDE
.idea/
.vscode/
*.iml
*.code-workspace

# Documentation
README.md
CHANGELOG.md
LICENSE

# Tests
test/
*_test.dart

# CI/CD
.travis.yml
.gitlab-ci.yml

# Misc
*.log
*.tmp
.DS_Store
''';
}
