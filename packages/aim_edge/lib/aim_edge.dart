/// Cloudflare workerd adapter for the Aim framework.
///
/// Compile your application with `dart compile wasm` and call
/// [AimEdge.serveEdge] from `main()`. See the package README.
library;

export 'src/edge_request.dart' show EdgeRequestAccess;
export 'src/serve_edge.dart' show AimEdge;
