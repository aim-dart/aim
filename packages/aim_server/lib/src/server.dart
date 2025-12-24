import 'dart:io';

import 'package:aim_server/src/context.dart';
import 'package:aim_server/src/env.dart';
import 'package:aim_server/src/request.dart';
import 'package:aim_server/src/response.dart';

/// A function that handles an HTTP request and returns a response.
///
/// Handlers are registered via [Aim.get], [Aim.post], etc.
typedef Handler<E extends Env> = Future<Response> Function(Context<E> c);

/// A function that processes requests in a middleware chain.
///
/// Middleware can modify the context, perform actions before/after the handler,
/// or finalize the response early.
typedef Middleware<E extends Env> =
    Future<void> Function(Context<E> c, Next next);

/// A function that handles errors that occur during request processing.
///
/// Error handlers are registered via [Aim.onError].
typedef ErrorHandler<E extends Env> =
    Future<Response> Function(Object error, Context<E> c);

/// A function that calls the next middleware in the chain.
typedef Next = Future<void> Function();

/// A modern, simple, and fast web framework for Dart.
///
/// Aim provides an intuitive API for building HTTP servers with support for:
/// - Routing with path parameters and wildcards
/// - Middleware
/// - Type-safe context variables
/// - CORS handling
///
/// Example:
/// ```dart
/// final app = Aim();
/// app.get('/hello', (c) async => c.text('Hello, World!'));
/// await app.serve(host: InternetAddress.anyIPv4, port: 8080);
/// ```
class Aim<E extends Env> {
  final List<Route<E>> _routes = [];
  final List<Middleware<E>> _middlewares = [];

  /// Get an unmodifiable list of all registered routes.
  ///
  /// This is useful for generating OpenAPI specifications, documentation, etc.
  List<Route<E>> get routes => List.unmodifiable(_routes);

  /// Handler for 404 Not Found responses
  Handler<E>? _notFoundHandler;

  /// Handler for error responses
  ErrorHandler<E>? _errorHandler;

  /// Factory function to create instances of [E].
  ///
  /// This must be provided by the user when using a custom [Env].
  final E Function() _envFactory;

  /// Creates a new [Aim] instance.
  ///
  /// If using a custom [Env], provide an [envFactory] that creates instances of [E].
  ///
  /// Example:
  /// ```dart
  /// final app = Aim<MyEnv>(envFactory: () => MyEnv());
  /// ```
  Aim({E Function()? envFactory})
    : _envFactory = envFactory ?? (() => EmptyEnv() as E);

  /// Starts the HTTP server and begins listening for requests.
  ///
  /// Returns an [AimHttpServer] instance that can be used to stop the server.
  ///
  /// Parameters:
  /// - [host]: The host address to bind to (e.g., InternetAddress.anyIPv4)
  /// - [port]: The port to listen on
  /// - [securityContext]: Optional SSL/TLS security context for HTTPS
  /// - [backlog]: The maximum number of pending connections (defaults to 0)
  /// - [shared]: Whether to allow multiple isolates to bind to the same port
  ///
  /// Example:
  /// ```dart
  /// final server = await app.serve(
  ///   host: InternetAddress.anyIPv4,
  ///   port: 8080,
  /// );
  /// print('Server running on http://${server.host}:${server.port}');
  /// ```
  Future<AimHttpServer> serve({
    required Object host,
    required int port,
    SecurityContext? securityContext,
    int? backlog,
    bool shared = false,
  }) async {
    backlog ??= 0;
    final server = await (securityContext == null
        ? HttpServer.bind(host, port, backlog: backlog, shared: shared)
        : HttpServer.bindSecure(
            host,
            port,
            securityContext,
            backlog: backlog,
            shared: shared,
          ));
    server.listen(_handleRequest);
    return AimHttpServer._(server, server.address.host, server.port);
  }

