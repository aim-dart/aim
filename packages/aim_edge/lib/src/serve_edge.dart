import 'dart:js_interop';

import 'package:aim_core/aim_core.dart';
import 'package:aim_edge/src/edge_request.dart';
import 'package:aim_edge/src/edge_response.dart';
import 'package:aim_edge/src/interop.dart';
import 'package:web/web.dart' as web;

/// Runs an [Aim] application on Cloudflare workerd.
extension AimEdge<E extends Env> on Aim<E> {
  /// Registers this application as the worker's fetch handler.
  ///
  /// Sets `globalThis.__aimFetch` to a function `(request, env, ctx)` that
  /// returns a `Promise<Response>`. The JS entry module instantiates the
  /// wasm module, calls `main()` (which calls this), then forwards every
  /// `fetch` event to `__aimFetch`.
  ///
  /// Unhandled errors without an [Aim.onError] handler are written to
  /// `console.error` and answered with a 500 response.
  void serveEdge() {
    aimFetchGlobal = ((web.Request request, JSObject env, JSObject ctx) =>
        _fetch(this, request, env, ctx).toJS).toJS;
  }
}

Future<web.Response> _fetch<E extends Env>(
  Aim<E> app,
  web.Request request,
  JSObject env,
  JSObject ctx,
) async {
  Response response;
  try {
    response = await app.handle(
      await toAimRequest(request, env, ctx),
      onUnhandledError: _logAndRespond,
    );
  } catch (e, st) {
    web.console.error('Failed to process request: $e\n$st'.toJS);
    response = Response.text('Bad Request', statusCode: 400);
  }
  try {
    return toWebResponse(response);
  } catch (e, st) {
    web.console.error('Failed to send response: $e\n$st'.toJS);
    return web.Response(
      'Internal Server Error'.toJS,
      web.ResponseInit(status: 500),
    );
  }
}

Future<Response> _logAndRespond<E extends Env>(
  Object error,
  StackTrace stackTrace,
  Context<E> c,
) async {
  web.console.error('Error: $error\n$stackTrace'.toJS);
  return Response.internalServerError(body: 'Internal Server Error: $error');
}
