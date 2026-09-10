import 'dart:convert';

import 'package:aim_core/src/body.dart';
import 'package:aim_core/src/message.dart';

/// An HTTP request to be processed by an Aim application.
class Request with MessageMixin {
  /// The HTTP request method, such as "GET" or "POST".
  final String method;

  /// The original [Uri] for the request.
  final Uri uri;

  @override
  final Map<String, String> headers;

  @override
  final Map<String, Object> context;

  @override
  final Body body;

  /// The raw platform-specific request object, if available.
  ///
  /// On the Dart VM (`aim_server`) this is an `HttpRequest`. On other
  /// runtimes it is whatever the adapter received. Adapters provide typed
  /// accessors; core code must not depend on its concrete type.
  final Object? raw;

  /// Creates a new [Request].
  ///
  /// [bodyContent] is the request body. It may be either a [String], a `List<int>`, a
  /// `Stream<List<int>>`, or `null` to indicate no body. If it's a [String],
  /// [encoding] is used to encode it to a `Stream<List<int>>`. The default
  /// encoding is UTF-8.
  ///
  /// [raw] is the platform-specific request object supplied by the runtime
  /// adapter (an `HttpRequest` on the Dart VM).
  Request(
    this.method,
    this.uri, {
    Object? bodyContent,
    Map<String, String>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
    this.raw,
  }) : body = Body(bodyContent, encoding),
       headers = headers ?? {},
       context = context ?? {} {
    if (method.isEmpty) {
      throw ArgumentError.value(method, 'method', 'cannot be empty.');
    }
  }

  /// The URL path of the request.
  String get path => uri.path;

  /// The query parameters of the request.
  Map<String, String> get queryParameters => uri.queryParameters;

  /// Parses the request body as JSON.
  ///
  /// Returns a [Future] that completes with the parsed JSON object.
  /// Throws [FormatException] if the body is not valid JSON.
  ///
  /// Example:
  /// ```dart
  /// app.post('/api/users', (c) async {
  ///   final data = await c.req.json();
  ///   final name = data['name'];
  ///   return c.json({'message': 'Hello, $name'});
  /// });
  /// ```
  Future<Map<String, dynamic>> json() async {
    final text = await readAsString();
    return jsonDecode(text) as Map<String, dynamic>;
  }

  /// Returns the request body as a string.
  ///
  /// Example:
  /// ```dart
  /// app.post('/echo', (c) async {
  ///   final body = await c.req.text();
  ///   return c.text(body);
  /// });
  /// ```
  Future<String> text() async {
    return readAsString();
  }
}
