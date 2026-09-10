import 'dart:js_interop';

import 'package:aim_core/aim_core.dart';
import 'package:aim_edge/src/edge_request.dart';

/// Access to the Cloudflare workerd runtime from a request handled by `aim_edge`.
extension EdgeContext<E extends Variables> on Context<E> {
  /// The worker's bindings object (`env`): vars, secrets, KV, D1, R2,
  /// Durable Object namespaces and service bindings.
  ///
  /// `null` when the request was not produced by the workerd adapter.
  /// Type it in your application with `dart:js_interop`, for example
  /// `(c.env?.getProperty('GREETING'.toJS) as JSString?)?.toDart`.
  JSObject? get env {
    final r = request.raw;
    return r is EdgeRawRequest ? r.env : null;
  }

  /// The worker's `ExecutionContext` (`ctx`), used for `waitUntil` and
  /// `passThroughOnException`. `null` outside workerd.
  JSObject? get executionContext {
    final r = request.raw;
    return r is EdgeRawRequest ? r.ctx : null;
  }
}
