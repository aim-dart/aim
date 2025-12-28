import 'package:aim_server_sse/src/sse_event.dart';

/// Formats an [SseEvent] into the SSE protocol text format.
///
/// This function is for internal use only and should not be exported
/// from the package.
///
/// The SSE protocol format:
/// - Comments: `: comment text\n`
/// - Events: `event: name\ndata: content\nid: id\nretry: ms\n\n`
///
/// Multi-line data is supported by prefixing each line with `data: `.
String formatSseEvent(SseEvent event) {
  final buffer = StringBuffer();

  if (event.isComment) {
    // Comment format: `: comment text\n`
    buffer.write(': ${event.data}\n');
  } else {
    // Event type (optional)
    if (event.event != null) {
      buffer.write('event: ${event.event}\n');
    }

    // Data (required) - support multi-line data
    final lines = event.data.split('\n');
    for (final line in lines) {
      buffer.write('data: $line\n');
    }

    // ID (optional)
    if (event.id != null) {
      buffer.write('id: ${event.id}\n');
    }

    // Retry (optional)
    if (event.retry != null) {
      buffer.write('retry: ${event.retry}\n');
    }

    // End of event (empty line)
    buffer.write('\n');
  }

  return buffer.toString();
}
