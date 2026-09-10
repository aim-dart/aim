import 'dart:io';

import 'package:aim_core/aim_core.dart';

/// Typed access to the underlying `dart:io` request.
extension HttpRequestAccess on Request {
  /// The [HttpRequest] this request was created from, or `null` when the
  /// request was not produced by [AimServe.serve] (for example in tests).
  HttpRequest? get httpRequest {
    final r = raw;
    return r is HttpRequest ? r : null;
  }
}

/// Runs an [Aim] application on `dart:io`'s [HttpServer].
extension AimServe<E extends Env> on Aim<E> {
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
  /// Unhandled errors without an [Aim.onError] handler are printed with
  /// their stack trace and answered with a 500 response.
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
    server.listen(_handleHttpRequest);
    return AimHttpServer._(server, server.address.host, server.port);
  }

  Future<void> _handleHttpRequest(HttpRequest httpRequest) async {
    Response response;
    try {
      response = await handle(
        _toRequest(httpRequest),
        onUnhandledError: _printAndRespond,
      );
    } catch (e, st) {
      print('Failed to process request: $e');
      print(st.toString());
      response = Response.text('Bad Request', statusCode: 400);
    }
    await _writeResponse(httpRequest.response, response);
  }
}

/// Default error handler for the VM adapter: logs and returns 500.
Future<Response> _printAndRespond<E extends Env>(
  Object error,
  StackTrace stackTrace,
  Context<E> c,
) async {
  print('Error: $error');
  print(stackTrace.toString());
  return Response.internalServerError(body: 'Internal Server Error: $error');
}

/// Converts a `dart:io` [HttpRequest] into an Aim [Request].
///
/// Multi-value headers are joined with `,`. The path and query always come
/// from the request line; only the scheme, host, and port come from the
/// `Host` header, falling back to `localhost` when that header is missing
/// or malformed.
Request _toRequest(HttpRequest httpRequest) {
  final headers = <String, String>{};
  httpRequest.headers.forEach((key, values) {
    headers[key] = values.join(',');
  });

  final scheme = httpRequest.connectionInfo?.localPort == 443
      ? 'https'
      : 'http';
  Uri base;
  try {
    base = Uri.parse(
      '$scheme://${httpRequest.headers.value('host') ?? 'localhost'}',
    );
    if (base.host.isEmpty) base = Uri.parse('$scheme://localhost');
  } on FormatException {
    base = Uri.parse('$scheme://localhost');
  }
  final absoluteUri = Uri(
    scheme: base.scheme,
    host: base.host,
    port: base.hasPort ? base.port : null,
    path: httpRequest.uri.path,
    query: httpRequest.uri.hasQuery ? httpRequest.uri.query : null,
  );

  return Request(
    httpRequest.method,
    absoluteUri,
    bodyContent: httpRequest,
    headers: headers,
    raw: httpRequest,
  );
}

/// Writes an Aim [Response] to a `dart:io` [HttpResponse].
///
/// `Set-Cookie` values joined with `\n` are split into separate headers.
/// `text/event-stream` responses disable output buffering and every chunk
/// is flushed so SSE clients receive events in real time.
Future<void> _writeResponse(HttpResponse out, Response response) async {
  try {
    out.statusCode = response.statusCode;
    response.headers.forEach((key, value) {
      if (key.toLowerCase() == 'set-cookie') {
        for (final cookie in value.split('\n')) {
          if (cookie.isNotEmpty) out.headers.add(key, cookie);
        }
      } else {
        out.headers.set(key, value);
      }
    });

    final contentType = response.headers['content-type'];
    if (contentType != null && contentType.contains('text/event-stream')) {
      out.bufferOutput = false;
    }

    await for (final chunk in response.read()) {
      out.add(chunk);
      await out.flush();
    }
    await out.close();
  } catch (e) {
    print('Failed to send response: $e');
    try {
      await out.close();
    } catch (_) {
      // Ignore
    }
  }
}

/// Represents a running HTTP server.
///
/// Returned by [AimServe.serve] and can be used to stop the server.
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
