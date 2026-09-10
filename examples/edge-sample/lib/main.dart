import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:aim_edge/aim_edge.dart';
import 'package:aim_server_cors/aim_server_cors.dart';

void main() {
  final app = Aim();

  app.use(cors());

  app.get('/', (c) async => c.text('Hello from Dart on workerd'));

  app.get('/users/:id', (c) async => c.json({'id': c.param('id')}));

  app.post('/echo', (c) async {
    final body = await c.req.json();
    return c.json({'echo': body});
  });

  app.get('/headers', (c) async => c.json(c.headers));

  app.get('/cookies', (c) async {
    c.header('set-cookie', 'a=1; Path=/\nb=2; Path=/');
    return c.text('cookies set');
  });

  app.get('/sse', (c) async {
    final events = Stream<int>.periodic(
      const Duration(milliseconds: 100),
      (i) => i,
    ).take(3).map((i) => utf8.encode('data: tick $i\n\n'));
    return c.stream(
      events,
      headers: {
        'content-type': 'text/event-stream',
        'cache-control': 'no-cache',
      },
    );
  });

  app.get('/env', (c) async {
    final greeting =
        (c.req.workerEnv?.getProperty('GREETING'.toJS) as JSString?)?.toDart;
    return c.text(greeting ?? 'GREETING is not set');
  });

  app.get('/boom', (c) async => throw StateError('boom'));

  app.get('/not-modified', (c) async {
    c.header('etag', '"v1"');
    return c.text('', statusCode: 304);
  });

  app.notFound((c) async => c.json({'error': 'not found'}, statusCode: 404));

  app.onError((error, c) async {
    return c.json({'error': error.toString()}, statusCode: 500);
  });

  app.serveEdge();
}
