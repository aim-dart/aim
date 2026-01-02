# Middleware Overview

Aim provides a rich ecosystem of official middleware packages for common web application needs. Each package is published separately, allowing you to include only what you need.

## Available Middleware

### Core Features

| Package | Description | Version |
|---------|-------------|---------|
| [CORS](/middleware/cors) | Cross-Origin Resource Sharing support | 0.0.1 |
| [Logger](/middleware/logger) | HTTP request/response logging | 0.0.1 |
| [Static Files](/middleware/static) | Serve static files securely | 0.0.1 |

### Data Handling

| Package | Description | Version |
|---------|-------------|---------|
| [Cookie](/middleware/cookie) | Secure cookie management | 0.0.1 |
| [Form](/middleware/form) | Parse form data (application/x-www-form-urlencoded) | 0.0.1 |
| [Multipart](/middleware/multipart) | Handle file uploads (multipart/form-data) | 0.0.1 |

### Real-time

| Package | Description | Version |
|---------|-------------|---------|
| [SSE](/middleware/sse) | Server-Sent Events support | 0.0.1 |

### Authentication

| Package | Description | Version |
|---------|-------------|---------|
| [JWT Auth](/middleware/jwt) | JSON Web Token authentication | 0.0.1 |
| [Basic Auth](/middleware/basic-auth) | HTTP Basic Authentication (RFC 7617) | 0.0.1 |

## Installation

Add middleware packages to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6
  aim_server_cors: ^0.0.1
  aim_server_logger: ^0.0.1
  aim_server_jwt: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Quick Start

Most middleware follows a similar usage pattern:

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_logger/aim_server_logger.dart';
import 'package:aim_server_cors/aim_server_cors.dart';

void main() async {
  final app = Aim();

  // Add middleware with app.use()
  app.use(logger());
  app.use(cors());

  // Your routes
  app.get('/', (c) async => c.text('Hello!'));

  await app.serve(port: 8080);
}
```

## Middleware Order

The order in which you add middleware matters:

```dart
final app = Aim();

// 1. Logger (first to capture everything)
app.use(logger());

// 2. CORS (before authentication)
app.use(cors());

// 3. Authentication (protect routes below)
app.use(jwt());

// 4. Your routes
app.get('/protected', handler);
```

**Best practices:**
- Logger should be first to capture all requests
- CORS should be early to handle preflight requests
- Authentication should come before protected routes
- Error handlers should wrap other middleware

## Environment-Based Middleware

Some middleware requires custom environment classes:

```dart
import 'package:aim_server_jwt/aim_server_jwt.dart';

final app = Aim<JwtEnv>(
  envFactory: () => JwtEnv(
    secret: 'your-secret-key',
  ),
);

app.use(jwt());

app.get('/protected', (c) async {
  // Access JWT payload from environment
  final userId = c.variables.payload['sub'];
  return c.json({'userId': userId});
});
```

## Common Patterns

### Public + Protected Routes

```dart
import 'package:aim_server_jwt/aim_server_jwt.dart';

final app = Aim<JwtEnv>(
  envFactory: () => JwtEnv(secret: 'secret'),
);

// Global middleware
app.use(logger());
app.use(cors());

// Public routes
app.post('/login', loginHandler);
app.get('/public', publicHandler);

// Protected routes
app.use(jwt());
app.get('/dashboard', dashboardHandler);
app.get('/profile', profileHandler);
```

### API with Multiple Features

```dart
import 'package:aim_server_logger/aim_server_logger.dart';
import 'package:aim_server_cors/aim_server_cors.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';
import 'package:aim_server_form/aim_server_form.dart';

// Combine multiple middleware environments
class ApiEnv extends JwtEnv with FormMixin {
  ApiEnv() : super(secret: Platform.environment['JWT_SECRET']!);
}

final app = Aim<ApiEnv>(
  envFactory: () => ApiEnv(),
);

app.use(logger());
app.use(cors(origin: 'https://example.com'));
app.use(form());
app.use(jwt());

app.post('/api/data', apiHandler);
```

### File Upload API

```dart
import 'package:aim_server_multipart/aim_server_multipart.dart';

final app = Aim<MultipartEnv>(
  envFactory: () => MultipartEnv(),
);

app.use(logger());
app.use(multipart(
  maxFileSize: 10 * 1024 * 1024, // 10MB
));

app.post('/upload', uploadHandler);
```

## Creating Custom Middleware

You can create your own middleware:

```dart
// Simple middleware
Future<void> requestTiming(Context c, Next next) async {
  final stopwatch = Stopwatch()..start();
  await next();
  stopwatch.stop();
  print('Request took ${stopwatch.elapsedMilliseconds}ms');
}

// Middleware factory
Middleware<E> customHeader<E extends Env>(String name, String value) {
  return (c, next) async {
    c.header(name, value);
    return next();
  };
}

// Usage
app.use(requestTiming);
app.use(customHeader('X-API-Version', '1.0'));
```

## Middleware Packages

Explore each middleware package for detailed documentation:

- **[CORS](/middleware/cors)** - Handle cross-origin requests
- **[Cookie](/middleware/cookie)** - Secure cookie management
- **[Form](/middleware/form)** - Parse form data
- **[Multipart](/middleware/multipart)** - File upload handling
- **[Static Files](/middleware/static)** - Serve static assets
- **[Logger](/middleware/logger)** - Request/response logging
- **[SSE](/middleware/sse)** - Real-time server-sent events
- **[JWT Auth](/middleware/jwt)** - Token-based authentication
- **[Basic Auth](/middleware/basic-auth)** - Username/password authentication

## Next Steps

- Learn about [creating custom middleware](/concepts/middleware)
- Explore specific middleware packages
- Check out the [Context API](/concepts/context) for request handling
