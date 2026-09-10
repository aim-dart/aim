/// Platform-independent core of the Aim web framework.
///
/// This library contains routing, middleware chaining, and the request and
/// response types. It does not depend on `dart:io`, so it can be compiled to
/// WebAssembly. Use `aim_server` to run on the Dart VM with `HttpServer`.
library;

export 'src/app.dart';
export 'src/body.dart';
export 'src/context.dart';
export 'src/variables.dart';
export 'src/message.dart';
export 'src/request.dart';
export 'src/response.dart';
export 'src/route.dart';
