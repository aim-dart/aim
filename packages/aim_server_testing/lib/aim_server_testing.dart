/// Testing utilities for the Aim framework.
///
/// This library provides utility classes and helper functions to make
/// testing Aim applications easier without starting an actual HTTP server.
///
/// Main features:
/// - [TestClient]: A test client for sending HTTP requests to Aim applications
/// - [TestRequestBuilder]: A builder for easily constructing requests
/// - Custom matchers: Convenient matchers for validating responses
///
/// Example usage:
/// ```dart
/// import 'package:aim_server/aim_server.dart';
/// import 'package:aim_server_testing/aim_server_testing.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   test('GET /users/:id returns user data', () async {
///     final app = Aim()
///       ..get('/users/:id', (c) async {
///         final id = c.param('id');
///         return c.json({'id': id, 'name': 'Alice'});
///       });
///
///     final client = TestClient(app);
///     final response = await client.get('/users/123');
///
///     expect(response, hasStatus(200));
///     expect(response, isSuccessful());
///
///     final json = await response.bodyAsJson();
///     expect(json['id'], equals('123'));
///     expect(json['name'], equals('Alice'));
///   });
/// }
/// ```
library;

export 'src/matchers.dart';
export 'src/request_builder.dart';
export 'src/test_client.dart';