  Future<void> _handleRequest(HttpRequest httpRequest) async {
    // Convert HttpRequest headers to Map<String, String>
    final requestHeaders = <String, String>{};
    httpRequest.headers.forEach((key, values) {
      requestHeaders[key] = values.join(',');
    });

    // Build absolute URI
    final scheme = httpRequest.connectionInfo?.localPort == 443
        ? 'https'
        : 'http';
    final host = httpRequest.headers.value('host') ?? 'localhost';
    final absoluteUri = Uri.parse('$scheme://$host${httpRequest.uri}');

    // Create Request object
    final request = Request(
      httpRequest.method,
      absoluteUri,
      bodyContent: httpRequest,
      headers: requestHeaders,
      raw: httpRequest,
    );

    // Create Context
    final env = _envFactory();
    final context = Context<E>(request, env);

    Response response;

    try {
      // Find matching route first
      Route<E>? matchingRoute;
      Map<String, String>? pathParams;

      for (final route in _routes) {
        if (route.method == httpRequest.method) {
          final params = route.match(httpRequest.uri.path);
          if (params != null) {
            matchingRoute = route;
            pathParams = params;
            break;
          }
        }
      }

      // Define final handler (either route handler or 404 handler)
      Handler<E> finalHandler;

      if (matchingRoute == null) {
        // 404 handler
        finalHandler =
            _notFoundHandler ??
            (c) async => Response.notFound(body: 'Not Found');
      } else {
        // Route handler with path parameters
        finalHandler = (c) async {
          pathParams!.forEach((key, value) {
            c.set('param:$key', value);
          });
          return await matchingRoute!.handler(c);
        };
      }

      // Execute middleware chain + handler
      response = await _executeMiddlewareChain(context, finalHandler);
    } catch (e, st) {
      // Handle errors
      if (_errorHandler != null) {
        try {
          response = await _errorHandler!(e, context);
        } catch (handlerError) {
          // Error handler itself threw an error
          print('Error handler failed: $handlerError');
          print('Original error: $e');
          print(st.toString());
          response = Response.internalServerError(
            body: 'Internal Server Error',
          );
        }
      } else {
        // Default error handling
        print('Error: $e');
        print(st.toString());
        response = Response.internalServerError(
          body: 'Internal Server Error: $e',
        );
      }
    }

    // Write response
    try {
      httpRequest.response.statusCode = response.statusCode;
      response.headers.forEach((key, value) {
        // Handle Set-Cookie specially (multiple headers allowed)
        if (key.toLowerCase() == 'set-cookie') {
          // Split by newline if multiple cookies were concatenated
          final cookies = value.split('\n');
          for (final cookie in cookies) {
            if (cookie.isNotEmpty) {
              httpRequest.response.headers.add(key, cookie);
            }
          }
        } else {
          httpRequest.response.headers.set(key, value);
        }
      });

      // Stream the response body
      await httpRequest.response.addStream(response.read());
      await httpRequest.response.close();
    } catch (e) {
      print('Failed to send response: $e');
      try {
        await httpRequest.response.close();
      } catch (_) {
        // Ignore
      }
    }
  }

  /// Registers a GET route.
  ///
  /// The [path] can include parameters (e.g., `/users/:id`) and wildcards (e.g., `/files/*`).
  ///
  /// Example:
  /// ```dart
  /// app.get('/users/:id', (c) async {
  ///   final id = c.param('id');
  ///   return c.json({'userId': id});
  /// });
  /// ```
  Aim<E> get(String path, Handler<E> handler, {Object? metadata}) {
    _routes.add(
      Route<E>(path: path, method: 'GET', handler: handler, metadata: metadata),
    );
    return this;
  }

  /// Registers a POST route.
  ///
  /// Example:
  /// ```dart
  /// app.post('/users', (c) async {
  ///   final data = await c.req.json();
  ///   return c.json({'message': 'User created', 'user': data});
  /// });
  /// ```
  Aim<E> post(String path, Handler<E> handler, {Object? metadata}) {
    _routes.add(
      Route<E>(
        path: path,
        method: 'POST',
        handler: handler,
        metadata: metadata,
      ),
    );
    return this;
  }

  /// Registers a PUT route.
  Aim<E> put(String path, Handler<E> handler, {Object? metadata}) {
    _routes.add(
      Route<E>(path: path, method: 'PUT', handler: handler, metadata: metadata),
    );
    return this;
  }

  /// Registers a DELETE route.
  Aim<E> delete(String path, Handler<E> handler, {Object? metadata}) {
    _routes.add(
      Route<E>(
        path: path,
        method: 'DELETE',
        handler: handler,
        metadata: metadata,
      ),
    );
    return this;
  }

  /// Registers a PATCH route.
  Aim<E> patch(String path, Handler<E> handler, {Object? metadata}) {
    _routes.add(
      Route<E>(
        path: path,
        method: 'PATCH',
        handler: handler,
        metadata: metadata,
      ),
    );
    return this;
  }

