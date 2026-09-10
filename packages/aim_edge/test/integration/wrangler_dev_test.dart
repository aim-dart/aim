import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

/// Path of examples/edge-sample relative to packages/aim_edge (the CWD of
/// `dart test`).
const _exampleDir = '../../examples/edge-sample';

Future<int> _freePort() async {
  final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = socket.port;
  await socket.close();
  return port;
}

Future<void> _waitUntilReady(HttpClient client, int port) async {
  final deadline = DateTime.now().add(const Duration(seconds: 90));
  while (DateTime.now().isBefore(deadline)) {
    try {
      final req = await client.getUrl(Uri.parse('http://localhost:$port/'));
      final res = await req.close();
      await res.drain<void>();
      if (res.statusCode == 200) return;
    } catch (_) {
      // not up yet
    }
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
  throw StateError('wrangler dev did not become ready on port $port');
}

/// `npx wrangler dev` forks a chain of processes (npm exec -> node
/// wrangler-dist/cli.js -> workerd) that do not reliably exit when only the
/// top-level process receives SIGTERM. Recursively SIGKILLs the whole
/// subtree rooted at [pid] so no wrangler/workerd process outlives the test.
Future<void> _killProcessTree(int pid) async {
  final children = await Process.run('pgrep', ['-P', '$pid']);
  final childPids = (children.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map(int.parse);
  for (final child in childPids) {
    await _killProcessTree(child);
  }
  await Process.run('kill', ['-9', '$pid']);
}

void main() {
  late int port;
  late Process wrangler;
  late HttpClient client;
  final wranglerOutput = StringBuffer();

  setUpAll(() async {
    final build = await Process.run(Platform.resolvedExecutable, [
      'run',
      'tool/build.dart',
    ], workingDirectory: _exampleDir);
    expect(
      build.exitCode,
      equals(0),
      reason: 'build failed:\n${build.stdout}\n${build.stderr}',
    );

    port = await _freePort();
    wrangler = await Process.start('npx', [
      '--yes',
      'wrangler',
      'dev',
      '--port',
      '$port',
      '--log-level',
      'error',
    ], workingDirectory: _exampleDir);
    wrangler.stdout.transform(utf8.decoder).listen(wranglerOutput.write);
    wrangler.stderr.transform(utf8.decoder).listen(wranglerOutput.write);

    client = HttpClient();
    try {
      await _waitUntilReady(client, port);
    } catch (e) {
      fail('$e\nwrangler output:\n$wranglerOutput');
    }
  });

  tearDownAll(() async {
    client.close(force: true);
    wrangler.kill(ProcessSignal.sigterm);
    await wrangler.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () => -1,
    );
    // SIGTERM to the top-level `npx` process does not reliably propagate
    // through the npm exec -> wrangler cli -> workerd process chain, so
    // force-kill any survivors by process tree and, as a last resort, by
    // whatever is still listening on the dev port.
    await _killProcessTree(wrangler.pid);
    await Process.run('sh', [
      '-c',
      'lsof -ti tcp:$port | xargs kill -9 2>/dev/null; true',
    ]);
  });

  Future<HttpClientResponse> get(
    String path, {
    Map<String, String>? headers,
  }) async {
    final req = await client.getUrl(Uri.parse('http://localhost:$port$path'));
    headers?.forEach(req.headers.set);
    return req.close();
  }

  test('serves text', () async {
    final res = await get('/');
    expect(res.statusCode, 200);
    expect(await utf8.decodeStream(res), 'Hello from Dart on workerd');
  });

  test('routes path parameters to JSON', () async {
    final res = await get('/users/42');
    expect(res.statusCode, 200);
    expect(res.headers.contentType?.mimeType, 'application/json');
    expect(jsonDecode(await utf8.decodeStream(res)), {'id': '42'});
  });

  test('reads a JSON request body', () async {
    final req = await client.postUrl(Uri.parse('http://localhost:$port/echo'));
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'a': 1, 'b': 'two'}));
    final res = await req.close();
    expect(res.statusCode, 200);
    expect(jsonDecode(await utf8.decodeStream(res)), {
      'echo': {'a': 1, 'b': 'two'},
    });
  });

  test('exposes request headers', () async {
    final res = await get('/headers', headers: {'x-probe': 'yes'});
    final body = jsonDecode(await utf8.decodeStream(res)) as Map;
    expect(body['x-probe'], 'yes');
  });

  test('sends multiple Set-Cookie headers', () async {
    final res = await get('/cookies');
    await res.drain<void>();
    expect(res.headers['set-cookie'], hasLength(2));
    expect(res.headers['set-cookie'], contains('a=1; Path=/'));
    expect(res.headers['set-cookie'], contains('b=2; Path=/'));
  });

  test('applies the cors middleware', () async {
    final res = await get('/', headers: {'origin': 'https://example.com'});
    await res.drain<void>();
    expect(res.headers.value('access-control-allow-origin'), '*');
  });

  test('reads worker bindings through workerEnv', () async {
    final res = await get('/env');
    expect(await utf8.decodeStream(res), 'hello from workerd');
  });

  test('uses the custom 404 handler', () async {
    final res = await get('/nope');
    expect(res.statusCode, 404);
    expect(jsonDecode(await utf8.decodeStream(res)), {'error': 'not found'});
  });

  test('uses the custom error handler', () async {
    final res = await get('/boom');
    expect(res.statusCode, 500);
    final body = jsonDecode(await utf8.decodeStream(res)) as Map;
    expect(body['error'], contains('boom'));
  });

  test('streams SSE events instead of buffering them', () async {
    final res = await get('/sse');
    expect(res.headers.contentType?.mimeType, 'text/event-stream');

    final arrivals = <DateTime>[];
    final chunks = <String>[];
    await for (final chunk in res.transform(utf8.decoder)) {
      arrivals.add(DateTime.now());
      chunks.add(chunk);
    }

    final text = chunks.join();
    expect(text, contains('data: tick 0'));
    expect(text, contains('data: tick 2'));
    expect(
      arrivals.length,
      greaterThanOrEqualTo(2),
      reason: 'events arrived in a single chunk: $text',
    );
    final spread = arrivals.last.difference(arrivals.first);
    expect(
      spread,
      greaterThan(const Duration(milliseconds: 100)),
      reason: 'events were buffered and flushed together',
    );
  });
}
