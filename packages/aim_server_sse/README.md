# aim_server_sse

Server-Sent Events (SSE) support for the Aim framework.

## Overview

`aim_server_sse` provides Server-Sent Events functionality for the Aim framework, enabling real-time server-to-client streaming. Inspired by [Hono](https://hono.dev/)'s SSE helper.

## Features

- Simple and intuitive API for sending events
- Support for text and JSON events
- Event types, IDs, and retry intervals
- Keep-alive and comment support
- Automatic connection cleanup
- Full TypeScript-like type safety

## Installation

Add `aim_server_sse` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6
  aim_server_sse: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Example

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_sse/aim_server_sse.dart';

void main() async {
  final app = Aim();

  app.get('/events', (c) async {
    return c.sse((stream) async {
      stream.send('Hello, SSE!');

      await Future.delayed(Duration(seconds: 1));

      stream.sendJson({'message': 'World!'}, event: 'greeting');
    });
  });

  await app.serve(port: 8080);
}
```

### Real-time Updates

```dart
app.get('/clock', (c) async {
  return c.sse((stream) async {
    while (true) {
      stream.sendJson({
        'time': DateTime.now().toIso8601String(),
      }, event: 'time');

      await Future.delayed(Duration(seconds: 1));
    }
  });
});
```

### Keep-alive

```dart
app.get('/notifications', (c) async {
  return c.sse((stream) async {
    while (true) {
      // Send keep-alive every 30 seconds to prevent timeout
      stream.keepAlive();
      await Future.delayed(Duration(seconds: 30));
    }
  });
});
```

### Event IDs and Retry

```dart
app.get('/updates', (c) async {
  return c.sse((stream) async {
    for (var i = 1; i <= 10; i++) {
      stream.sendJson(
        {'count': i},
        event: 'update',
        id: '$i',
        retry: 5000,  // Reconnect after 5 seconds
      );
      await Future.delayed(Duration(seconds: 1));
    }
  });
});
```

### Debug Comments

```dart
app.get('/process', (c) async {
  return c.sse((stream) async {
    stream.comment('Starting process');

    // ... do work ...

    stream.comment('Process completed');
    stream.send('Done!');
  });
});
```

## API Reference

### `c.sse(callback)`

Creates an SSE response stream.

**Parameters:**
- `callback`: `Future<void> Function(SseStream stream)` - Function that receives a stream to send events

**Returns:** `Response`

The stream is automatically closed when:
- The callback completes
- An error occurs
- The client disconnects

### `SseStream` Methods

#### `send(data, {event, id, retry})`

Sends a text event.

```dart
stream.send('Hello', event: 'message', id: '1', retry: 3000);
```

#### `sendJson(data, {event, id, retry})`

Sends a JSON-encoded event.

```dart
stream.sendJson({'message': 'Hello'}, event: 'greeting', id: '1');
```

#### `keepAlive()`

Sends a keep-alive comment.

```dart
stream.keepAlive();
```

#### `comment(text)`

Sends a comment (for debugging).

```dart
stream.comment('Debug: Processing started');
```

#### `close()`

Manually closes the stream (automatically called when callback completes).

```dart
stream.close();
```

## Client-Side Usage

On the client side, use the standard `EventSource` API:

```html
<script>
  const eventSource = new EventSource('/events');

  // Default 'message' event
  eventSource.onmessage = (event) => {
    console.log('Message:', event.data);
  };

  // Custom event type
  eventSource.addEventListener('greeting', (event) => {
    const data = JSON.parse(event.data);
    console.log('Greeting:', data);
  });

  // Error handling
  eventSource.onerror = (error) => {
    console.error('SSE error:', error);
  };
</script>
```

## How It Works

Server-Sent Events is a standard protocol for pushing updates from server to client over HTTP:

1. Client sends a regular HTTP request
2. Server responds with `Content-Type: text/event-stream`
3. Connection stays open
4. Server sends events as they occur
5. Client automatically reconnects if disconnected

SSE is ideal for:
- Real-time notifications
- Live dashboards
- Progress updates
- Chat applications (server-to-client only)

For bidirectional communication, consider WebSockets instead.

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