  /// Registers a HEAD route.
  Aim<E> head(String path, Handler<E> handler, {Object? metadata}) {
    _routes.add(
      Route<E>(
        path: path,
        method: 'HEAD',
        handler: handler,
        metadata: metadata,
      ),
    );
    return this;
  }

  /// Registers an OPTIONS route.
  Aim<E> options(String path, Handler<E> handler, {Object? metadata}) {
    _routes.add(
      Route<E>(
        path: path,
        method: 'OPTIONS',
        handler: handler,
        metadata: metadata,
      ),
    );
    return this;
  }

  /// Registers a middleware function.
  ///
  /// Middleware is executed globally before route handlers.
  /// Middleware can modify the context, perform logging, authentication, etc.
  ///
  /// Example:
  /// ```dart
  /// app.use((c, next) async {
  ///   print('${c.method} ${c.path}');
  ///   await next();
  /// });
  /// ```
  Aim<E> use(Middleware<E> middleware) {
    _middlewares.add(middleware);
    return this;
  }

  /// Sets a custom handler for 404 Not Found responses.
  ///
  /// This handler is called when no route matches the request.
  ///
  /// Example:
  /// ```dart
  /// app.notFound((c) async {
  ///   return c.json({'error': 'Not Found'}, statusCode: 404);
  /// });
  /// ```
  Aim<E> notFound(Handler<E> handler) {
    _notFoundHandler = handler;
    return this;
  }

  /// Sets a custom error handler for uncaught exceptions.
  ///
  /// This handler is called when an error occurs during request processing.
  ///
  /// Example:
  /// ```dart
  /// app.onError((error, c) async {
  ///   print('Error: $error');
  ///   return c.json({'error': error.toString()}, statusCode: 500);
  /// });
  /// ```
  Aim<E> onError(ErrorHandler<E> handler) {
    _errorHandler = handler;
    return this;
  }

  /// Mounts a sub-application at the specified path prefix.
  ///
  /// All routes from the sub-application will be prefixed with [basePath].
  /// Middlewares from the sub-application are NOT automatically applied.
  ///
  /// Example:
  /// ```dart
  /// final api = Aim<MyEnv>(envFactory: () => MyEnv());
  /// api.get('/users', (c) => c.json({'users': []}));
  /// api.get('/posts', (c) => c.json({'posts': []}));
  ///
  /// final app = Aim<MyEnv>(envFactory: () => MyEnv());
  /// app.route('/api/v1', api); // Mounts at /api/v1/users, /api/v1/posts
  /// ```
  Aim<E> route(String basePath, Aim<E> subApp) {
    // Normalize base path (remove trailing slash)
    final normalizedBasePath = basePath.endsWith('/')
        ? basePath.substring(0, basePath.length - 1)
        : basePath;

    // Add all routes from sub-app with prefix
    for (final route in subApp._routes) {
      final prefixedPath = normalizedBasePath + route.path;
      _routes.add(
        Route<E>(
          path: prefixedPath,
          method: route.method,
          handler: route.handler,
        ),
      );
    }

    return this;
  }

  /// Executes middleware chain including the final handler.
  ///
  /// This implements koa-compose style middleware chaining where:
  /// - Middlewares can run code before calling next() (before phase)
  /// - The final handler is executed when all middlewares call next()
  /// - Middlewares can run code after next() returns (after phase)
  ///
  /// This allows middlewares to access the response after the handler executes.
  Future<Response> _executeMiddlewareChain(
    Context<E> context,
    Handler<E> finalHandler,
  ) async {
    var index = -1;

    Future<Response> dispatch(int i) async {
      if (i <= index) {
        throw StateError('next() called multiple times');
      }
      index = i;

      // Check if response has been finalized by previous middleware
      if (context.finalized) {
        return context.response!;
      }

      if (i < _middlewares.length) {
        // Execute middleware
        await _middlewares[i](context, () => dispatch(i + 1));

        // After middleware completes, response should be finalized
        // (either by the middleware itself or by the handler called through next())
        if (context.finalized) {
          return context.response!;
        }

        // This shouldn't happen - either middleware or handler should finalize
        throw StateError(
          'Middleware chain completed without finalizing response',
        );
      } else {
        // All middlewares executed, now execute the final handler
        final response = await finalHandler(context);

        // Store response in context so middlewares can access it in after phase
        // Note: If handler used c.json(), c.text(), etc., response is already stored
        // But if handler directly returned Response, we need to ensure it's stored
        if (!context.finalized) {
          // Handler returned Response directly without using context methods
          context.internalFinalizeResponse(response);
        }

        return response;
      }
    }

    final response = await dispatch(0);

    // After all middlewares complete, check if any headers were added in after phase
    // If so, merge them into the final response
    if (context.responseHeaders.isNotEmpty) {
      final mergedHeaders = Map<String, String>.from(response.headers);
      mergedHeaders.addAll(context.responseHeaders);

      // Create new response with merged headers
      return Response.stream(
        response.read(),
        statusCode: response.statusCode,
        headers: mergedHeaders,
      );
    }

    return response;
  }
}

