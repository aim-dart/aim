# Form Data

Parse `application/x-www-form-urlencoded` form data.

## Installation

```bash
dart pub add aim_server_form
```

## Quick Start

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_form/aim_server_form.dart';

void main() async {
  final app = Aim<FormEnv>(
    envFactory: () => FormEnv(),
  );

  app.use(form());

  app.post('/login', (c) async {
    final username = c.variables.formData['username'];
    final password = c.variables.formData['password'];

    return c.json({
      'username': username,
      'password': password,
    });
  });

  await app.serve(port: 8080);
}
```

## Form Data

Access parsed form data through `c.variables.formData`:

```dart
app.post('/submit', (c) async {
  final formData = c.variables.formData;

  final name = formData['name'];
  final email = formData['email'];
  final message = formData['message'];

  return c.json({
    'name': name,
    'email': email,
    'message': message,
  });
});
```

## Complete Example

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_form/aim_server_form.dart';

void main() async {
  final app = Aim<FormEnv>(
    envFactory: () => FormEnv(),
  );

  app.use(form());

  // Login form
  app.get('/login', (c) async {
    return c.html('''
      <!DOCTYPE html>
      <html>
        <body>
          <form method="POST" action="/login">
            <input type="text" name="username" placeholder="Username">
            <input type="password" name="password" placeholder="Password">
            <button type="submit">Login</button>
          </form>
        </body>
      </html>
    ''');
  });

  // Handle login
  app.post('/login', (c) async {
    final username = c.variables.formData['username'];
    final password = c.variables.formData['password'];

    // Validate credentials...
    if (username == 'admin' && password == 'password') {
      return c.html('<h1>Welcome, $username!</h1>');
    }

    return c.html('<h1>Invalid credentials</h1>', statusCode: 401);
  });

  // Contact form
  app.post('/contact', (c) async {
    final name = c.variables.formData['name'];
    final email = c.variables.formData['email'];
    final message = c.variables.formData['message'];

    // Process form...
    print('Contact from $name ($email): $message');

    return c.json({
      'status': 'success',
      'message': 'Thank you for your message!',
    });
  });

  await app.serve(port: 8080);
  print('Server running on http://localhost:8080');
}
```

## HTML Form Example

```html
<form method="POST" action="/submit">
  <input type="text" name="username">
  <input type="email" name="email">
  <textarea name="message"></textarea>
  <button type="submit">Submit</button>
</form>
```

## Testing with curl

```bash
curl -X POST http://localhost:8080/login \
  -d "username=admin&password=secret"
```

## Content Type

The middleware only processes requests with:

```
Content-Type: application/x-www-form-urlencoded
```

For file uploads, use the [Multipart middleware](/middleware/multipart) instead.

## Next Steps

- Learn about [Multipart](/middleware/multipart) for file uploads
- Explore [Cookie](/middleware/cookie) for session management
- Read about [Request handling](/guide/context#request-body)
