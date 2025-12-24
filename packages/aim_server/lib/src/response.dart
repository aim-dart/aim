import 'dart:convert';

import 'package:aim_server/src/body.dart';
import 'package:aim_server/src/message.dart';

/// The response returned by a [Handler].
class Response with MessageMixin {
  /// The HTTP status code of the response.
  final int statusCode;

  @override
  final Map<String, String> headers;

  @override
  final Map<String, Object> context;

  @override
  final Body body;

  /// Constructs an HTTP response with the given [statusCode].
  ///
  /// [statusCode] must be greater than or equal to 100.
  ///
  /// [body] is the response body. It may be either a [String], a `List<int>`, a
  /// `Stream<List<int>>`, or `null` to indicate no body.
  ///
  /// If the body is a [String], [encoding] is used to encode it to a
  /// `Stream<List<int>>`. It defaults to UTF-8.
  ///
  /// This constructor is private. Use factory methods like [Response.json]
  /// or [Response.text], or use the Context API (c.json, c.text, etc.).
  Response._(
      this.statusCode, {
        Object? bodyContent,
        Map<String, String>? headers,
        Encoding? encoding,
        Map<String, Object>? context,
      })  : body = Body(bodyContent, encoding),
        headers = headers ?? {},
        context = context ?? {} {
    if (statusCode < 100) {
      throw ArgumentError('Invalid status code: $statusCode.');
    }
  }

  /// Constructs a 200 OK response with JSON body.
  ///
  /// The [body] will be encoded as JSON and the Content-Type header
  /// will be set to "application/json".
  factory Response.json({
    required Map<String, dynamic> body,
    int statusCode = 200,
    Map<String, String>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) {
    final mergedHeaders = {
      'content-type': 'application/json',
      ...?headers,
    };
    return Response._(
      statusCode,
      bodyContent: jsonEncode(body),
      headers: mergedHeaders,
      encoding: encoding,
      context: context,
    );
  }

  /// Constructs a 200 OK response with plain text body.
  ///
  /// The Content-Type header will be set to "text/plain; charset=utf-8".
  factory Response.text(
      String text, {
        int statusCode = 200,
        Map<String, String>? headers,
        Encoding? encoding,
        Map<String, Object>? context,
      }) {
    final mergedHeaders = {
      'content-type': 'text/plain; charset=utf-8',
      ...?headers,
    };
    return Response._(
      statusCode,
      bodyContent: text,
      headers: mergedHeaders,
      encoding: encoding,
      context: context,
    );
  }

  /// Constructs a 404 Not Found response.
  factory Response.notFound({
    Object? body,
    Map<String, String>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) {
    return Response._(
      404,
      bodyContent: body ?? 'Not Found',
      headers: headers,
      encoding: encoding,
      context: context,
    );
  }

  /// Constructs a 500 Internal Server Error response.
  factory Response.internalServerError({
    Object? body,
    Map<String, String>? headers,
    Encoding? encoding,
    Map<String, Object>? context,
  }) {
    return Response._(
      500,
      bodyContent: body ?? 'Internal Server Error',
      headers: headers,
      encoding: encoding,
      context: context,
    );
  }

  /// Constructs a redirect response.
  ///
  /// [location] is the URL to redirect to.
  /// [statusCode] defaults to 302 (Found) but can be customized:
  /// - 301: Moved Permanently
  /// - 302: Found (default)
  /// - 303: See Other
  /// - 307: Temporary Redirect
  /// - 308: Permanent Redirect
  ///
  /// Example:
  /// ```dart
  /// // Temporary redirect (302)
  /// return Response.redirect('/login');
  ///
  /// // Permanent redirect (301)
  /// return Response.redirect('/new-page', 301);
  /// ```
  factory Response.redirect(String location, [int statusCode = 302]) {
    if (statusCode < 300 || statusCode >= 400) {
      throw ArgumentError(
        'Redirect status code must be 3xx, got $statusCode',
      );
    }

    return Response._(
      statusCode,
      bodyContent: '',
      headers: {'location': location},
    );
  }

  /// Constructs a response with a stream body.
  ///
  /// Useful for serving files or other streaming content.
  ///
  /// Example:
  /// ```dart
  /// final file = File('image.png');
  /// return Response.stream(
  ///   file.openRead(),
  ///   headers: {'content-type': 'image/png'},
  /// );
  /// ```
  factory Response.stream(
      Stream<List<int>> body, {
        int statusCode = 200,
        Map<String, String>? headers,
        Map<String, Object>? context,
      }) {
    return Response._(
      statusCode,
      bodyContent: body,
      headers: headers,
      context: context,
    );
  }
}
