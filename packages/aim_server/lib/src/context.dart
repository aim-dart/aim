import 'package:aim_server/src/env.dart';
import 'package:aim_server/src/request.dart';
import 'package:aim_server/src/response.dart';

/// Context provides a simple API for handling HTTP requests and responses.
///
/// Inspired by Hono's context API, this class offers convenient methods
/// for creating responses and accessing request data.
///
/// The type parameter [E] allows you to define type-safe context variables.
class Context<E extends Env> {
  /// The HTTP request.
  final Request request;

  /// Type-safe variables for this context.
  ///
  /// Users can define their own [Env] subclass to add custom variables
  /// with full type safety.
  late final E variables;

  /// Internal map for backward compatibility with set/get methods.
  final Map<String, Object> _variables = {};

  /// Additional headers to be added to all responses.
  final Map<String, String> _responseHeaders = {};

  /// Gets the response headers added by middleware.
  ///
  /// This is used internally to merge headers added in after phase.
  Map<String, String> get responseHeaders => _responseHeaders;

  /// Early response set by middleware (e.g., for CORS preflight).
  Response? _response;

  Context(this.request, this.variables);

  /// Whether a response has been finalized.
  ///
  /// When true, the middleware chain will stop and return the finalized response.
  bool get finalized => _response != null;

  /// Gets the finalized response, if any.
  Response? get response => _response;

  // Request accessors

  /// Shorthand for accessing the request.
  ///
  /// This provides a more concise API similar to Hono:
  /// ```dart
  /// final data = await c.req.json();
  /// final text = await c.req.text();
  /// ```
  Request get req => request;

  /// The HTTP method (GET, POST, etc.).
  String get method => request.method;

  /// The request path.
  String get path => request.path;

  /// The request headers.
  Map<String, String> get headers => request.headers;

  /// The query parameters.
  Map<String, String> get query => request.queryParameters;

  // Path and query parameters

  /// Gets a path parameter by name.
  ///
  /// Path parameters are defined in the route pattern using colons:
  /// ```dart
  /// app.get('/users/:id', (c) {
  ///   final id = c.param('id');
  ///   return c.json({'userId': id});
  /// });
  /// ```
  String param(String name) {
    final value = get<String>('param:$name');
    if (value == null) {
      throw ArgumentError('Path parameter "$name" not found');
    }
    return value;
  }

  /// Gets a query parameter by name with an optional default value.
  ///
  /// Example:
  /// ```dart
  /// // GET /search?q=dart&page=2
  /// app.get('/search', (c) {
  ///   final query = c.queryParam('q');
  ///   final page = c.queryParam('page', '1');
  ///   return c.json({'query': query, 'page': page});
  /// });
  /// ```
  String queryParam(String name, [String? defaultValue]) {
    final value = query[name];
    if (value == null && defaultValue == null) {
      throw ArgumentError('Query parameter "$name" not found');
    }
    return value ?? defaultValue!;
  }

  // Context variables

  /// Sets a variable in the context.
  ///
  /// This can be used to pass data between middleware and handlers.
  void set(String key, Object value) {
    _variables[key] = value;
  }

  /// Gets a variable from the context.
  ///
  /// Returns null if the key doesn't exist.
  T? get<T>(String key) {
    return _variables[key] as T?;
  }

  // Response headers

  /// Sets a response header.
  ///
  /// This header will be added to the response when it's created.
  /// Useful for middleware that needs to add headers (e.g., CORS).
  ///
  /// Example:
  /// ```dart
  /// app.use((c, next) async {
  ///   c.header('X-Custom-Header', 'value');
  ///   await next();
  /// });
  /// ```
  void header(String key, String value) {
    _responseHeaders[key] = value;
  }

  // Response methods

  /// Returns a JSON response.
  ///
  /// The [body] will be encoded as JSON and the Content-Type header
  /// will be set to "application/json".
  ///
  /// Example:
  /// ```dart
  /// app.get('/api/user', (c) {
  ///   return c.json({'name': 'Alice', 'age': 30});
  /// });
  /// ```
  Response json(
    Map<String, dynamic> body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return _finalizeResponse(
      Response.json(body: body, statusCode: statusCode, headers: headers),
    );
  }

  /// Returns a plain text response.
  ///
  /// The Content-Type header will be set to "text/plain; charset=utf-8".
  ///
  /// Example:
  /// ```dart
  /// app.get('/hello', (c) {
  ///   return c.text('Hello, World!');
  /// });
  /// ```
  Response text(
    String text, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return _finalizeResponse(
      Response.text(text, statusCode: statusCode, headers: headers),
    );
  }

  /// Returns an HTML response.
  ///
  /// The Content-Type header will be set to "text/html; charset=utf-8".
  ///
  /// Example:
  /// ```dart
  /// app.get('/', (c) {
  ///   return c.html('<h1>Hello, World!</h1>');
  /// });
  /// ```
  Response html(
    String html, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final mergedHeaders = {
      'content-type': 'text/html; charset=utf-8',
      ...?headers,
    };
    return _finalizeResponse(
      Response.text(html, statusCode: statusCode, headers: mergedHeaders),
    );
  }

  /// Returns a 404 Not Found response.
  Response notFound([String? message]) {
    return _finalizeResponse(Response.notFound(body: message));
  }

  /// Returns a redirect response.
  ///
  /// [location] is the URL to redirect to.
  /// [statusCode] defaults to 302 (Found) but can be customized.
  ///
  /// Example:
  /// ```dart
  /// app.get('/old-page', (c) {
  ///   return c.redirect('/new-page');  // 302
  /// });
  ///
  /// app.get('/moved', (c) {
  ///   return c.redirect('/permanent-url', 301);  // 301
  /// });
  /// ```
  Response redirect(String location, [int statusCode = 302]) {
    return _finalizeResponse(Response.redirect(location, statusCode));
  }

  /// Returns a response with a stream body.
  ///
  /// Useful for serving files or other streaming content.
  ///
  /// Example:
  /// ```dart
  /// app.get('/download', (c) {
  ///   final file = File('large-file.zip');
  ///   return c.stream(
  ///     file.openRead(),
  ///     headers: {
  ///       'content-type': 'application/zip',
  ///       'content-disposition': 'attachment; filename="file.zip"',
  ///     },
  ///   );
  /// });
  /// ```
  Response stream(
    Stream<List<int>> body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return _finalizeResponse(
      Response.stream(body, statusCode: statusCode, headers: headers),
    );
  }

  /// Internal method to finalize a response that was created outside of context methods.
  ///
  /// This is used by the framework when a handler returns a Response directly
  /// instead of using c.json(), c.text(), etc.
  void internalFinalizeResponse(Response response) {
    if (_response != null) {
      return; // Already finalized
    }
    _response = response;
  }

  /// Finalizes the response by adding custom headers.
  Response _finalizeResponse(Response response) {
    final headers = Map<String, String>.from(response.headers);

    // Add custom response headers
    headers.addAll(_responseHeaders);

    // Modify the existing response headers directly
    response.headers.addAll(headers);

    // Store the finalized response
    _response = response;

    return response;
  }
}
