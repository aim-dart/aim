# aim_core

Platform-independent core of the Aim framework: routing, middleware, `Request`, `Response`, and `Context`. No `dart:io` dependency.

You usually do not depend on this package directly. Use [aim_server](https://pub.dev/packages/aim_server) to run on the Dart VM. Middleware packages depend on `aim_core` so they work on every runtime adapter.
