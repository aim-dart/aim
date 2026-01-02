# aim_server_basic_auth

HTTP Basic Authentication middleware for the Aim framework.

## Overview

`aim_server_basic_auth` provides RFC 7617 compliant HTTP Basic Authentication middleware for the Aim framework. This package enables simple username/password authentication with full support for custom user verification, realm configuration, and path exclusions.

## Features

- 🔐 **Basic Authentication** - RFC 7617 compliant HTTP Basic Auth middleware
- 🎫 **Custom Verification** - Flexible async user verification function
- 🔒 **Secure** - Automatic WWW-Authenticate header response
- 📋 **Realm Support** - Configurable protection realm for authentication dialogs
- ⚡ **Path Exclusion** - Skip authentication for specific routes (e.g., /login, /public)
- 🛡️ **Flexible** - Supports passwords with special characters, including colons
- 🌐 **Unicode Support** - Full support for non-ASCII characters in credentials
- 🎯 **Type-safe** - Leverages Dart's type system for compile-time safety

## Installation

Add `aim_server_basic_auth` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6
  aim_server_basic_auth: ^0.0.1
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
import 'package:aim_server_basic_auth/aim_server_basic_auth.dart';

void main() {
  final app = Aim<BasicAuthEnv>(
    envFactory: () => BasicAuthEnv(
      options: BasicAuthOptions(
        realm: 'Admin Area',
        verify: (username, password) async {
          // Simple credential check (use password hashing in production!)
          return username == 'admin' && password == 'secret123';
        },
      ),
    ),
  );

  // Apply Basic Auth middleware
  app.use(basicAuth());

  // Protected endpoint
  app.get('/admin', (c) async {
    final username = c.variables.username;
    return c.json({'message': 'Welcome, $username!'});
  });

  app.serve(host: InternetAddress.anyIPv4, port: 8080);
  print('Server running on http://localhost:8080');
}
```

### With Database Verification

```dart
import 'package:crypto/crypto.dart';
import 'dart:convert';

final app = Aim<BasicAuthEnv>(
  envFactory: () => BasicAuthEnv(
    options: BasicAuthOptions(
      realm: 'My Application',
      verify: (username, password) async {
        // Fetch user from database
        final user = await database.findUserByUsername(username);
        if (user == null) return false;

        // Verify password hash (using bcrypt, argon2, etc.)
        final passwordHash = sha256.convert(utf8.encode(password)).toString();
        return passwordHash == user.passwordHash;
      },
    ),
  ),
);

app.use(basicAuth());
```

### Path Exclusion

Exclude specific paths from authentication:

```dart
final app = Aim<BasicAuthEnv>(
  envFactory: () => BasicAuthEnv(
    options: BasicAuthOptions(
      realm: 'Protected Area',
      verify: (username, password) async {
        return username == 'admin' && password == 'secret';
      },
      excludedPaths: ['/login', '/register', '/public', '/health'],
    ),
  ),
);

app.use(basicAuth());

// Public endpoint (no authentication required)
app.get('/login', (c) async {
  return c.html('<form>...</form>');
});

// Protected endpoint (authentication required)
app.get('/dashboard', (c) async {
  final username = c.variables.username;
  return c.json({'user': username});
});
```

### Custom Realm

The realm identifier appears in the browser's authentication dialog:

```dart
final options = BasicAuthOptions(
  realm: 'Staff Only Area',  // Shown to users
  verify: (username, password) async {
    return await authService.verify(username, password);
  },
);
```

### Complete Example

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_basic_auth/aim_server_basic_auth.dart';

void main() async {
  // Configuration
  final options = BasicAuthOptions(
    realm: 'Admin Dashboard',
    verify: (username, password) async {
      // In production, verify against a database with hashed passwords
      final validUsers = {
        'admin': 'admin_password_hash',
        'user': 'user_password_hash',
      };

      return validUsers[username] == password; // Simplified for demo
    },
    excludedPaths: ['/login', '/health', '/public'],
  );

  final app = Aim<BasicAuthEnv>(
    envFactory: () => BasicAuthEnv(options: options),
  );

  app.use(basicAuth());

  // Health check (excluded from auth)
  app.get('/health', (c) async => c.json({'status': 'ok'}));

  // Login page (excluded from auth)
  app.get('/login', (c) async {
    return c.html('''
      <h1>Login</h1>
      <p>Use HTTP Basic Authentication to access protected resources.</p>
    ''');
  });

  // Protected admin routes
  app.get('/admin/dashboard', (c) async {
    final username = c.variables.username;
    return c.json({
      'page': 'dashboard',
      'user': username,
      'timestamp': DateTime.now().toIso8601String(),
    });
  });

  app.get('/admin/users', (c) async {
    final username = c.variables.username;
    return c.json({
      'page': 'users',
      'admin': username,
      'users': ['alice', 'bob', 'charlie'],
    });
  });

  // Protected API endpoint
  app.post('/api/data', (c) async {
    final username = c.variables.username;
    final body = await c.req.json();

    return c.json({
      'message': 'Data received',
      'user': username,
      'data': body,
    });
  });

  await app.serve(host: InternetAddress.anyIPv4, port: 8080);
  print('Server running on http://localhost:8080');
  print('Try accessing: http://localhost:8080/admin/dashboard');
  print('Credentials: admin / admin_password_hash');
}
```

