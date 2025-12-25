import 'dart:convert';
import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_form/aim_form.dart';
import 'package:test/test.dart';

void main() {
  group('Integration - Aim server with form data', () {
    late Aim app;
    late dynamic server;
    late int port;

    setUp(() async {
      app = Aim();
      server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      port = server.port;
    });

    tearDown(() async {
      await server.close();
    });

    test('Should handle POST request with form data', () async {
      app.post('/login', (c) async {
        final form = await c.req.formData();
        final username = form['username'];
        final password = form['password'];

        return c.json({
          'success': true,
          'username': username,
          'passwordLength': password?.length,
        });
      });

      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://localhost:$port/login'),
        );
        request.headers.set(
          'Content-Type',
          'application/x-www-form-urlencoded',
        );
        request.write('username=alice&password=secret123');

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, equals(200));
        expect(body, contains('"success":true'));
        expect(body, contains('"username":"alice"'));
        expect(body, contains('"passwordLength":9'));
      } finally {
        client.close();
      }
    });

    test('Should work with middleware', () async {
      // Logging middleware
      final logs = <String>[];
      app.use((c, next) async {
        logs.add('Before handler');
        await next();
        logs.add('After handler');
      });

      app.post('/test', (c) async {
        final form = await c.req.formData();
        return c.json({'field': form['field']});
      });

      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://localhost:$port/test'),
        );
        request.headers.set(
          'Content-Type',
          'application/x-www-form-urlencoded',
        );
        request.write('field=value');

        final response = await request.close();
        await response.drain();

        expect(logs, equals(['Before handler', 'After handler']));
      } finally {
        client.close();
      }
    });

    test('Should handle Content-Type with charset', () async {
      app.post('/test', (c) async {
        final form = await c.req.formData();
        return c.json({'name': form['name']});
      });

      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://localhost:$port/test'),
        );
        request.headers.set(
          'Content-Type',
          'application/x-www-form-urlencoded; charset=utf-8',
        );
        request.write('name=%E5%A4%AA%E9%83%8E'); // 太郎

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, equals(200));
        expect(body, contains('太郎'));
      } finally {
        client.close();
      }
    });

    test('Should return error for wrong Content-Type', () async {
      app.post('/test', (c) async {
        try {
          await c.req.formData();
          return c.text('Should not reach here');
        } catch (e) {
          return c.json({'error': e.toString()}, statusCode: 400);
        }
      });

      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://localhost:$port/test'),
        );
        request.headers.set('Content-Type', 'application/json');
        request.write('{"username":"alice"}');

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, equals(400));
        expect(body, contains('error'));
        expect(body, contains('FormatException'));
      } finally {
        client.close();
      }
    });

    test('Should handle empty form data', () async {
      app.post('/test', (c) async {
        final form = await c.req.formData();
        return c.json({
          'isEmpty': form.keys.isEmpty,
          'keysCount': form.keys.length,
        });
      });

      final client = HttpClient();
      try {
        final request = await client.postUrl(
          Uri.parse('http://localhost:$port/test'),
        );
        request.headers.set(
          'Content-Type',
          'application/x-www-form-urlencoded',
        );
        request.write('');

        final response = await request.close();
        final body = await response.transform(utf8.decoder).join();

        expect(response.statusCode, equals(200));
        expect(body, contains('"isEmpty":true'));
        expect(body, contains('"keysCount":0'));
      } finally {
        client.close();
      }
    });

    test('Should handle multiple form submissions', () async {
      var requestCount = 0;

      app.post('/test', (c) async {
        requestCount++;
        final form = await c.req.formData();
        return c.json({
          'requestNumber': requestCount,
          'username': form['username'],
        });
      });

      final client = HttpClient();
      try {
        // First request
        var request = await client.postUrl(
          Uri.parse('http://localhost:$port/test'),
        );
        request.headers.set(
          'Content-Type',
          'application/x-www-form-urlencoded',
        );
        request.write('username=alice');
        var response = await request.close();
        await response.drain();

        // Second request
        request = await client.postUrl(
          Uri.parse('http://localhost:$port/test'),
        );
        request.headers.set(
          'Content-Type',
          'application/x-www-form-urlencoded',
        );
        request.write('username=bob');
        response = await request.close();
        await response.drain();

        expect(requestCount, equals(2));
      } finally {
        client.close();
      }
    });
  });
}
