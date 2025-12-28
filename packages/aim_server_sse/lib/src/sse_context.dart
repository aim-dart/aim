import 'dart:async';
import 'dart:convert';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_sse/src/formatter.dart';
import 'package:aim_server_sse/src/sse_event.dart';
import 'package:aim_server_sse/src/sse_stream.dart';

/// Extension on [Context] to add SSE support.
extension SseContext<E extends Env> on Context<E> {
  /// Returns a Server-Sent Events (SSE) response.
  ///
  /// The [callback] function receives an [SseStream] that can be used to send
  /// events to the client. The stream is automatically closed when the callback
  /// completes or when an error occurs.
  ///
  /// Example:
  /// ```dart
  /// app.get('/events', (c) async {
  ///   return c.sse((stream) async {
  ///     stream.send('Hello');
  ///     await Future.delayed(Duration(seconds: 1));
  ///     stream.sendJson({'message': 'World'}, event: 'custom');
  ///
  ///     // Infinite loop for real-time updates
  ///     while (true) {
  ///       stream.send('Ping');
  ///       await Future.delayed(Duration(seconds: 5));
  ///     }
  ///   });
  /// });
  /// ```
  ///
  /// The connection will be automatically closed when:
  /// - The callback completes (returns)
  /// - An error occurs in the callback
  /// - The client disconnects
  Future<Response> sse(
    FutureOr<void> Function(SseStream stream) callback, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) async {
    // Create StreamController with onListen to execute callback when streaming starts
    late final StreamController<SseEvent> controller;
    late final SseStream sseStream;

    controller = StreamController<SseEvent>(
      sync: false,
      onListen: () {
        // Execute callback in background without awaiting
        Future(() async {
          try {
            await callback(sseStream);
            if (!controller.isClosed) {
              controller.close();
            }
          } catch (e, stackTrace) {
            // Log the error but don't propagate it
            print('SSE callback error: $e');
            print(stackTrace);
            if (!controller.isClosed) {
              controller.close();
            }
          }
        });
      },
    );

    sseStream = SseStream.fromController(controller);

    // Convert Stream<SseEvent> to Stream<List<int>>
    final byteStream = controller.stream.map((event) {
      final formatted = formatSseEvent(event);
      return utf8.encode(formatted);
    });

    // Set SSE-specific headers
    final sseHeaders = {
      'content-type': 'text/event-stream; charset=utf-8',
      'cache-control': 'no-cache',
      'connection': 'keep-alive',
      ...?headers,
    };

    return stream(byteStream, statusCode: statusCode, headers: sseHeaders);
  }
}
