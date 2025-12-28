# aim_server_logger

HTTP logging middleware for the Aim framework.

## Overview

`aim_server_logger` provides HTTP request/response logging for the Aim framework. Inspired by [Hono](https://hono.dev/)'s logger middleware.

## Features

- Request/response logging with method, path, status code, and response time
- Customizable `onRequest` and `onResponse` callbacks
- Easy integration with custom logging systems

## Installation

Add `aim_server_logger` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6
  aim_server_logger: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Logging

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_logger/aim_server_logger.dart';

void main() async {
  final app = Aim();

  app.use(logger());

  app.get('/', (c) async => c.text('Hello, Aim!'));

  await app.serve(port: 8080);
}
```

Output:
```
<-- GET http://localhost:8080/
--> GET http://localhost:8080/ 200 15ms
```

### Custom Callbacks

```dart
app.use(logger(
  onRequest: (c) async {
    print('[${DateTime.now()}] --> ${c.req.method} ${c.req.uri}');
  },
  onResponse: (c, durationMs) async {
    final status = c.response?.statusCode ?? 0;
    print('[${DateTime.now()}] <-- ${c.req.method} ${c.req.uri} $status (${durationMs}ms)');
  },
));
```

### File Logging

```dart
import 'dart:io';

final logFile = File('server.log');

app.use(logger(
  onResponse: (c, durationMs) async {
    final timestamp = DateTime.now().toIso8601String();
    final status = c.response?.statusCode ?? 0;
    final entry = '$timestamp | ${c.req.method} ${c.req.uri} | $status | ${durationMs}ms\n';
    await logFile.writeAsString(entry, mode: FileMode.append);
  },
));
```

## API Reference

### `logger({onRequest, onResponse})`

Creates a logger middleware.

**Parameters:**
- `onRequest` (optional): `Future<void> Function(Context c)` - Callback invoked when a request is received
- `onResponse` (optional): `Future<void> Function(Context c, int durationMs)` - Callback invoked when a response is sent

**Returns:** `Middleware<E>`

If both parameters are omitted, default log output is used.

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.