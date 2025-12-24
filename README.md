# Aim

A lightweight, fast, and developer-friendly web framework for Dart.

## Overview

Aim is a modern web framework for Dart that emphasizes simplicity, performance, and developer experience. It provides a clean API for building web servers and APIs with features like routing, middleware, hot reload during development, and more.

## Features

- 🚀 **Fast and Lightweight** - Minimal overhead with excellent performance
- 🔥 **Hot Reload** - Automatic server restart during development
- 🛣️ **Flexible Routing** - Intuitive path-based routing with parameter support
- 🔌 **Middleware Support** - Composable middleware for request/response handling
- 🌐 **CORS Support** - Built-in CORS handling
- 📝 **Type-safe** - Full Dart type safety
- 🛠️ **CLI Tools** - Project scaffolding and development server

## Packages

This repository contains the following packages:

### [aim_server](./packages/aim_server)

The core web server framework package. Provides routing, middleware, request/response handling, and more.

### [aim_cli](./packages/aim_cli)

Command-line tools for creating and managing Aim projects. Includes project scaffolding and a development server with hot reload.

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

## Example

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';

void main() async {
  final app = Aim();

  // Middleware
  app.use((c, next) async {
    print('${c.method} ${c.path}');
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

  print('Server started: http://${server.host}:${server.port}');
}
```

## Architecture

Aim follows a modular architecture:

- **aim_server**: Core framework with routing, middleware, and HTTP handling
- **aim_cli**: Development tools for project management and hot reload
- **Examples**: Sample projects demonstrating various features

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
