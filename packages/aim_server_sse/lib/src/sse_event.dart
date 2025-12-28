import 'dart:convert';

/// Represents a Server-Sent Events (SSE) message.
///
/// SSE events can contain data, an optional event type, an optional ID,
/// and an optional retry interval. Comments and keep-alive messages
/// are also supported.
class SseEvent {
  /// The data payload of this event.
  final String data;

  /// The event type name. If null, the client will use 'message' as default.
  final String? event;

  /// The event ID. Can be used by the client to track the last received event
  /// and resume from that point after reconnection.
  final String? id;

  /// The reconnection time in milliseconds. This tells the client how long
  /// to wait before attempting to reconnect after the connection is closed.
  final int? retry;

  /// Whether this is a comment (will be ignored by the client).
  /// Comments are used for keep-alive or debugging purposes.
  final bool isComment;

  /// Private constructor. Use named constructors instead.
  SseEvent._({
    required this.data,
    this.event,
    this.id,
    this.retry,
    this.isComment = false,
  });

  /// Creates an event with JSON-encoded data.
  ///
  /// The [data] object will be encoded as JSON using [jsonEncode].
  ///
  /// Example:
  /// ```dart
  /// SseEvent.json({'message': 'Hello'}, event: 'greeting', id: '1')
  /// ```
  SseEvent.json(
    Object data, {
    String? event,
    String? id,
    int? retry,
  }) : this._(
          data: jsonEncode(data),
          event: event,
          id: id,
          retry: retry,
        );

  /// Creates an event with text data.
  ///
  /// Example:
  /// ```dart
  /// SseEvent.text('Hello, World!', event: 'message', id: '1')
  /// ```
  SseEvent.text(
    String data, {
    String? event,
    String? id,
    int? retry,
  }) : this._(
          data: data,
          event: event,
          id: id,
          retry: retry,
        );

  /// Creates a comment event.
  ///
  /// Comments are ignored by the client but can be used for debugging
  /// or keep-alive purposes.
  ///
  /// Example:
  /// ```dart
  /// SseEvent.comment('Server timestamp: ${DateTime.now()}')
  /// ```
  SseEvent.comment(String text) : this._(data: text, isComment: true);

  /// Creates a keep-alive event.
  ///
  /// This sends an empty comment to maintain the connection.
  /// Useful for preventing proxy or firewall timeouts.
  ///
  /// Example:
  /// ```dart
  /// SseEvent.keepAlive()
  /// ```
  SseEvent.keepAlive() : this._(data: '', isComment: true);
}
