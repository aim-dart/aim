import 'dart:convert';

import 'package:aim_server/aim_server.dart';

/// A class for easily constructing test Requests using the builder pattern.
///
/// Allows setting HTTP method, path, headers, query parameters, and body
/// using a fluent API.
///
/// Example usage:
/// ```dart
/// final request = TestRequestBuilder()
///     .get('/users/123')
///     .header('Authorization', 'Bearer token')
///     .query('format', 'json')
///     .build();
/// ```
class TestRequestBuilder {
  String _method = 'GET';
  String _path = '/';
  final Map<String, String> _headers = {};
  final Map<String, String> _queryParams = {};
  Object? _bodyContent;
  Encoding? _encoding;

  /// Sets the HTTP method to GET.
  TestRequestBuilder get([String path = '/']) {
    _method = 'GET';
    _path = path;
    return this;
  }

  /// Sets the HTTP method to POST.
  TestRequestBuilder post([String path = '/']) {
    _method = 'POST';
    _path = path;
    return this;
  }

  /// Sets the HTTP method to PUT.
  TestRequestBuilder put([String path = '/']) {
    _method = 'PUT';
    _path = path;
    return this;
  }

  /// Sets the HTTP method to DELETE.
  TestRequestBuilder delete([String path = '/']) {
    _method = 'DELETE';
    _path = path;
    return this;
  }

  /// Sets the HTTP method to PATCH.
  TestRequestBuilder patch([String path = '/']) {
    _method = 'PATCH';
    _path = path;
    return this;
  }

  /// Sets the HTTP method to HEAD.
  TestRequestBuilder head([String path = '/']) {
    _method = 'HEAD';
    _path = path;
    return this;
  }

  /// Sets the HTTP method to OPTIONS.
  TestRequestBuilder options([String path = '/']) {
    _method = 'OPTIONS';
    _path = path;
    return this;
  }

  /// Adds a request header.
  ///
  /// If a header with the same name already exists, it will be overwritten.
  TestRequestBuilder header(String name, String value) {
    _headers[name] = value;
    return this;
  }

  /// Adds multiple request headers at once.
  TestRequestBuilder headers(Map<String, String> headers) {
    _headers.addAll(headers);
    return this;
  }

  /// Adds a query parameter.
  TestRequestBuilder query(String name, String value) {
    _queryParams[name] = value;
    return this;
  }

  /// Adds multiple query parameters at once.
  TestRequestBuilder queries(Map<String, String> params) {
    _queryParams.addAll(params);
    return this;
  }

  /// Sets the request body as text.
  ///
  /// If the Content-Type header is not set,
  /// it will be automatically set to `text/plain; charset=utf-8`.
  TestRequestBuilder text(String body, {Encoding? encoding}) {
    _bodyContent = body;
    _encoding = encoding;
    if (!_headers.containsKey('content-type')) {
      _headers['content-type'] = 'text/plain; charset=utf-8';
    }
    return this;
  }

  /// Sets the request body as JSON.
  ///
  /// The [body] is provided as a Map and is automatically encoded to a JSON string.
  /// If the Content-Type header is not set,
  /// it will be automatically set to `application/json`.
  TestRequestBuilder json(Map<String, dynamic> body) {
    _bodyContent = jsonEncode(body);
    if (!_headers.containsKey('content-type')) {
      _headers['content-type'] = 'application/json';
    }
    return this;
  }

  /// Sets the request body as raw bytes.
  TestRequestBuilder bytes(List<int> body) {
    _bodyContent = body;
    return this;
  }

  /// Builds a Request object with the configured settings.
  ///
  /// By default, uses `http://localhost` as the base URL.
  Request build() {
    // Build URI with query parameters
    var uri = Uri.parse('http://localhost$_path');
    if (_queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: _queryParams);
    }

    return Request(
      _method,
      uri,
      headers: Map.from(_headers),
      bodyContent: _bodyContent,
      encoding: _encoding,
    );
  }
}
