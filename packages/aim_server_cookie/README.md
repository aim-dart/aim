# aim_server_cookie

Cookie support for the aim_server framework.

## Overview

`aim_server_cookie` provides secure cookie management for the Aim framework. This package offers an easy-to-use API for setting, deleting, and managing HTTP cookies with support for all standard cookie attributes including HttpOnly, Secure, SameSite, and expiration controls.

## Features

- 🍪 **Simple Cookie API** - Easy `setCookie` and `deleteCookie` methods
- 🔒 **Security Options** - Full support for HttpOnly, Secure, and SameSite attributes
- ⏰ **Expiration Control** - Set expiration with Max-Age or Expires
- 🌐 **Path & Domain** - Control cookie scope with path and domain options
- 🎯 **Type-safe** - Full Dart type safety with `CookieOptions`
- 📦 **Multiple Cookies** - Set multiple cookies in a single response

## Installation

Add `aim_server_cookie` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: <latest_version>
  aim_server_cookie: <latest_version>
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Cookie

Set a simple cookie:

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_cookie/aim_server_cookie.dart';

void main() async {
  final app = Aim();

  app.get('/login', (c) async {
    c.setCookie('user_id', '12345');
    return c.json({'status': 'logged in'});
  });

  await app.serve(host: InternetAddress.anyIPv4, port: 8080);
}
```

### Secure Session Cookie

Set a secure session cookie with HttpOnly and SameSite:

```dart
app.get('/login', (c) async {
  c.setCookie('session_id', 'abc123xyz', options: CookieOptions(
    httpOnly: true,
    secure: true,
    sameSite: SameSite.strict,
    path: '/',
  ));
  return c.json({'status': 'logged in'});
});
```

### Cookie with Expiration

Set a cookie that expires after a specific duration:

```dart
app.get('/remember', (c) async {
  c.setCookie('remember_token', 'xyz789', options: CookieOptions(
    maxAge: Duration(days: 30),
    path: '/',
    httpOnly: true,
  ));
  return c.json({'status': 'remembered'});
});
```

### Multiple Cookies

Set multiple cookies in a single response:

```dart
app.get('/preferences', (c) async {
  c.setCookie('theme', 'dark', options: CookieOptions(
    path: '/',
    maxAge: Duration(days: 365),
  ));

  c.setCookie('language', 'ja', options: CookieOptions(
    path: '/',
    maxAge: Duration(days: 365),
  ));

  return c.json({'status': 'preferences saved'});
});
```

### Delete Cookie

Delete a cookie by setting its Max-Age to 0:

```dart
app.get('/logout', (c) async {
  c.deleteCookie('session_id', path: '/');
  return c.json({'status': 'logged out'});
});
```

**Important:** When deleting a cookie, you must specify the same `path` and `domain` that were used when setting the cookie.

### Complete Example

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_cookie/aim_server_cookie.dart';

void main() async {
  final app = Aim();

  // Login endpoint - set secure session cookie
  app.post('/login', (c) async {
    final body = await c.req.json();

    // Validate credentials...

    c.setCookie('session_id', 'generated_session_id', options: CookieOptions(
      httpOnly: true,
      secure: true,
      sameSite: SameSite.strict,
      path: '/',
      maxAge: Duration(hours: 24),
    ));

    return c.json({'status': 'success'});
  });

  // Logout endpoint - delete session cookie
  app.post('/logout', (c) async {
    c.deleteCookie('session_id', path: '/');
    return c.json({'status': 'logged out'});
  });

  // Protected endpoint - read cookies
  app.get('/profile', (c) async {
    final cookies = c.headers['cookie'] ?? '';
    // Parse and validate session cookie...

    return c.json({'user': 'data'});
  });

  await app.serve(host: InternetAddress.anyIPv4, port: 8080);
  print('Server running on http://localhost:8080');
}
```

## API Reference

### `setCookie(String name, String value, {CookieOptions? options})`

Sets a cookie in the response.

**Parameters:**
- `name` - Cookie name
- `value` - Cookie value
- `options` (optional) - Cookie configuration options

**Example:**
```dart
c.setCookie('user_id', '12345', options: CookieOptions(
  path: '/',
  maxAge: Duration(days: 7),
));
```

### `deleteCookie(String name, {String? path, String? domain})`

Deletes a cookie by setting its Max-Age to 0.

**Parameters:**
- `name` - Cookie name to delete
- `path` (optional) - Cookie path (must match the path used when setting the cookie)
- `domain` (optional) - Cookie domain (must match the domain used when setting the cookie)

**Example:**
```dart
c.deleteCookie('user_id', path: '/');
```

### `CookieOptions`

Configuration options for cookies.

**Properties:**

- **`path`** (`String?`, default: `null`)
  - The path for which the cookie is valid
  - Example: `'/'`, `'/api'`

- **`domain`** (`String?`, default: `null`)
  - The domain for which the cookie is valid
  - Example: `'example.com'`, `'.example.com'`

- **`maxAge`** (`Duration?`, default: `null`)
  - How long the cookie should be valid
  - Example: `Duration(days: 7)`, `Duration(hours: 1)`

- **`expires`** (`DateTime?`, default: `null`)
  - Absolute expiration date for the cookie
  - Example: `DateTime.now().add(Duration(days: 30))`

- **`secure`** (`bool?`, default: `null`)
  - Whether the cookie should only be sent over HTTPS
  - Set to `true` for production environments

- **`httpOnly`** (`bool?`, default: `null`)
  - Whether the cookie is inaccessible to JavaScript
  - Set to `true` for session cookies to prevent XSS attacks

- **`sameSite`** (`SameSite?`, default: `null`)
  - Controls whether the cookie is sent with cross-site requests
  - Values: `SameSite.strict`, `SameSite.lax`, `SameSite.none`

### `SameSite` Enum

Controls cross-site cookie behavior:

- **`SameSite.strict`** - Cookie is only sent in first-party context
- **`SameSite.lax`** - Cookie is sent with top-level navigations
- **`SameSite.none`** - Cookie is sent in all contexts (requires `Secure` flag)

## Security Best Practices

1. **Use HttpOnly for session cookies** - Prevents XSS attacks
   ```dart
   c.setCookie('session', 'value', options: CookieOptions(httpOnly: true));
   ```

2. **Use Secure in production** - Ensures cookies are only sent over HTTPS
   ```dart
   c.setCookie('session', 'value', options: CookieOptions(secure: true));
   ```

3. **Set SameSite attribute** - Prevents CSRF attacks
   ```dart
   c.setCookie('session', 'value', options: CookieOptions(
     sameSite: SameSite.strict,
   ));
   ```

4. **Specify Path** - Limit cookie scope
   ```dart
   c.setCookie('api_token', 'value', options: CookieOptions(path: '/api'));
   ```

5. **Set expiration** - Don't create permanent cookies unnecessarily
   ```dart
   c.setCookie('temp', 'value', options: CookieOptions(
     maxAge: Duration(hours: 1),
   ));
   ```

## How It Works

The cookie middleware:

1. **Sets cookies** via the `set-cookie` HTTP header
2. **Supports multiple cookies** by concatenating them with newlines
3. **Server-side splitting** automatically splits concatenated cookies into individual `Set-Cookie` headers
4. **Formats attributes** according to HTTP cookie specification (RFC 6265)

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.