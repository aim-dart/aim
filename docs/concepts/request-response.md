# Request & Response

Learn how to handle HTTP requests and generate responses in Aim.

## Request Object

Access request information through `c.req`:

### Method and Path

```dart
app.all('/*', (c) async {
  final method = c.req.method;  // GET, POST, etc.
  final path = c.req.path;      // /users/123

  return c.json({
    'method': method,
    'path': path,
  });
});
```

### Headers

```dart
app.get('/headers', (c) async {
  final headers = c.req.headers;  // Map<String, String>
  final userAgent = c.req.headers['user-agent'];
  final auth = c.req.headers['authorization'];

  return c.json({
    'userAgent': userAgent,
    'auth': auth,
  });
});
```

### Query Parameters

```dart
app.get('/search', (c) async {
  final queries = c.req.queries;  // Map<String, List<String>>
  final q = c.req.queries['q']?.first;
  final page = c.req.queries['page']?.first ?? '1';

  return c.json({
    'query': q,
    'page': int.parse(page),
  });
});
```

Example: `GET /search?q=dart&page=2`

### Request Body

#### JSON Body

```dart
app.post('/users', (c) async {
  final body = await c.req.json();  // Map<String, dynamic>
  final name = body['name'];
  final email = body['email'];

  return c.json({
    'created': {
      'name': name,
      'email': email,
    },
  }, statusCode: 201);
});
```

#### Raw Body

```dart
app.post('/webhook', (c) async {
  final raw = await c.req.raw();  // List<int>
  final text = utf8.decode(raw);

  return c.text('Received ${raw.length} bytes');
});
```

#### Form Data

Use the `aim_server_form` middleware:

```dart
import 'package:aim_server_form/aim_server_form.dart';

final app = Aim<FormEnv>(
  envFactory: () => FormEnv(),
);

app.use(form());

app.post('/login', (c) async {
  final username = c.variables.formData['username'];
  final password = c.variables.formData['password'];

  return c.json({'username': username});
});
```

## Response Methods

### JSON Response

```dart
app.get('/api/users', (c) async {
  return c.json({
    'users': [
      {'id': 1, 'name': 'Alice'},
      {'id': 2, 'name': 'Bob'},
    ],
  });
});

// With status code
app.post('/users', (c) async {
  return c.json({'created': true}, statusCode: 201);
});
```

### Text Response

```dart
app.get('/hello', (c) async {
  return c.text('Hello, World!');
});

// With status code
app.get('/not-found', (c) async {
  return c.text('Not Found', statusCode: 404);
});
```

### HTML Response

```dart
app.get('/page', (c) async {
  return c.html('''
    <!DOCTYPE html>
    <html>
      <head><title>My Page</title></head>
      <body><h1>Hello!</h1></body>
    </html>
  ''');
});
```

### Binary Response

```dart
import 'dart:io';

app.get('/download', (c) async {
  final file = File('assets/document.pdf');
  final bytes = await file.readAsBytes();

  c.header('Content-Type', 'application/pdf');
  c.header('Content-Disposition', 'attachment; filename="document.pdf"');

  return c.bytes(bytes);
});
```

### Redirect

```dart
app.get('/old-path', (c) async {
  return c.redirect('/new-path');
});

// With status code
app.get('/temp-redirect', (c) async {
  return c.redirect('/new-path', statusCode: 302);
});
```

### Stream Response

```dart
app.get('/stream', (c) async {
  final stream = Stream.periodic(
    Duration(seconds: 1),
    (count) => 'Event $count\n',
  ).take(10);

  return c.stream(stream);
});
```

For Server-Sent Events, use the `aim_server_sse` package. See [SSE middleware](/middleware/sse).

## Response Headers

Set headers before sending the response:

```dart
app.get('/api', (c) async {
  c.header('X-API-Version', '1.0');
  c.header('X-Request-ID', generateId());
  c.header('Cache-Control', 'no-cache');

  return c.json({'data': 'value'});
});
```

## Common Patterns

### Content Negotiation

```dart
app.get('/data', (c) async {
  final accept = c.req.headers['accept'];

  if (accept?.contains('application/json') ?? false) {
    return c.json({'message': 'JSON response'});
  }

  return c.text('Text response');
});
```

### File Download

```dart
app.get('/export', (c) async {
  final data = generateCSV();

  c.header('Content-Type', 'text/csv');
  c.header('Content-Disposition', 'attachment; filename="export.csv"');

  return c.text(data);
});
```

### CORS Headers

```dart
app.get('/api', (c) async {
  c.header('Access-Control-Allow-Origin', '*');
  c.header('Access-Control-Allow-Methods', 'GET, POST');

  return c.json({'data': 'value'});
});
```

Or use the [CORS middleware](/middleware/cors) for full CORS support.

### Cache Control

```dart
app.get('/static', (c) async {
  c.header('Cache-Control', 'public, max-age=31536000');
  return c.text('Cached content');
});
```

## Best Practices

1. **Set headers before response**
   ```dart
   // ✅ Good
   c.header('X-Version', '1.0');
   return c.json({'data': 'value'});

   // ❌ Bad - Headers after response won't work
   final response = c.json({'data': 'value'});
   c.header('X-Version', '1.0');
   return response;
   ```

2. **Validate request data**
   ```dart
   app.post('/users', (c) async {
     final body = await c.req.json();

     if (body['email'] == null) {
       return c.json({'error': 'Email required'}, statusCode: 400);
     }

     // Process request...
   });
   ```

3. **Use appropriate status codes**
   ```dart
   // 201 for creation
   return c.json({'created': true}, statusCode: 201);

   // 400 for client errors
   return c.json({'error': 'Bad request'}, statusCode: 400);

   // 404 for not found
   return c.json({'error': 'Not found'}, statusCode: 404);

   // 500 for server errors
   return c.json({'error': 'Internal error'}, statusCode: 500);
   ```

4. **Handle errors gracefully**
   ```dart
   app.post('/api', (c) async {
     try {
       final body = await c.req.json();
       // Process...
       return c.json({'success': true});
     } catch (e) {
       return c.json({'error': 'Invalid JSON'}, statusCode: 400);
     }
   });
   ```

## Next Steps

- Learn about [Context](/concepts/context) for the full API
- Explore [Middleware](/concepts/middleware) for request processing
- Check out [Form](/middleware/form) and [Multipart](/middleware/multipart) for file uploads
