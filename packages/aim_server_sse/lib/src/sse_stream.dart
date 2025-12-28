import 'dart:async';

import 'package:aim_server_sse/src/sse_event.dart';

/// A stream wrapper for sending Server-Sent Events.
///
/// This class provides convenient methods for sending SSE events
/// without directly managing [SseEvent] objects.
class SseStream {
  final StreamController<SseEvent> _controller;

  SseStream._(this._controller);

  /// Internal factory for creating SseStream from a StreamController.
  ///
  /// This is used internally by the SSE extension and should not be
  /// used directly in application code.
  factory SseStream.fromController(StreamController<SseEvent> controller) {
    return SseStream._(controller);
  }

  /// Sends a text event.
  ///
  /// Example:
  /// ```dart
  /// stream.send('Hello, World!', event: 'greeting', id: '1');
  /// ```
  void send(String data, {String? event, String? id, int? retry}) {
    _controller.add(SseEvent.text(data, event: event, id: id, retry: retry));
  }

  /// Sends a JSON-encoded event.
  ///
  /// The [data] object will be automatically encoded as JSON.
  ///
  /// Example:
  /// ```dart
  /// stream.sendJson({'message': 'Hello'}, event: 'greeting', id: '1');
  /// ```
  void sendJson(Object data, {String? event, String? id, int? retry}) {
    _controller.add(SseEvent.json(data, event: event, id: id, retry: retry));
  }

  /// Sends a keep-alive comment.
  ///
  /// This helps maintain the connection and prevents timeouts.
  ///
  /// Example:
  /// ```dart
  /// stream.keepAlive();
  /// ```
  void keepAlive() {
    _controller.add(SseEvent.keepAlive());
  }

  /// Sends a comment.
  ///
  /// Comments are ignored by the client but can be useful for debugging.
  ///
  /// Example:
  /// ```dart
  /// stream.comment('Debug: Processing started');
  /// ```
  void comment(String text) {
    _controller.add(SseEvent.comment(text));
  }

  /// Closes the stream.
  ///
  /// After calling this method, no more events can be sent.
  /// Note: The stream is automatically closed when the callback completes.
  void close() {
    _controller.close();
  }
}
