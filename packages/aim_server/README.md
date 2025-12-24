# aim_server

A lightweight and fast web server framework for Dart.

## Overview

`aim_server` is the core package of the Aim framework. It provides a simple yet powerful API for building web servers and RESTful APIs in Dart with support for routing, middleware, request/response handling, CORS, and environment variables.

## Features

- ⚡ **Fast HTTP Server** - Built on Dart's native HTTP server
- 🛣️ **Route Definitions** - Intuitive routing with path parameters
- 🔌 **Middleware Support** - Composable middleware chain
- 📨 **Request/Response Handling** - Easy-to-use request and response APIs
- 🌐 **CORS Support** - Built-in Cross-Origin Resource Sharing
- 🔒 **Type-safe** - Full Dart type safety
- 🌍 **Environment Variables** - Built-in environment variable support
- 📝 **JSON Support** - Native JSON request/response handling

## Installation

Add `aim_server` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: <latest version>
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Server

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';

void main() async {
  final app = Aim();

  app.get('/', (c) async {
    return c.json({'message': 'Hello, Aim!'});
  });

  final server = await app.serve(
    host: InternetAddress.anyIPv4,
    port: 8080,
  );

  print('Server started: http://${server.host}:${server.port}');
}
```

### Routing

#### Path Parameters

```dart
app.get('/users/:id', (c) async {
  final id = c.param('id');
  return c.json({'userId': id, 'name': 'User $id'});
});
```

#### Query Parameters

```dart
app.get('/search', (c) async {
  final query = c.queryParam('q', '');
  final page = c.queryParam('page', '1');

  return c.json({
    'query': query,
    'page': int.parse(page),
    'results': [],
  });
});
```

#### POST Requests with JSON

```dart
app.post('/api/users', (c) async {
  final data = await c.req.json();

  return c.json({
    'message': 'User created',
    'user': data,
  }, statusCode: 201);
});
```

### Middleware

Middleware functions are executed in order for each request:

```dart
// Logging middleware
app.use((c, next) async {
  final start = DateTime.now();
  print('[${start}] ${c.method} ${c.path}');

  await next();

  final duration = DateTime.now().difference(start);
  print('Request completed in ${duration.inMilliseconds}ms');
});

// Authentication middleware
app.use((c, next) async {
  final token = c.req.header('Authorization');

  if (token == null) {
    return c.json({'error': 'Unauthorized'}, statusCode: 401);
  }

  // Validate token...
  await next();
});
```

### CORS

```dart
import 'package:aim_server/aim_server.dart';

final app = Aim();

// Enable CORS for all routes
app.use(cors(
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization'],
));
```

### Error Handling

#### 404 Handler

```dart
app.notFound((c) async {
  return c.json({
    'error': 'Not Found',
    'path': c.path,
  }, statusCode: 404);
});
```

#### Global Error Handler

```dart
app.onError((error, c) async {
  print('Error: $error');

  return c.json({
    'error': error.toString(),
  }, statusCode: 500);
});
```

### Response Types

#### JSON Response

```dart
app.get('/json', (c) async {
  return c.json({'key': 'value'});
});
```

#### Text Response

```dart
app.get('/text', (c) async {
  return c.text('Hello, World!');
});
```

#### HTML Response

```dart
app.get('/html', (c) async {
  return c.html('<h1>Hello, World!</h1>');
});
```

#### Redirect

```dart
app.get('/old-path', (c) async {
  return c.redirect('/new-path');
});
```

### Environment Variables

```dart
import 'package:aim_server/aim_server.dart';

void main() {
  final env = Env();

  final port = env.get('PORT', defaultValue: '8080');
  final apiKey = env.get('API_KEY'); // Required

  print('Port: $port');
  print('API Key: $apiKey');
}
```

## API Reference

### Core Classes

- **`Aim`** - Main application class
  - `get(path, handler)` - Register GET route
  - `post(path, handler)` - Register POST route
  - `put(path, handler)` - Register PUT route
  - `delete(path, handler)` - Register DELETE route
  - `use(middleware)` - Add middleware
  - `notFound(handler)` - Set 404 handler
  - `onError(handler)` - Set error handler
  - `serve(host, port)` - Start server

- **`Context`** - Request context
  - `req` - Request object
  - `method` - HTTP method
  - `path` - Request path
  - `param(name)` - Get path parameter
  - `queryParam(name, defaultValue)` - Get query parameter
  - `json(data, statusCode)` - Send JSON response
  - `text(data, statusCode)` - Send text response
  - `html(data, statusCode)` - Send HTML response
  - `redirect(location, statusCode)` - Send redirect

- **`Request`** - HTTP request
  - `header(name)` - Get header value
  - `json()` - Parse JSON body
  - `text()` - Get text body

## Examples

See the [examples](../../examples) directory for complete working examples.

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
