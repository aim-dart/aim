# aim_form

Form data parsing for the Aim server framework.

## Overview

`aim_form` provides support for parsing `application/x-www-form-urlencoded` form data in Aim server applications. This package offers a simple, type-safe API for accessing form fields with support for default values and validation.

## Features

- 📝 **Simple Form API** - Easy `formData()` method on `Request`
- 🔍 **Type-safe Access** - Full Dart type safety with nullable return types
- 🌐 **URL Decoding** - Automatic URL decoding of form values
- ✅ **Content-Type Validation** - Ensures correct Content-Type header
- 🎯 **Default Values** - Support for default values with `get()` method
- 🔒 **Immutable Data** - Thread-safe, immutable form data
- 🌏 **Unicode Support** - Full support for Unicode characters

## Installation

Add `aim_form` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: <latest_version>
  aim_form: <latest_version>
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Form Parsing

Parse form data from a POST request:

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_form/aim_server_form.dart';

void main() async {
  final app = Aim();

  app.post('/login', (c) async {
    final form = await c.req.formData();

    final username = form['username'];  // String?
    final password = form['password'];  // String?

    return c.json({'user': username});
  });

  await app.serve(host: InternetAddress.anyIPv4, port: 8080);
}
```

### Login Form

Handle a login form with validation:

```dart
app.post('/login', (c) async {
  final form = await c.req.formData();

  final username = form['username'];
  final password = form['password'];
  final remember = form.get('remember', 'off');

  // Validation
  if (username == null || username.isEmpty) {
    return c.json({'error': 'Username is required'}, statusCode: 400);
  }

  if (password == null || password.isEmpty) {
    return c.json({'error': 'Password is required'}, statusCode: 400);
  }

  // Authentication logic...
  return c.json({
    'success': true,
    'user': username,
    'remember': remember,
  });
});
```

### Search Form

Handle a search form with filters:

```dart
app.post('/search', (c) async {
  final form = await c.req.formData();

  final query = form['q'] ?? '';
  final filter = form.get('filter', 'all');
  final sort = form.get('sort', 'relevance');

  // Search logic...
  return c.json({
    'query': query,
    'filter': filter,
    'sort': sort,
    'results': [],
  });
});
```

### Error Handling

Handle Content-Type errors gracefully:

```dart
app.post('/submit', (c) async {
  try {
    final form = await c.req.formData();

    // Process form data...
    return c.json({'success': true});
  } on FormatException catch (e) {
    return c.json({
      'error': 'Invalid form data',
      'details': e.message,
      'expected': 'application/x-www-form-urlencoded',
    }, statusCode: 400);
  }
});
```

### Complete Example

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_form/aim_server_form.dart';

void main() async {
  final app = Aim();

  // Serve login form
  app.get('/login', (c) {
    return c.html('''
      <!DOCTYPE html>
      <html>
      <head><title>Login</title></head>
      <body>
        <form action="/login" method="POST">
          <input type="text" name="username" placeholder="Username" required>
          <input type="password" name="password" placeholder="Password" required>
          <label>
            <input type="checkbox" name="remember" value="on">
            Remember me
          </label>
          <button type="submit">Login</button>
        </form>
      </body>
      </html>
    ''');
  });

  // Handle login submission
  app.post('/login', (c) async {
    try {
      final form = await c.req.formData();

      final username = form['username'];
      final password = form['password'];
      final remember = form.get('remember', 'off');

      // Validation
      if (username == null || username.isEmpty) {
        return c.json({'error': 'Username is required'}, statusCode: 400);
      }

      // Authentication (mock)
      if (username == 'alice' && password == 'secret') {
        return c.json({
          'success': true,
          'user': username,
          'remember': remember == 'on',
        });
      } else {
        return c.json({
          'success': false,
          'error': 'Invalid credentials',
        }, statusCode: 401);
      }
    } on FormatException catch (e) {
      return c.json({
        'error': 'Invalid Content-Type',
        'expected': 'application/x-www-form-urlencoded',
        'details': e.message,
      }, statusCode: 400);
    }
  });

  await app.serve(host: InternetAddress.anyIPv4, port: 8080);
  print('Server running on http://localhost:8080');
}
```

## API Reference

### `formData()`

Extension method on `Request` to parse form data.

```dart
Future<FormData> formData()
```

**Throws:**
- `FormatException` if Content-Type is not `application/x-www-form-urlencoded`

**Returns:**
- `FormData` instance containing parsed form fields

