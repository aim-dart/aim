# aim_server_testing

A comprehensive testing utility package for the Aim framework. Designed to make testing Aim applications concise and readable.

## Features

- 🧪 **TestClient**: Test Aim applications without starting an actual HTTP server
- 🔨 **TestRequestBuilder**: Easily build test requests with a fluent API
- ✅ **Custom Matchers**: Convenient matchers for response validation
- 🎯 **Response Helpers**: Rich status code helpers and body caching

## Installation

Add to your `pubspec.yaml`:

```yaml
dev_dependencies:
  aim_server_testing: ^0.1.0
  test: ^1.25.6
```

## Usage

### TestClient

Use `TestClient` to test Aim applications without starting an actual HTTP server.

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  test('GET /users/:id returns user data', () async {
    // Create Aim application
    final app = Aim()
      ..get('/users/:id', (c) async {
        final id = c.param('id');
        return c.json({'id': id, 'name': 'Alice'});
      });

    // Create TestClient
    final client = TestClient(app);

    // Send request
    final response = await client.get('/users/123');

    // Validate response
    expect(response, isOk());
    expect(response, hasStatus(200));

    final json = await response.bodyAsJson();
    expect(json['id'], equals('123'));
    expect(json['name'], equals('Alice'));
  });
}
```

### TestRequestBuilder

Use `TestRequestBuilder` to easily build complex requests.

```dart
final request = TestRequestBuilder()
    .post('/api/users')
    .header('Authorization', 'Bearer token123')
    .header('Content-Type', 'application/json')
    .json({'name': 'Bob', 'email': 'bob@example.com'})
    .build();
```

### Custom Matchers

Convenient matchers are available for response validation.

```dart
test('POST /users creates a new user', () async {
  final app = Aim()
    ..post('/users', (c) async {
      final data = await c.req.json();
      return c.json({'id': '1', 'name': data['name']}, statusCode: 201);
    });

  final client = TestClient(app);
  final response = await client.post(
    '/users',
    body: {'name': 'Charlie'},
  );

  // Status code matchers
  expect(response, isCreated());
  expect(response, hasStatus(201));

  // Success response matcher
  expect(response, isSuccessful());

  // Header matcher
  expect(response, hasHeader('content-type', 'application/json'));

  // JSON body validation
  final json = await response.bodyAsJson();
  expect(json['name'], equals('Charlie'));
});
```

#### Available Matchers

**General Matchers:**
- `hasStatus(int statusCode)` - Validates status code
- `hasHeader(String name, String value)` - Validates headers
- `isSuccessful()` - Validates 2xx status codes
- `isClientError()` - Validates 4xx status codes
- `isServerError()` - Validates 5xx status codes

**Specific Status Code Matchers:**
- `isOk()` - 200 OK
- `isCreated()` - 201 Created
- `isNoContent()` - 204 No Content
- `isBadRequest()` - 400 Bad Request
- `isUnauthorized()` - 401 Unauthorized
- `isForbidden()` - 403 Forbidden
- `isNotFound()` - 404 Not Found
- `isInternalServerError()` - 500 Internal Server Error

## HTTP Methods

`TestClient` supports the following HTTP methods:

- `get(path, {headers, query})`
- `post(path, {headers, body})`
- `put(path, {headers, body})`
- `delete(path, {headers})`
- `patch(path, {headers, body})`
- `head(path, {headers})`
- `options(path, {headers})`

## Response Helpers

The `TestResponse` class provides the following helper methods:

**Body Access:**
- `bodyAsString()` - Get response body as a string (cached)
- `bodyAsJson()` - Decode response body as JSON (cached)
- `jsonMap` - Get response body as a JSON Map (cached)
- `jsonList` - Get response body as a JSON List (cached)

**Headers:**
- `header(name)` - Get a specific header

**Status Checks (Properties):**
- `isSuccessful` - Is successful response (2xx)
- `isClientError` - Is client error (4xx)
- `isServerError` - Is server error (5xx)
- `isOk` - Is 200 OK
- `isCreated` - Is 201 Created
- `isNoContent` - Is 204 No Content
- `isBadRequest` - Is 400 Bad Request
- `isUnauthorized` - Is 401 Unauthorized
- `isForbidden` - Is 403 Forbidden
- `isNotFound` - Is 404 Not Found
- `isInternalServerError` - Is 500 Internal Server Error

## Complete Example

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_testing/aim_server_testing.dart';
import 'package:test/test.dart';

void main() {
  group('User API', () {
    late Aim app;
    late TestClient client;

    setUp(() {
      app = Aim()
        ..get('/users/:id', (c) async {
          final id = c.param('id');
          return c.json({'id': id, 'name': 'Alice'});
        })
        ..post('/users', (c) async {
          final data = await c.req.json();
          return c.json(
            {'id': '1', 'name': data['name']},
            statusCode: 201,
          );
        })
        ..delete('/users/:id', (c) async {
          return c.text('', statusCode: 204);
        });

      client = TestClient(app);
    });

    test('GET /users/:id returns user', () async {
      final response = await client.get('/users/123');

      expect(response, isOk());
      expect(response.isSuccessful, isTrue);

      final json = await response.bodyAsJson();
      expect(json['id'], equals('123'));
    });

    test('POST /users creates user', () async {
      final response = await client.post(
        '/users',
        body: {'name': 'Bob'},
      );

      expect(response, isCreated());

      final json = await response.bodyAsJson();
      expect(json['name'], equals('Bob'));
    });

    test('DELETE /users/:id returns 204', () async {
      final response = await client.delete('/users/123');

      expect(response, isNoContent());
      expect(response.isSuccessful, isTrue);
    });
  });
}
```

## License

This package is part of the Aim framework. See the main repository for details.

## Contributing

For bug reports and feature requests, please visit the [GitHub repository](https://github.com/aim-dart/aim).
