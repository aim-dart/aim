/// Cloudflare workerd adapter for the Aim framework.
///
/// Compile your application with `dart compile wasm` and call
/// [AimEdge.serveEdge] from `main()`. See the package README.
library;

export 'package:aim_core/aim_core.dart';
export 'src/bindings.dart' show Bindings;
export 'src/cf_properties.dart' show CfProperties;
export 'src/edge_context.dart' show EdgeContext;
export 'src/serve_edge.dart' show AimEdge;
