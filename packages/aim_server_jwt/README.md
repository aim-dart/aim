# aim_server_jwt

JWT (JSON Web Token) authentication middleware for the Aim framework.

## Overview

`aim_server_jwt` provides JWT authentication and authorization middleware for the Aim framework. This package enables stateless authentication using JSON Web Tokens with full support for standard JWT claims and secure token verification.

## Features

- 🔐 **JWT Verification** - Automatic Bearer token validation middleware
- 🎫 **Token Generation** - Easy-to-use token creation with standard claims
- 🔒 **Secure by Default** - Enforces minimum 32-character secret keys (RFC 7518)
- 📋 **Standard Claims** - Full support for iss, sub, aud, exp, iat, nbf claims
- 🛡️ **Custom Claims** - Add any custom payload data to tokens
- ⚡ **Path Exclusion** - Skip authentication for specific routes (e.g., /login)
- 🎯 **Type-safe** - Sealed class design with compile-time safety
- 🔑 **HMAC Algorithms** - HS256 support (RS256 and ECDSA coming soon)

## Installation

Add `aim_server_jwt` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6
  aim_server_jwt: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Authentication

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';

void main() {
  final app = Aim<JwtEnv>(
    envFactory: () => JwtEnv.create(
      JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
        ),
        excludedPaths: ['/login'],
      ),
    ),
  );

  // Apply JWT middleware
  app.use(jwt());

  // Login endpoint (excluded from auth)
  app.post('/login', (c) async {
    // Validate credentials...
    final token = Jwt(options: c.variables.jwtOptions).sign({
      'user_id': 123,
      'role': 'admin',
    });
    return c.json({'token': token});
  });

  // Protected endpoint
  app.get('/profile', (c) async {
    final payload = c.variables.jwtPayload;
    return c.json({
      'user_id': payload['user_id'],
      'role': payload['role'],
    });
  });

  app.serve(host: InternetAddress.anyIPv4, port: 8080);
}
```

### Token Generation with Standard Claims

```dart
final options = JwtOptions(
  algorithm: HS256(
    secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
  ),
  issuer: 'my-app',
  audience: 'api.example.com',
  expiration: Duration(hours: 24),
);

final jwt = Jwt(options: options);
final token = jwt.sign({
  'user_id': 123,
  'username': 'alice',
  'permissions': ['read', 'write'],
});
```

### Token Verification

```dart
try {
  final claims = jwt.verify(token);
  print('User ID: ${claims['user_id']}');
  print('Username: ${claims['username']}');
} on JwtException catch (e) {
  print('Invalid token: ${e.message}');
}
```

### Using Static Method

```dart
final token = Jwt.createToken(
  payload: {'user_id': 123, 'role': 'admin'},
  options: options,
);
```

### Path Exclusion

Exclude specific paths from authentication:

```dart
final options = JwtOptions(
  algorithm: HS256(
    secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
  ),
  excludedPaths: ['/login', '/register', '/public'],
);
```

### Complete Example with All Claims

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';

void main() {
  final jwtOptions = JwtOptions(
    algorithm: HS256(
      secretKey: SecretKey(secret: 'super-secret-key-change-in-production'),
    ),
    issuer: 'my-app',
    audience: 'api.example.com',
    expiration: Duration(hours: 24),
    notBefore: Duration(seconds: 0),
    excludedPaths: ['/login', '/health'],
  );

  final app = Aim<JwtEnv>(
    envFactory: () => JwtEnv.create(jwtOptions),
  );

  app.use(jwt());

  // Health check (excluded)
  app.get('/health', (c) async => c.text('OK'));

  // Login (excluded)
  app.post('/login', (c) async {
    final body = await c.req.json();

    // Validate credentials...
    if (body['username'] == 'admin' && body['password'] == 'secret') {
      final jwt = Jwt(options: c.variables.jwtOptions);
      final token = jwt.sign({
        'user_id': 1,
        'username': body['username'],
        'role': 'admin',
        'permissions': ['read', 'write', 'delete'],
      });

      return c.json({'token': token});
    }

    return c.json({'error': 'Invalid credentials'}, statusCode: 401);
  });

  // Protected routes
  app.get('/profile', (c) async {
    final payload = c.variables.jwtPayload;
    return c.json({
      'user_id': payload['user_id'],
      'username': payload['username'],
      'role': payload['role'],
    });
  });

  app.get('/admin', (c) async {
    final payload = c.variables.jwtPayload;

    if (payload['role'] != 'admin') {
      return c.json({'error': 'Forbidden'}, statusCode: 403);
    }

    return c.json({'message': 'Admin access granted'});
  });

  app.serve(host: InternetAddress.anyIPv4, port: 8080);
  print('Server running on http://localhost:8080');
}
```

## Supported Algorithms

### Currently Supported
- ✅ **HS256** (HMAC-SHA256) - Symmetric key algorithm

### Coming Soon
- 🔜 **RS256** (RSA-SHA256) - Asymmetric key algorithm for microservices
- 🔜 **ES256** (ECDSA-SHA256) - Elliptic curve algorithm

## Security Best Practices

1. **Secret Key Length**: Always use secrets of at least 32 characters for HS256
   ```dart
   // ✅ Good
   SecretKey(secret: 'super-secret-key-at-least-32-chars')

   // ❌ Bad - Will throw error
   SecretKey(secret: 'short')
   ```

2. **Token Expiration**: Always set an expiration time
   ```dart
   JwtOptions(
     algorithm: HS256(...),
     expiration: Duration(hours: 24), // Recommended
   )
   ```

3. **HTTPS Only**: Use JWT authentication only over HTTPS in production

4. **Secure Storage**: Never store secrets in code - use environment variables
   ```dart
   final secret = Platform.environment['JWT_SECRET'] ??
                  throw Exception('JWT_SECRET not set');
   ```

5. **Excluded Paths**: Be explicit about which paths don't require authentication

## How It Works

1. **Client Login**: User sends credentials to `/login`
2. **Token Generation**: Server validates credentials and creates a JWT token
3. **Client Storage**: Client stores token (e.g., in localStorage)
4. **Authenticated Requests**: Client sends token in `Authorization: Bearer <token>` header
5. **Middleware Verification**: JWT middleware verifies signature and claims
6. **Access Granted**: Valid token allows access to protected resources

```
Client                    Server
  |                         |
  |------ POST /login ----->|
  |   (credentials)         | Validate credentials
  |                         | Generate JWT
  |<----- { token } --------|
  |                         |
  | Store token             |
  |                         |
  |------ GET /profile ---->|
  |   Authorization: Bearer | Verify JWT
  |   <token>               | Extract claims
  |                         |
  |<----- { user data } ----|
```

## Error Handling

The middleware returns 401 Unauthorized in these cases:
- Missing Authorization header
- Invalid Bearer token format
- Invalid signature
- Expired token (exp claim)
- Token not yet valid (nbf claim)
- Issuer mismatch
- Audience mismatch

```dart
app.use(jwt());

app.get('/protected', (c) async {
  // If we reach here, token is valid
  final payload = c.variables.jwtPayload;
  return c.json({'user_id': payload['user_id']});
});
```

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
