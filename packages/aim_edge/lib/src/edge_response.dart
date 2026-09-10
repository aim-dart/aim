import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';

import 'package:aim_core/aim_core.dart';
import 'package:web/web.dart' as web;

/// Converts an Aim [Response] into a workerd [web.Response].
///
/// `Set-Cookie` values joined with `\n` become separate headers. Bodies are
/// streamed through a `ReadableStream` so SSE and large responses flow
/// chunk by chunk; an empty body is sent as `null`.
web.Response toWebResponse(Response response) {
  final headers = web.Headers();
  response.headers.forEach((key, value) {
    if (key.toLowerCase() == 'set-cookie') {
      for (final cookie in value.split('\n')) {
        if (cookie.isNotEmpty) headers.append(key, cookie);
      }
    } else {
      headers.append(key, value);
    }
  });

  final init = web.ResponseInit(status: response.statusCode, headers: headers);
  if (response.body.contentLength == 0) {
    return web.Response(null, init);
  }
  return web.Response(_toReadableStream(response.read()), init);
}

/// Wraps a Dart byte stream in a JS `ReadableStream`.
///
/// No backpressure: chunks are enqueued as they arrive.
web.ReadableStream _toReadableStream(Stream<List<int>> stream) {
  StreamSubscription<List<int>>? subscription;

  final source = JSObject();
  source['start'] = ((web.ReadableStreamDefaultController controller) {
    subscription = stream.listen(
      (chunk) => controller.enqueue(Uint8List.fromList(chunk).toJS),
      onDone: () => controller.close(),
      onError: (Object error) => controller.error(error.toString().toJS),
      cancelOnError: true,
    );
  }).toJS;
  source['cancel'] = (() {
    subscription?.cancel();
  }).toJS;

  return web.ReadableStream(source);
}