**Example:**
```dart
final form = await c.req.formData();
```

### `FormData`

Immutable container for parsed form data.

#### `operator [](String key)`

Gets the value for the given key.

```dart
String? operator [](String key)
```

**Returns:**
- The value if it exists, otherwise `null`

**Example:**
```dart
final username = form['username'];  // String?
```

#### `get(String key, [String? defaultValue])`

Gets the value for the given key with an optional default.

```dart
String? get(String key, [String? defaultValue])
```

**Returns:**
- The value if it exists, otherwise `defaultValue`

**Example:**
```dart
final theme = form.get('theme', 'light');  // String?
final remember = form.get('remember', 'off');
```

#### `has(String key)`

Checks if the form data contains the given key.

```dart
bool has(String key)
```

**Returns:**
- `true` if the key exists, otherwise `false`

**Example:**
```dart
if (form.has('email')) {
  print('Email provided');
}
```

#### `keys`

Returns all keys in the form data.

```dart
Iterable<String> get keys
```

**Example:**
```dart
for (final key in form.keys) {
  print('$key: ${form[key]}');
}
```

#### `values`

Returns all values in the form data.

```dart
Iterable<String> get values
```

#### `entries`

Returns all entries in the form data.

```dart
Iterable<MapEntry<String, String>> get entries
```

#### `toMap()`

Converts the form data to an unmodifiable Map.

```dart
Map<String, String> toMap()
```

**Example:**
```dart
final map = form.toMap();
print(map);  // {username: alice, age: 30}
```

## Security Best Practices

### 1. CSRF Token Validation

Always validate CSRF tokens in form submissions:

```dart
app.post('/submit', (c) async {
  final form = await c.req.formData();
  final token = form['csrf_token'];

  if (token != expectedToken) {
    return c.json({'error': 'Invalid CSRF token'}, statusCode: 403);
  }

  // Process form...
});
```

### 2. Input Validation

Always validate user input:

```dart
app.post('/register', (c) async {
  final form = await c.req.formData();

  final email = form['email'];
  if (email == null || !isValidEmail(email)) {
    return c.json({'error': 'Invalid email'}, statusCode: 400);
  }

  // Process registration...
});
```

### 3. XSS Prevention

Always escape HTML when displaying user input:

```dart
import 'package:html_escape/html_escape.dart';

app.post('/comment', (c) async {
  final form = await c.req.formData();
  final comment = HtmlEscape().convert(form['comment'] ?? '');

  // Store escaped comment...
});
```

### 4. Rate Limiting

Implement rate limiting for form submissions:

```dart
final rateLimiter = RateLimiter(maxRequests: 5, window: Duration(minutes: 1));

app.use((c, next) async {
  if (c.path == '/login' && c.method == 'POST') {
    if (!rateLimiter.allow(c.headers['x-forwarded-for'] ?? '')) {
      return c.json({'error': 'Too many requests'}, statusCode: 429);
    }
  }
  await next();
});
```

### 5. Content-Length Limits

Limit the size of form data to prevent DoS attacks:

```dart
app.use((c, next) async {
  final contentLength = int.tryParse(c.headers['content-length'] ?? '0') ?? 0;

  if (contentLength > 1024 * 1024) {  // 1MB limit
    return c.json({'error': 'Request too large'}, statusCode: 413);
  }

  await next();
});
```

## How It Works

The form parsing process:

1. **Content-Type Validation** - Validates that the `Content-Type` header is `application/x-www-form-urlencoded`
2. **Body Reading** - Reads the request body as text using the `text()` method
3. **URL Decoding** - Uses `Uri.splitQueryString()` to parse and decode the form data
4. **Immutable Storage** - Stores the parsed data in an immutable Map

## Limitations

- **Form Type**: This package only supports `application/x-www-form-urlencoded` format
- **File Uploads**: For `multipart/form-data` (file uploads), use a separate package (planned: `aim_multipart`)
- **Duplicate Keys**: When the same key appears multiple times, only the last value is retained (this is the behavior of `Uri.splitQueryString`)
- **Arrays**: Array syntax like `field[]=value1&field[]=value2` is not directly supported

## Examples

See the [example](example/main.dart) directory for a complete working example with:
- Login form
- Search form
- Contact form with Unicode support
- Error handling
- API endpoint returning JSON

Run the example:

```bash
cd packages/aim_form
dart run example/main.dart
```

Then open http://localhost:8080 in your browser.

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
