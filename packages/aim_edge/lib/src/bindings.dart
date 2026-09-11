import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// The worker's bindings object (`env`): vars, secrets and resource bindings
/// (KV, D1, R2, Durable Objects, service bindings). Hono calls this Bindings.
class Bindings {
  /// The underlying JS object, for bindings this class does not type.
  final JSObject raw;

  Bindings(this.raw);

  /// A string var or secret, or `null` when absent or not a string.
  String? string(String name) {
    final value = raw.getProperty(name.toJS);
    return value.isA<JSString>() ? (value as JSString).toDart : null;
  }

  /// A resource binding (KV namespace, D1 database, ...), or `null` when
  /// absent or not an object. Use `dart:js_interop` to call it.
  JSObject? get(String name) {
    final value = raw.getProperty(name.toJS);
    return value.isA<JSObject>() ? value as JSObject : null;
  }

  /// Whether [name] exists on the bindings object.
  bool has(String name) => raw.has(name);
}
