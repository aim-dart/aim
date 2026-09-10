import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

Future<(T, List<String>)> capturePrint<T>(Future<T> Function() body) async {
  final lines = <String>[];
  final result = await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return (result, lines);
}

void main() {
  late HttpClient client;

  setUp(() => client = HttpClient());
  tearDown(() => client.close(force: true));

  Future<HttpClientResponse> send(
    int port,
    String method,
    String path, {
    Map<String, List<String>> headers = const {},
  }) async {
    final req = await client.openUrl(
      method,
      Uri.parse('http://localhost:$port$path'),
    );
    headers.forEach((k, values) {
      for (final v in values) {
        req.headers.add(k, v);
      }
    });
    return req.close();
  }

  // Sends a request whose header appears as genuinely separate raw header
  // lines (`X-Multi: a\r\nX-Multi: b\r\n...`), bypassing HttpClientRequest's
  // own header model. HttpClientRequest.headers.add coalesces repeated calls
  // for the same header name into a single wire line joined with ", "
  // before the request is ever sent, so it cannot exercise the adapter's
  // `values.join(',')` step over a multi-element value list. A raw socket
  // is required to produce the duplicate-line request the adapter is meant
  // to handle. Decodes the (chunked) response body.
  Future<String> sendRawMultiHeader(
    int port,
    String path,
    String headerName,
    List<String> values,
  ) async {
    final socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
    final headerLines = values.map((v) => '$headerName: $v\r\n').join();
    socket.write(
      'GET $path HTTP/1.1\r\n'
      'Host: localhost\r\n'
      '$headerLines'
      'Connection: close\r\n'
      '\r\n',
    );
    await socket.flush();
    final raw = await utf8.decoder.bind(socket).join();
    await socket.close();
    final headerEnd = raw.indexOf('\r\n\r\n');
    final body = raw.substring(headerEnd + 4);
    final lines = body.split('\r\n');
    final decoded = StringBuffer();
    for (var i = 0; i < lines.length;) {
      final sizeLine = lines[i].trim();
      i++;
      if (sizeLine.isEmpty) continue;
      final size = int.parse(sizeLine, radix: 16);
      if (size == 0) break;
      decoded.write(lines[i]);
      i++;
    }
    return decoded.toString();
  }

  group('dart:io adapter', () {
    test('joins multi-value request headers with a comma', () async {
      final app = Aim();
      app.get('/h', (c) async => c.text(c.headers['x-multi'] ?? ''));
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final body = await sendRawMultiHeader(server.port, '/h', 'X-Multi', [
        'a',
        'b',
      ]);

      expect(body, equals('a,b'));
    });

    test('builds an absolute request URI from the host header', () async {
      final app = Aim();
      app.get('/u', (c) async => c.text(c.req.uri.toString()));
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final res = await send(server.port, 'GET', '/u?q=1');

      expect(
        await utf8.decodeStream(res),
        equals('http://localhost:${server.port}/u?q=1'),
      );
    });

    test('exposes the HttpRequest through Request.httpRequest', () async {
      final app = Aim();
      app.get('/raw', (c) async {
        final raw = c.req.httpRequest;
        return c.text(raw == null ? 'null' : raw.method);
      });
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final res = await send(server.port, 'GET', '/raw');

      expect(await utf8.decodeStream(res), equals('GET'));
    });

    test('splits newline-joined Set-Cookie into separate headers', () async {
      final app = Aim();
      app.get(
        '/c',
        (c) async => Response.text(
          'ok',
          headers: {'set-cookie': 'a=1; Path=/\nb=2; Path=/'},
        ),
      );
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final res = await send(server.port, 'GET', '/c');
      await res.drain<void>();

      expect(res.headers['set-cookie'], hasLength(2));
      expect(res.headers['set-cookie'], contains('a=1; Path=/'));
      expect(res.headers['set-cookie'], contains('b=2; Path=/'));
    });

    test('prints unhandled errors and answers 500 when onError is unset',
        () async {
      final app = Aim();
      app.get('/boom', (c) async => throw Exception('boom'));

      final (res, printed) = await capturePrint(() async {
        final server =
            await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
        addTearDown(() => server.close(force: true));
        return send(server.port, 'GET', '/boom');
      });

      expect(res.statusCode, equals(500));
      expect(await utf8.decodeStream(res), contains('boom'));
      expect(printed.first, equals('Error: Exception: boom'));
      expect(printed.length, greaterThanOrEqualTo(2));
    });
  });
}
