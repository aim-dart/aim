import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:aim_core/aim_core.dart';
import 'package:aim_edge/src/bindings.dart';
import 'package:aim_edge/src/cf_properties.dart';
import 'package:aim_edge/src/edge_request.dart';

/// Access to the Cloudflare workerd runtime from a request handled by `aim_edge`.
extension EdgeContext<E extends Variables> on Context<E> {
  /// The worker's bindings object (`env`): vars, secrets, KV, D1, R2,
  /// Durable Object namespaces and service bindings.
  ///
  /// `null` when the request was not produced by the workerd adapter.
  /// Read a var or secret with `c.env?.string('GREETING')`, or a resource
  /// binding with `c.env?.get('MY_KV')`.
  Bindings? get env {
    final r = request.raw;
    return r is EdgeRawRequest ? Bindings(r.env) : null;
  }

  /// The worker's `ExecutionContext` (`ctx`), used for `waitUntil` and
  /// `passThroughOnException`. `null` outside workerd.
  JSObject? get executionContext {
    final r = request.raw;
    return r is EdgeRawRequest ? r.ctx : null;
  }

  /// Cloudflare's `request.cf` metadata (colo, country, coordinates, ...).
  ///
  /// `null` when the request was not produced by the workerd adapter, or
  /// when the runtime did not populate `cf` (e.g. some local dev setups).
  CfProperties? get cf {
    final r = request.raw;
    if (r is! EdgeRawRequest) return null;
    final value = r.request.getProperty('cf'.toJS);
    return value.isA<JSObject>() ? CfProperties(value as JSObject) : null;
  }
}
