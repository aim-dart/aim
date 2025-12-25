import 'dart:convert';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_testing/src/request_builder.dart';

/// A client for sending test requests to Aim applications.
///
/// Obtains responses by directly calling Aim application handlers
/// without starting an actual HTTP server.
///
/// Example usage:
/// ```dart
/// final app = Aim()
///   ..get('/users/:id', (c) => c.json({'id': c.param('id')}));
///
/// final client = TestClient(app);
/// final response = await client.get('/users/123');
///
/// expect(response.statusCode, equals(200));
/// expect(response.bodyAsJson()['id'], equals('123'));
/// ```
class TestClient<E extends Env> {
  final Aim<E> _app;

  /// Creates a new TestClient instance.
  ///
  /// [app] is the Aim application to test.
  TestClient(this._app);

  /// Sends a GET request.
  Future<TestResponse> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    return _sendRequest(
      TestRequestBuilder()
          .get(path)
          .headers(headers ?? {})
          .queries(query ?? {}),
    );
  }

  /// Sends a POST request.
  Future<TestResponse> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final builder = TestRequestBuilder().post(path).headers(headers ?? {});

    if (body != null) {
      if (body is Map<String, dynamic>) {
        builder.json(body);
      } else if (body is String) {
        builder.text(body);
      }
    }

    return _sendRequest(builder);
  }

  /// Sends a PUT request.
  Future<TestResponse> put(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final builder = TestRequestBuilder().put(path).headers(headers ?? {});

    if (body != null) {
      if (body is Map<String, dynamic>) {
        builder.json(body);
      } else if (body is String) {
        builder.text(body);
      }
    }

    return _sendRequest(builder);
  }

  /// Sends a DELETE request.
  Future<TestResponse> delete(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      TestRequestBuilder().delete(path).headers(headers ?? {}),
    );
  }

  /// Sends a PATCH request.
  Future<TestResponse> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final builder = TestRequestBuilder().patch(path).headers(headers ?? {});

    if (body != null) {
      if (body is Map<String, dynamic>) {
        builder.json(body);
      } else if (body is String) {
        builder.text(body);
      }
    }

    return _sendRequest(builder);
  }

  /// Sends a HEAD request.
  Future<TestResponse> head(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      TestRequestBuilder().head(path).headers(headers ?? {}),
    );
  }

  /// Sends an OPTIONS request.
  Future<TestResponse> options(
    String path, {
    Map<String, String>? headers,
  }) async {
    return _sendRequest(
      TestRequestBuilder().options(path).headers(headers ?? {}),
    );
  }

  /// Sends a request using TestRequestBuilder.
  Future<TestResponse> _sendRequest(TestRequestBuilder builder) async {
    final request = builder.build();
    final response = await _handleRequest(request);
    return TestResponse(response);
  }

  /// Handles a request and returns a response.
  ///
  /// Simply delegates to the Aim application's handle() method.
  Future<Response> _handleRequest(Request request) async {
    return await _app.handle(request);
  }
}

/// A wrapper class for test responses.
///
/// Wraps a Response object and provides convenient helper methods for testing.
class TestResponse {
  final Response _response;
  String? _cachedBody; // Cache for body (Stream can only be read once)

  /// The original Response object.
  Response get response => _response;

  /// The HTTP status code.
  int get statusCode => _response.statusCode;

  /// The response headers.
  Map<String, String> get headers => _response.headers;

  TestResponse(this._response);

  /// Gets the response body as a String.
  ///
  /// This method caches the body after first read.
  Future<String> bodyAsString() async {
    _cachedBody ??= await _response.readAsString();
    return _cachedBody!;
  }

  /// Decodes and gets the response body as JSON.
  ///
  /// This method caches the body after first read.
  Future<Map<String, dynamic>> bodyAsJson() async {
    final text = await bodyAsString(); // Use cached version
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Gets the response body as a JSON Map.
  ///
  /// This method caches the body after first read.
  /// Alias for bodyAsJson() for consistency with jsonList.
  Future<Map<String, dynamic>> get jsonMap async {
    return await bodyAsJson();
  }

  /// Gets the response body as a JSON List.
  ///
  /// This method caches the body after first read.
  /// Throws if the body is not a valid JSON array.
  Future<List<dynamic>> get jsonList async {
    _cachedBody ??= await _response.readAsString();
    final decoded = jsonDecode(_cachedBody!);
    if (decoded is! List) {
      throw FormatException('Response body is not a JSON array');
    }
    return decoded;
  }

  /// Gets the specified header.
  String? header(String name) {
    return _response.headers[name];
  }

  /// Determines if the response is successful (2xx).
  bool get isSuccessful => statusCode >= 200 && statusCode < 300;

  /// Determines if the response is a client error (4xx).
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  /// Determines if the response is a server error (5xx).
  bool get isServerError => statusCode >= 500 && statusCode < 600;

  /// Returns true if status code is 200 OK.
  bool get isOk => statusCode == 200;

  /// Returns true if status code is 201 Created.
  bool get isCreated => statusCode == 201;

  /// Returns true if status code is 204 No Content.
  bool get isNoContent => statusCode == 204;

  /// Returns true if status code is 400 Bad Request.
  bool get isBadRequest => statusCode == 400;

  /// Returns true if status code is 401 Unauthorized.
  bool get isUnauthorized => statusCode == 401;

  /// Returns true if status code is 403 Forbidden.
  bool get isForbidden => statusCode == 403;

  /// Returns true if status code is 404 Not Found.
  bool get isNotFound => statusCode == 404;

  /// Returns true if status code is 500 Internal Server Error.
  bool get isInternalServerError => statusCode == 500;
}
