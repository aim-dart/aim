// Compiled with `dart compile wasm` by wasm_smoke_test.dart.
// If aim_core ever imports dart:io, this compilation fails.
import 'package:aim_core/aim_core.dart';

void main() {
  final app = Aim();
  app.use((c, next) async {
    c.header('x-smoke', '1');
    await next();
  });
  app.get('/users/:id', (c) async => c.json({'id': c.param('id')}));
  app.handle(Request('GET', Uri.parse('http://localhost/users/1')));
}