## How It Works

1. **Client Request**: User attempts to access a protected resource
2. **Missing Credentials**: Server returns 401 with `WWW-Authenticate: Basic realm="..."`
3. **Browser Dialog**: Browser displays authentication dialog with the realm name
4. **Credential Submission**: Client sends `Authorization: Basic base64(username:password)`
5. **Verification**: Server decodes and verifies credentials using the `verify` function
6. **Access Granted/Denied**:
   - Valid credentials → sets `c.variables.username` and proceeds
   - Invalid credentials → returns 401 with WWW-Authenticate header

```
Client                          Server
  |                               |
  |------ GET /admin ------------>|
  |                               | (no auth header)
  |<----- 401 Unauthorized -------|
  |   WWW-Authenticate: Basic     |
  |   realm="Admin Area"          |
  |                               |
  | [Browser shows dialog]        |
  |                               |
  |------ GET /admin ------------>|
  |   Authorization: Basic        |
  |   YWRtaW46c2VjcmV0           |
  |                               | (verify credentials)
  |<----- 200 OK -----------------|
  |   {"user": "admin"}           |
```

## Security Best Practices

### 1. Always Use HTTPS in Production

Basic Auth sends credentials in Base64 encoding (not encryption). **Always use HTTPS** to prevent credentials from being intercepted.

```dart
// ✅ Production
final server = await app.serve(
  host: InternetAddress.anyIPv4,
  port: 443,
  securityContext: SecurityContext()
    ..useCertificateChain('server_chain.pem')
    ..usePrivateKey('server_key.pem'),
);
```

### 2. Use Strong Password Hashing

Never store or compare plaintext passwords. Use bcrypt, argon2, or similar:

```dart
import 'package:bcrypt/bcrypt.dart';

verify: (username, password) async {
  final user = await db.findUser(username);
  if (user == null) return false;

  // Verify hashed password
  return BCrypt.checkpw(password, user.passwordHash);
}
```

### 3. Implement Rate Limiting

Protect against brute force attacks:

```dart
// Use aim_server_ratelimit (when available) or implement custom logic
final loginAttempts = <String, int>{};

verify: (username, password) async {
  // Check rate limit
  final attempts = loginAttempts[username] ?? 0;
  if (attempts >= 5) {
    return false; // Locked out
  }

  final isValid = await authService.verify(username, password);

  if (!isValid) {
    loginAttempts[username] = attempts + 1;
  } else {
    loginAttempts.remove(username);
  }

  return isValid;
}
```

### 4. Never Log Passwords

```dart
// ❌ Bad
print('Login attempt: $username:$password');

// ✅ Good
print('Login attempt for user: $username');
```

### 5. Use Environment Variables for Secrets

```dart
final secret = Platform.environment['ADMIN_PASSWORD'] ??
               throw Exception('ADMIN_PASSWORD not set');
```

## Error Handling

The middleware returns 401 Unauthorized in these cases:

- Missing `Authorization` header
- Invalid `Authorization` header format (not "Basic ...")
- Invalid Base64 encoding
- Missing colon separator in credentials
- Verification function returns `false`

All 401 responses include the `WWW-Authenticate` header with the configured realm.

```dart
// Example 401 response
HTTP/1.1 401 Unauthorized
WWW-Authenticate: Basic realm="Admin Area"
Content-Type: application/json

{"error": "Unauthorized"}
```

## API Reference

For detailed API documentation, see the [API reference on pub.dev](https://pub.dev/documentation/aim_server_basic_auth/latest/).

## Comparison with JWT

| Feature | Basic Auth | JWT |
|---------|-----------|-----|
| **Stateless** | ✅ Yes | ✅ Yes |
| **Sends credentials** | Every request | Only during login |
| **Token expiration** | ❌ No | ✅ Yes (exp claim) |
| **Complexity** | Very simple | More complex |
| **Best for** | Internal tools, admin panels | Public APIs, mobile apps |
| **HTTPS required** | ✅ Critical | ✅ Recommended |
| **Browser support** | ✅ Native | ⚠️ Requires JavaScript |

Use Basic Auth for:
- Internal admin dashboards
- Development/staging environments
- Simple authentication needs
- Legacy system compatibility

Use JWT for:
- Public-facing APIs
- Mobile applications
- Token expiration requirements
- Stateless microservices

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
