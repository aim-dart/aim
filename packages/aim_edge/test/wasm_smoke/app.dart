// Compiled with `dart compile wasm` by wasm_smoke_test.dart.
import 'package:aim_core/aim_core.dart';
import 'package:aim_edge/aim_edge.dart';

void main() {
  final app = Aim();
  app.get('/env', (c) async => c.text('${c.req.workerEnv != null}'));
  app.get('/', (c) async => c.text('ok'));
  app.serveEdge();
}
