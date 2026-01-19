<div align="center">
  <img src="docs/public/banner.png" alt="Aim – A lightweight, fast web framework for Dart" width="1536">
</div>

<hr />

A lightweight, fast, and developer-friendly web framework for Dart.

## Overview

Aim is a modern web framework for Dart that emphasizes simplicity, performance, and developer experience. It provides a clean API for building web servers and APIs with features like routing, middleware, hot reload during development, and more.

## Features

- **Fast and Lightweight** - Minimal overhead with excellent performance
- **Hot Reload** - Automatic server restart during development
- **Flexible Routing** - Intuitive path-based routing with parameter support
- **Middleware Support** - Composable middleware for request/response handling
- **CORS Support** - Built-in CORS handling
- **Authentication** - JWT and Basic authentication middleware
- **Database Support** - Native PostgreSQL driver with SSL/TLS support
- **Real-time** - Server-Sent Events (SSE) support
- **Type-safe** - Full Dart type safety
- **CLI Tools** - Project scaffolding and development server

## Packages

This repository contains the following packages:

### Core

| Package | pub.dev | Description |
|---------|---------|-------------|
| [aim_server](./packages/aim_server) | [![Pub Version](https://img.shields.io/pub/v/aim_server)](https://pub.dev/packages/aim_server) | Core web server framework with routing, middleware, and HTTP handling |
| [aim_cli](./packages/aim_cli) | [![Pub Version](https://img.shields.io/pub/v/aim_cli)](https://pub.dev/packages/aim_cli) | CLI tools for project scaffolding and development server with hot reload |

### Middleware

| Package | pub.dev | Description |
|---------|---------|-------------|
| [aim_server_cors](./packages/aim_server_cors) | [![Pub Version](https://img.shields.io/pub/v/aim_server_cors)](https://pub.dev/packages/aim_server_cors) | CORS (Cross-Origin Resource Sharing) middleware |
| [aim_server_cookie](./packages/aim_server_cookie) | [![Pub Version](https://img.shields.io/pub/v/aim_server_cookie)](https://pub.dev/packages/aim_server_cookie) | Secure cookie management (HttpOnly, SameSite, expiration) |
| [aim_server_form](./packages/aim_server_form) | [![Pub Version](https://img.shields.io/pub/v/aim_server_form)](https://pub.dev/packages/aim_server_form) | Form data parsing (application/x-www-form-urlencoded) |
| [aim_server_multipart](./packages/aim_server_multipart) | [![Pub Version](https://img.shields.io/pub/v/aim_server_multipart)](https://pub.dev/packages/aim_server_multipart) | Multipart form data parsing with file upload support |
| [aim_server_static](./packages/aim_server_static) | [![Pub Version](https://img.shields.io/pub/v/aim_server_static)](https://pub.dev/packages/aim_server_static) | Static file serving with security features |
| [aim_server_logger](./packages/aim_server_logger) | [![Pub Version](https://img.shields.io/pub/v/aim_server_logger)](https://pub.dev/packages/aim_server_logger) | HTTP logging with customizable output formats |
| [aim_server_sse](./packages/aim_server_sse) | [![Pub Version](https://img.shields.io/pub/v/aim_server_sse)](https://pub.dev/packages/aim_server_sse) | Server-Sent Events for real-time streaming |

### Authentication

| Package | pub.dev | Description |
|---------|---------|-------------|
| [aim_server_jwt](./packages/aim_server_jwt) | [![Pub Version](https://img.shields.io/pub/v/aim_server_jwt)](https://pub.dev/packages/aim_server_jwt) | JWT authentication with HS256, standard claims validation |
| [aim_server_basic_auth](./packages/aim_server_basic_auth) | [![Pub Version](https://img.shields.io/pub/v/aim_server_basic_auth)](https://pub.dev/packages/aim_server_basic_auth) | RFC 7617 compliant HTTP Basic Authentication |

### Database

| Package | pub.dev | Description |
|---------|---------|-------------|
| [aim_database](./packages/aim_database) | - | Database abstraction layer with unified interface |
| [aim_postgres](./packages/aim_postgres) | - | Native PostgreSQL driver with SSL/TLS and SCRAM-SHA-256 |

### Testing

| Package | pub.dev | Description |
|---------|---------|-------------|
| [aim_server_testing](./packages/aim_server_testing) | [![Pub Version](https://img.shields.io/pub/v/aim_server_testing)](https://pub.dev/packages/aim_server_testing) | Test helpers, matchers, and mock objects |

## Quick Start

### 1. Install the CLI

```bash
dart install aim_cli
```

### 2. Create a new project

```bash
aim create my_app
cd my_app
```

### 3. Install dependencies

```bash
dart pub get
```

### 4. Start the development server

```bash
aim dev
```

Your server will start at `http://localhost:8080` with hot reload enabled.

## Examples

### Basic Server

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';

void main() async {
  final app = Aim();

  // Middleware
  app.use((c, next) async {
    print('${c.req.method} ${c.req.path}');
    await next();
  });

  // Routes
  app.get('/', (c) async {
    return c.json({'message': 'Hello, Aim!'});
  });

  app.get('/users/:id', (c) async {
    final id = c.param('id');
    return c.json({'userId': id});
  });

  app.post('/api/users', (c) async {
    final data = await c.req.json();
    return c.json({'message': 'User created', 'data': data});
  });

  // Start server
  final server = await app.serve(
    host: InternetAddress.anyIPv4,
    port: 8080,
  );

  print('Server started: http://${server.address.host}:${server.port}');
}
```

### JWT Authentication

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';

void main() async {
  final app = Aim<JwtEnv>(
    envFactory: () => JwtEnv.create(
      JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
        ),
        excludedPaths: ['/login', '/public'],
      ),
    ),
  );

  app.use(jwt());

  app.get('/protected', (c) async {
    final payload = c.variables.jwtPayload;
    return c.json({'user_id': payload['user_id']});
  });

  await app.serve(port: 8080);
}
```

### PostgreSQL Database

```dart
import 'package:aim_postgres/aim_postgres.dart';

void main() async {
  // Connect to PostgreSQL
  final db = await PostgresDatabase.connect(
    'postgresql://user:pass@localhost:5432/mydb?sslmode=require',
  );

  // Query with named parameters
  final users = await db.query(
    'SELECT * FROM users WHERE status = :status',
    params: {'status': 'active'},
  );

  // Transaction support
  await db.transaction((tx) async {
    await tx.execute(
      'INSERT INTO users (name, email) VALUES (:name, :email)',
      params: {'name': 'Alice', 'email': 'alice@example.com'},
    );
  });

  await db.close();
}
```

### Server-Sent Events

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_sse/aim_server_sse.dart';

void main() async {
  final app = Aim();

  app.get('/events', (c) async {
    return c.sse((stream) async {
      for (var i = 0; i < 10; i++) {
        await stream.writeJson({'count': i});
        await Future.delayed(Duration(seconds: 1));
      }
    });
  });

  await app.serve(port: 8080);
}
```

## Development

This is a Dart workspace project. To work on the packages:

```bash
# Install dependencies for all packages
dart pub get

# Install the CLI locally for development
dart install packages/aim_cli

# Now you can use the aim command
aim create test_project

# Run tests
dart test

# Run linter
dart analyze
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source. See the LICENSE file for details.

## Links

- [Documentation](https://github.com/aim-dart/aim)
- [Issue Tracker](https://github.com/aim-dart/aim/issues)