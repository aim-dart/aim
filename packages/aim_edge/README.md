# aim_edge

Run an [Aim](https://pub.dev/packages/aim_core) application on Cloudflare workerd (Cloudflare Workers), compiled to WebAssembly with `dart compile wasm`.

```dart
import 'package:aim_core/aim_core.dart';
import 'package:aim_edge/aim_edge.dart';

void main() {
  final app = Aim();
  app.get('/', (c) async => c.text('Hello from Dart on workerd'));
  app.serveEdge();
}
```

`serveEdge()` registers `globalThis.__aimFetch`. A small JS entry module instantiates the wasm module on the first request and forwards `fetch(request, env, ctx)` to it. See `examples/edge-sample` in the repository for the build script, `wrangler.jsonc`, and the entry module.

Worker bindings and the execution context are available as raw `JSObject`s via `c.req.workerEnv` and `c.req.workerContext`; type them with `dart:js_interop` in your application.
