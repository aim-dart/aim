import 'dart:convert';
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_static/aim_server_static.dart';
import 'package:test/test.dart';

void main() {
  group('serveStatic - Basic file serving', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.use(serveStatic('test/fixtures'));
      app.get('/api/test', (c) async => c.json({'message': 'API'}));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('serves existing file', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/test.txt'));
      final res = await response.close();

      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'text/plain');
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'Hello, World!\n');
    });

    test('serves HTML file with correct MIME type', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/index.html'));
      final res = await response.close();

      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'text/html');
    });

    test('serves CSS file with correct MIME type', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/style.css'));
      final res = await response.close();

      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'text/css');
    });

    test('passes to next handler for non-existent files', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/nonexistent.txt'));
      final res = await response.close();

      expect(res.statusCode, 404); // Default not found handler
    });

    test('allows API routes to work', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/api/test'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, contains('API'));
    });

    test('serves files from subdirectories', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/subdir/file.txt'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'Subdir file\n');
    });
  });

  group('serveStatic - Path prefix', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.use(serveStatic('test/fixtures', path: '/static'));
      app.get('/test.txt', (c) async => c.text('Not static'));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('serves file under prefix', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/static/test.txt'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'Hello, World!\n');
    });

    test('does not serve file without prefix', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/test.txt'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'Not static'); // Handler takes priority
    });
  });

  group('serveStatic - Index file support', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.use(serveStatic('test/fixtures', index: 'index.html'));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('serves index file for root directory', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, contains('<h1>Index</h1>'));
    });

    test('serves index file for subdirectory with trailing slash', () async {
      // Create index in subdir for this test
      await File('test/fixtures/subdir/index.html')
          .writeAsString('<h1>Subdir Index</h1>');

      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/subdir/'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, contains('Subdir Index'));

      // Cleanup
      await File('test/fixtures/subdir/index.html').delete();
    });
  });

  group('serveStatic - Dotfile protection', () {
    late Aim app;
    late AimHttpServer server;

    test('ignores dotfiles by default', () async {
      app = Aim();
      app.use(serveStatic('test/fixtures'));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);

      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/.env'));
      final res = await response.close();

      expect(res.statusCode, 404); // Ignored, passed to next handler

      await server.close();
    });

    test('denies dotfiles with DotFiles.deny', () async {
      app = Aim();
      app.use(serveStatic('test/fixtures', dotFiles: DotFiles.deny));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);

      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/.env'));
      final res = await response.close();

      expect(res.statusCode, 403); // Forbidden

      await server.close();
    });

    test('allows dotfiles with DotFiles.allow', () async {
      app = Aim();
      app.use(serveStatic('test/fixtures', dotFiles: DotFiles.allow));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);

      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/.env'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, contains('SECRET'));

      await server.close();
    });
  });

  group('serveStatic - Security', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.use(serveStatic('test/fixtures'));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('blocks path traversal with ../', () async {
      // Try to access parent directory
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/../pubspec.yaml'));
      final res = await response.close();

      // Should not serve files outside the root directory
      expect(res.statusCode, 404);
    });

    test('blocks accessing files outside root', () async {
      // This will be normalized by the server, but we test the behavior
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/../../README.md'));
      final res = await response.close();

      expect(res.statusCode, 404);
    });
  });
}
