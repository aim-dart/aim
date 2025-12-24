# aim_server_cors

CORS middleware for the aim_server framework.

## Overview

`aim_server_cors` provides Cross-Origin Resource Sharing (CORS) middleware for the Aim framework. This package was extracted from `aim_server` to provide modular CORS support with flexible configuration options for origin validation, method restrictions, header control, and more.

## Features

- 🌐 **Flexible Origin Control** - Support for wildcards, specific origins, multiple origins, or custom validation functions
- 🔒 **Credentials Support** - Enable cookies and authorization headers across origins
- 🛡️ **Method Restrictions** - Specify allowed HTTP methods
- 📋 **Header Control** - Configure allowed and exposed headers
- ⚡ **Preflight Handling** - Automatic OPTIONS request handling
- ⏱️ **Cache Control** - Configure preflight response caching duration
- 🎯 **Type-safe** - Full Dart type safety with `CorsOptions`

## Installation

Add `aim_server_cors` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: <latest_version>
  aim_server_cors: <latest_version>
```

Then run:

```bash
dart pub get
```

## Usage

### Basic CORS

Enable CORS for all origins (default):

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_cors/aim_server_cors.dart';

void main() async {
  final app = Aim();

  // Allow all origins
  app.use(cors());

  app.get('/', (c) async {
    return c.json({'message': 'CORS enabled!'});
  });

  await app.serve(port: 8080);
}
```

### Specific Origin

Allow requests from a specific origin:

```dart
app.use(cors(CorsOptions(
  origin: 'https://example.com',
  credentials: true,
)));
```

### Multiple Origins

Allow requests from multiple specific origins:

```dart
app.use(cors(CorsOptions(
  origin: ['https://example.com', 'https://app.example.com'],
  credentials: true,
)));
```

### Custom Origin Validation

Use a custom function to validate origins:

```dart
app.use(cors(CorsOptions(
  origin: (String origin) {
    // Allow all subdomains of example.com
    return origin.endsWith('.example.com');
  },
  credentials: true,
)));
```

### Method Restrictions

Specify allowed HTTP methods:

```dart
app.use(cors(CorsOptions(
  origin: '*',
  allowMethods: ['GET', 'POST'],
)));
```

### Header Configuration

Configure allowed and exposed headers:

```dart
app.use(cors(CorsOptions(
  origin: 'https://example.com',
  allowHeaders: ['Content-Type', 'Authorization', 'X-Custom-Header'],
  exposeHeaders: ['X-Total-Count'],
  credentials: true,
)));
```

### Preflight Cache

Configure how long preflight responses can be cached:

```dart
app.use(cors(CorsOptions(
  origin: 'https://example.com',
  maxAge: 86400, // 24 hours in seconds
)));
```

### Complete Example

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_cors/aim_server_cors.dart';

void main() async {
  final app = Aim();

  // Configure CORS
  app.use(cors(CorsOptions(
    origin: (String origin) => origin.endsWith('.example.com'),
    allowMethods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'],
    allowHeaders: ['Content-Type', 'Authorization'],
    exposeHeaders: ['X-Total-Count', 'X-Page-Number'],
    credentials: true,
    maxAge: 3600,
  )));

  // Your routes
  app.get('/api/data', (c) async {
    c.header('X-Total-Count', '100');
    return c.json({'items': []});
  });

  app.post('/api/data', (c) async {
    final data = await c.req.json();
    return c.json({'created': data}, statusCode: 201);
  });

  await app.serve(port: 8080);
  print('Server running on http://localhost:8080');
}
```

## API Reference

### `cors([CorsOptions options])`

Creates a CORS middleware with the specified options.

**Parameters:**
- `options` (optional) - CORS configuration options

**Returns:** `Middleware<E>`

### `CorsOptions`

Configuration options for CORS middleware.

**Properties:**

- **`origin`** (`dynamic`, default: `'*'`)
  - `String`: `'*'` for all origins, or a specific origin like `'https://example.com'`
  - `List<String>`: Multiple specific origins
  - `bool Function(String)`: Custom origin validation function

- **`allowMethods`** (`List<String>`, default: `['GET', 'HEAD', 'PUT', 'POST', 'DELETE', 'PATCH']`)
  - List of allowed HTTP methods

- **`allowHeaders`** (`List<String>`, default: `['*']`)
  - List of allowed request headers
  - Use `['*']` to allow all headers from the request

- **`exposeHeaders`** (`List<String>`, default: `[]`)
  - List of headers exposed to the browser

- **`credentials`** (`bool`, default: `false`)
  - Whether to allow credentials (cookies, authorization headers)

- **`maxAge`** (`int?`, default: `null`)
  - How long (in seconds) the results of a preflight request can be cached

## How It Works

The CORS middleware:

1. **Checks the origin** of incoming requests against the configured `origin` option
2. **Handles preflight requests** (OPTIONS) by responding with appropriate CORS headers
3. **Adds CORS headers** to regular responses for allowed origins
4. **Validates credentials** when `credentials: true` is set
5. **Caches preflight responses** when `maxAge` is specified


## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.