/// Represents a running HTTP server.
///
/// Returned by [Aim.serve] and can be used to stop the server.
class AimHttpServer {
  /// The host address the server is bound to.
  final String host;

  /// The port the server is listening on.
  final int port;

  final HttpServer _server;

  AimHttpServer._(this._server, this.host, this.port);

  /// Closes the HTTP server.
  ///
  /// If [force] is true, active connections will be closed immediately.
  /// Otherwise, the server will wait for active connections to close.
  Future<void> close({bool force = false}) async {
    await _server.close(force: force);
  }
}

/// Internal class representing a route with path pattern matching.
///
/// Supports:
/// - Named parameters: `/users/:id`
/// - Regex constraints: `/users/:id(\\d+)`
/// - Wildcard: `/posts/*`
/// - Wildcard parameter: `/static/*filepath`
class Route<E extends Env> {
  /// The path pattern for this route.
  final String path;

  /// The HTTP method for this route (e.g., 'GET', 'POST').
  final String method;

  /// The handler function for this route.
  final Handler<E> handler;

  /// Optional metadata for this route (e.g., OpenAPI spec, rate limiting config).
  final Object? metadata;

  /// Regular expression pattern for matching the route
  late final RegExp? _pattern;

  /// Names of path parameters in order
  late final List<String> _paramNames;

  Route({
    required this.path,
    required this.method,
    required this.handler,
    this.metadata,
  }) {
    _paramNames = [];

    // Parse path pattern and extract parameter names
    // Supports:
    // - Named parameters: /users/:id
    // - Regex constraints: /users/:id(\\d+)
    // - Wildcard: /posts/*
    // - Wildcard parameter: /static/*filepath
    final segments = path.split('/');
    final patternSegments = <String>[];
    var hasPattern = false;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];

      if (segment.startsWith('*')) {
        // Wildcard or wildcard parameter
        hasPattern = true;

        if (segment.length > 1) {
          // Wildcard parameter like *filepath
          final paramName = segment.substring(1);
          _paramNames.add(paramName);
          // Match everything including slashes
          patternSegments.add('(.*)');
        } else {
          // Plain wildcard *
          // Match everything including slashes but don't capture
          patternSegments.add('.*');
        }
        // Wildcard should be the last segment
        break;
      } else if (segment.startsWith(':')) {
        // Named parameter with optional regex constraint
        hasPattern = true;
        final paramContent = segment.substring(1);

        // Check for regex constraint like :id(\\d+)
        final regexMatch = RegExp(r'^(\w+)\((.+)\)$').firstMatch(paramContent);

        if (regexMatch != null) {
          // Parameter with regex constraint
          final paramName = regexMatch.group(1)!;
          final regexPattern = regexMatch.group(2)!;
          _paramNames.add(paramName);
          patternSegments.add('($regexPattern)');
        } else {
          // Simple parameter like :id
          final paramName = paramContent;
          _paramNames.add(paramName);
          patternSegments.add('([^/]+)'); // Match any non-slash characters
        }
      } else {
        // Literal segment
        patternSegments.add(RegExp.escape(segment));
      }
    }

    // Create regex pattern if there are parameters or wildcards
    if (hasPattern || _paramNames.isNotEmpty) {
      final pattern = '^${patternSegments.join('/')}\$';
      _pattern = RegExp(pattern);
    } else {
      _pattern = null;
    }
  }

  /// Matches the given path and extracts parameters
  /// Returns a map of parameter names to values, or null if no match
  Map<String, String>? match(String requestPath) {
    // If no parameters, do exact match
    final pattern = _pattern;
    if (pattern == null) {
      return requestPath == path ? {} : null;
    }

    // Try to match the pattern
    final match = pattern.firstMatch(requestPath);
    if (match == null) return null;

    // Extract parameters
    final params = <String, String>{};
    for (var i = 0; i < _paramNames.length; i++) {
      params[_paramNames[i]] = match.group(i + 1)!;
    }

    return params;
  }
}
