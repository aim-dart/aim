import 'dart:js_interop';

import 'package:aim_core/aim_core.dart';
import 'package:aim_edge/src/interop.dart';
import 'package:web/web.dart' as web;

/// Platform object stored in [Request.raw] by the workerd adapter.
///
/// Internal: exposes package:web types and must not be exported.
class EdgeRawRequest {
  final web.Request request;
  final JSObject env;
  final JSObject ctx;

  EdgeRawRequest(this.request, this.env, this.ctx);
}

/// Converts a workerd [web.Request] into an Aim [Request].
///
/// The URL is already absolute. Headers are copied as-is (workerd has
/// already joined repeated names). Bodies of non-GET/HEAD requests are read
/// fully into memory.
Future<Request> toAimRequest(
  web.Request request,
  JSObject env,
  JSObject ctx,
) async {
  final headers = <String, String>{};
  request.headers.forEach(
    (String value, String key) {
      headers[key] = value;
    }.toJS,
  );

  Object? body;
  if (request.method != 'GET' && request.method != 'HEAD') {
    final buffer = await request.arrayBuffer().toDart;
    body = buffer.toDart.asUint8List();
  }

  return Request(
    request.method,
    Uri.parse(request.url),
    bodyContent: body,
    headers: headers,
    raw: EdgeRawRequest(request, env, ctx),
  );
}
