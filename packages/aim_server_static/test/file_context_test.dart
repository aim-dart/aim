import 'dart:convert';
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_static/aim_server_static.dart';
import 'package:test/test.dart';

void main() {
  group('c.file() - Basic file serving', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.get('/file', (c) async => c.file('test/fixtures/test.txt'));
      app.get('/html', (c) async => c.file('test/fixtures/index.html'));
      app.get('/css', (c) async => c.file('test/fixtures/style.css'));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('serves file with correct content', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/file'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'Hello, World!\n');
    });

    test('serves file with correct MIME type - HTML', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/html'));
      final res = await response.close();

      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'text/html');
    });

    test('serves file with correct MIME type - CSS', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/css'));
      final res = await response.close();

      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'text/css');
    });

    test('sets Content-Length header', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/file'));
      final res = await response.close();

      expect(res.statusCode, 200);
      expect(res.headers.contentLength, greaterThan(0));
    });
  });

  group('c.file() - Download mode', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.get('/download', (c) async => c.file('test/fixtures/test.txt', download: true));
      app.get('/download-custom', (c) async => c.file(
        'test/fixtures/test.txt',
        download: true,
        filename: 'custom-name.txt',
      ));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('sets Content-Disposition header for download', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/download'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final contentDisposition = res.headers.value('content-disposition');
      expect(contentDisposition, contains('attachment'));
      expect(contentDisposition, contains('filename="test.txt"'));
    });

    test('uses custom filename for download', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/download-custom'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final contentDisposition = res.headers.value('content-disposition');
      expect(contentDisposition, contains('attachment'));
      expect(contentDisposition, contains('filename="custom-name.txt"'));
    });
  });

  group('c.file() - Error handling', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.get('/nonexistent', (c) async => c.file('test/fixtures/nonexistent.txt'));
      app.get('/directory', (c) async => c.file('test/fixtures/subdir'));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('returns 404 for non-existent file', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/nonexistent'));
      final res = await response.close();

      expect(res.statusCode, 404);
    });

    test('returns 404 for directory', () async {
      // Directories don't exist as files, so 404 is returned
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/directory'));
      final res = await response.close();

      expect(res.statusCode, 404); // Directory doesn't exist as a file
    });
  });

  group('c.file() - Security', () {
    test('returns 500 for absolute path', () async {
      final app = Aim();
      app.get('/absolute', (c) async => c.file('/etc/passwd'));
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);

      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/absolute'));
      final res = await response.close();

      // Aim's error handler catches ArgumentError and returns 500
      expect(res.statusCode, 500);

      await server.close();
    });

    test('returns 500 for path traversal', () async {
      final app = Aim();
      app.get('/traversal', (c) async => c.file('../../../etc/passwd'));
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);

      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/traversal'));
      final res = await response.close();

      // Aim's error handler catches ArgumentError and returns 500
      expect(res.statusCode, 500);

      await server.close();
    });
  });

  group('c.file() - Subdirectory access', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.get('/subdir', (c) async => c.file('test/fixtures/subdir/file.txt'));
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('serves file from subdirectory', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/subdir'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'Subdir file\n');
    });
  });

  group('c.file() - Path parameters', () {
    late Aim app;
    late AimHttpServer server;

    setUp(() async {
      app = Aim();
      app.get('/files/:filename', (c) async {
        final filename = c.param('filename');
        return c.file('test/fixtures/$filename');
      });
      app.get('/users/:id/avatar', (c) async {
        final id = c.param('id');
        return c.file('test/fixtures/subdir/$id.txt');
      });
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
    });

    tearDown(() async {
      await server.close();
    });

    test('serves file using path parameter', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/files/test.txt'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'Hello, World!\n');
    });

    test('serves different files based on parameter', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/files/style.css'));
      final res = await response.close();

      expect(res.statusCode, 200);
      expect(res.headers.contentType?.mimeType, 'text/css');
    });

    test('returns 404 for non-existent file via parameter', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/files/nonexistent.txt'));
      final res = await response.close();

      expect(res.statusCode, 404);
    });

    test('serves file with multiple path parameters', () async {
      // Create test file for this test
      await File('test/fixtures/subdir/user123.txt').writeAsString('User 123 avatar');

      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/users/user123/avatar'));
      final res = await response.close();

      expect(res.statusCode, 200);
      final body = await res.transform(const Utf8Decoder()).join();
      expect(body, 'User 123 avatar');

      // Cleanup
      await File('test/fixtures/subdir/user123.txt').delete();
    });

    test('blocks path traversal via parameter', () async {
      final response = await HttpClient()
          .getUrl(Uri.parse('http://localhost:${server.port}/files/..%2F..%2Fpubspec.yaml'));
      final res = await response.close();

      // Should either return 500 (path traversal detected) or 404 (file not found after normalization)
      expect([404, 500], contains(res.statusCode));
    });
  });
}
