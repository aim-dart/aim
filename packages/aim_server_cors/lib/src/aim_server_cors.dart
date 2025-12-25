import 'package:aim_server/aim_server.dart';

/// Options for CORS middleware
class CorsOptions {
  /// Allowed origins. Can be:
  /// - A string: '*' for all origins, or a specific origin like 'https://example.com'
  /// - A list of strings: multiple specific origins
  /// - A function: custom origin validation
  final dynamic origin;

  /// Allowed HTTP methods
  final List<String> allowMethods;

  /// Allowed request headers
  final List<String> allowHeaders;

  /// Headers exposed to the browser
  final List<String> exposeHeaders;

  /// Whether to allow credentials (cookies, authorization headers)
  final bool credentials;

  /// How long (in seconds) the results of a preflight request can be cached
  final int? maxAge;

  const CorsOptions({
    this.origin = '*',
    this.allowMethods = const ['GET', 'HEAD', 'PUT', 'POST', 'DELETE', 'PATCH'],
    this.allowHeaders = const ['*'],
    this.exposeHeaders = const [],
    this.credentials = false,
    this.maxAge,
  });
}

/// Creates a CORS middleware
///
/// Example:
/// ```dart
/// final app = Aim();
///
/// // Allow all origins (default)
/// app.use(cors());
///
/// // Allow specific origin
/// app.use(cors(CorsOptions(
///   origin: 'https://example.com',
///   credentials: true,
/// )));
///
/// // Allow multiple origins
/// app.use(cors(CorsOptions(
///   origin: ['https://example.com', 'https://app.example.com'],
/// )));
///
/// // Custom origin validation
/// app.use(cors(CorsOptions(
///   origin: (String origin) => origin.endsWith('.example.com'),
/// )));
/// ```
Middleware<E> cors<E extends Env>([CorsOptions options = const CorsOptions()]) {
  return (Context<E> c, Next next) async {
    // Get request origin
    final requestOrigin = c.headers['origin'];

    // Determine allowed origin
    String? allowedOrigin;

    if (options.origin is String) {
      final originStr = options.origin as String;
      if (originStr == '*') {
        allowedOrigin = '*';
      } else {
        // Specific origin
        if (requestOrigin == originStr) {
          allowedOrigin = originStr;
        }
      }
    } else if (options.origin is List<String>) {
      final origins = options.origin as List<String>;
      if (requestOrigin != null && origins.contains(requestOrigin)) {
        allowedOrigin = requestOrigin;
      }
    } else if (options.origin is bool Function(String)) {
      final validator = options.origin as bool Function(String);
      if (requestOrigin != null && validator(requestOrigin)) {
        allowedOrigin = requestOrigin;
      }
    }

    // If origin is not allowed, continue without CORS headers
    if (allowedOrigin == null && requestOrigin != null) {
      await next();
      return;
    }

    // Handle preflight request (OPTIONS)
    if (c.method == 'OPTIONS') {
      if (allowedOrigin != null) {
        c.header('access-control-allow-origin', allowedOrigin);
      }

      if (options.credentials) {
        c.header('access-control-allow-credentials', 'true');
      }

      if (options.allowMethods.isNotEmpty) {
        c.header(
          'access-control-allow-methods',
          options.allowMethods.join(', '),
        );
      }

      // Handle Access-Control-Request-Headers
      final requestHeaders = c.headers['access-control-request-headers'];
      if (requestHeaders != null) {
        if (options.allowHeaders.contains('*')) {
          c.header('access-control-allow-headers', requestHeaders);
        } else if (options.allowHeaders.isNotEmpty) {
          c.header(
            'access-control-allow-headers',
            options.allowHeaders.join(', '),
          );
        }
      }

      if (options.maxAge != null) {
        c.header('access-control-max-age', options.maxAge.toString());
      }

      // Return 204 No Content for preflight
      // This will finalize the response and skip remaining middleware/handler
      c.text('', statusCode: 204);
      return;
    }

    // For non-OPTIONS requests, add CORS headers to response
    if (allowedOrigin != null) {
      c.header('access-control-allow-origin', allowedOrigin);
    }

    if (options.credentials) {
      c.header('access-control-allow-credentials', 'true');
    }

    if (options.exposeHeaders.isNotEmpty) {
      c.header(
        'access-control-expose-headers',
        options.exposeHeaders.join(', '),
      );
    }

    await next();
  };
}
