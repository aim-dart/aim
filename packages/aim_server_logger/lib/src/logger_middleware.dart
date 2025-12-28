import 'package:aim_server/aim_server.dart';

/// Creates a logger middleware for HTTP request/response logging.
///
/// This middleware logs incoming requests and outgoing responses with their
/// processing time. You can customize the logging behavior by providing
/// [onRequest] and [onResponse] callbacks.
///
/// Example:
/// ```dart
/// final app = Aim();
///
/// // Use default logging
/// app.use(logger());
///
/// // Custom logging
/// app.use(logger(
///   onRequest: (c) async {
///     print('Request: ${c.req.method} ${c.req.uri}');
///   },
///   onResponse: (c, durationMs) async {
///     print('Response: ${c.response?.statusCode} (${durationMs}ms)');
///   },
/// ));
/// ```
///
/// If both [onRequest] and [onResponse] are omitted, default log output is used:
/// - Request: `<-- GET http://localhost:8080/`
/// - Response: `--> GET http://localhost:8080/ 200 15ms`
Middleware logger({
  Future<void> Function(Context c)? onRequest,
  Future<void> Function(Context c, int durationMs)? onResponse,
}) {
  return (c, next) async {
    if (onRequest != null) {
      await onRequest(c);
    } else {
      print('<-- ${c.req.method} ${c.req.uri}');
    }

    final start = DateTime.now();
    await next();
    final durationMs = DateTime.now().difference(start).inMilliseconds;

    if (onResponse != null) {
      await onResponse(c, durationMs);
    } else {
      print('--> ${c.req.method} ${c.req.uri} ${c.response?.statusCode} ${durationMs}ms');
    }
  };
}