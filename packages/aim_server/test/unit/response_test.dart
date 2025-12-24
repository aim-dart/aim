import 'dart:async';
import 'dart:convert';
import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Response - Status codes', () {
    test('Should accept valid status codes from 100 to 599', () {
      expect(() => Response.text('OK', statusCode: 100), returnsNormally);
      expect(() => Response.text('OK', statusCode: 200), returnsNormally);
      expect(() => Response.text('OK', statusCode: 300), returnsNormally);
      expect(() => Response.text('OK', statusCode: 400), returnsNormally);
      expect(() => Response.text('OK', statusCode: 500), returnsNormally);
      expect(() => Response.text('OK', statusCode: 599), returnsNormally);
    });

    test('Should reject status codes below 100', () {
      expect(() => Response.text('Bad', statusCode: 99), throwsArgumentError);
      expect(() => Response.text('Bad', statusCode: 0), throwsArgumentError);
      expect(() => Response.text('Bad', statusCode: -1), throwsArgumentError);
    });

    test('Should handle informational status codes (1xx)', () {
      final response = Response.text('Continue', statusCode: 100);
      expect(response.statusCode, equals(100));
    });

    test('Should handle success status codes (2xx)', () {
      final response1 = Response.text('OK', statusCode: 200);
      expect(response1.statusCode, equals(200));

      final response2 = Response.text('Created', statusCode: 201);
      expect(response2.statusCode, equals(201));

      final response3 = Response.text('', statusCode: 204);
      expect(response3.statusCode, equals(204));
    });

    test('Should handle redirection status codes (3xx)', () {
      final response = Response.redirect('/new-path', 301);
      expect(response.statusCode, equals(301));
    });

    test('Should handle client error status codes (4xx)', () {
      final response1 = Response.text('Bad Request', statusCode: 400);
      expect(response1.statusCode, equals(400));

      final response2 = Response.notFound();
      expect(response2.statusCode, equals(404));
    });

    test('Should handle server error status codes (5xx)', () {
      final response1 = Response.internalServerError();
      expect(response1.statusCode, equals(500));

      final response2 = Response.text('Bad Gateway', statusCode: 502);
      expect(response2.statusCode, equals(502));
    });
  });

  group('Response - JSON responses', () {
    test('Should create JSON response with correct Content-Type', () {
      final response = Response.json(body: {'message': 'hello'});
      expect(response.headers['content-type'], equals('application/json'));
    });

    test('Should serialize objects to JSON', () async {
      final response = Response.json(
        body: {'name': 'Alice', 'age': 30, 'active': true},
      );
      final body = await response.readAsString();
      expect(body, equals('{"name":"Alice","age":30,"active":true}'));
    });

    test('Should handle nested objects in JSON', () async {
      final response = Response.json(
        body: {
          'user': {
            'name': 'Bob',
            'address': {'city': 'Tokyo'},
          },
        },
      );
      final body = await response.readAsString();
      expect(
        body,
        equals('{"user":{"name":"Bob","address":{"city":"Tokyo"}}}'),
      );
    });

    test('Should handle arrays in JSON', () async {
      final response = Response.json(
        body: {
          'items': [1, 2, 3],
        },
      );
      final body = await response.readAsString();
      expect(body, equals('{"items":[1,2,3]}'));
    });

    test('Should allow custom status code for JSON response', () {
      final response = Response.json(
        body: {'message': 'Created'},
        statusCode: 201,
      );
      expect(response.statusCode, equals(201));
    });

    test('Should allow custom headers for JSON response', () {
      final response = Response.json(
        body: {'message': 'hello'},
        headers: {'X-Custom-Header': 'value'},
      );
      expect(response.headers['X-Custom-Header'], equals('value'));
    });

    test('Should default to status code 200 for JSON response', () {
      final response = Response.json(body: {'message': 'OK'});
      expect(response.statusCode, equals(200));
    });
  });

  group('Response - Text responses', () {
    test('Should create text response with correct Content-Type', () {
      final response = Response.text('Hello, World!');
      expect(
        response.headers['content-type'],
        equals('text/plain; charset=utf-8'),
      );
    });

    test('Should include charset in Content-Type', () {
      final response = Response.text('Plain text');
      expect(response.headers['content-type'], contains('charset=utf-8'));
    });

    test('Should handle Unicode text', () async {
      final response = Response.text('こんにちは世界 🌍');
      final body = await response.readAsString();
      expect(body, equals('こんにちは世界 🌍'));
    });

    test('Should allow custom status code for text response', () {
      final response = Response.text('Not Found', statusCode: 404);
      expect(response.statusCode, equals(404));
    });

    test('Should allow custom headers for text response', () {
      final response = Response.text(
        'Hello',
        headers: {'X-Custom-Header': 'value'},
      );
      expect(response.headers['X-Custom-Header'], equals('value'));
    });

    test('Should default to status code 200 for text response', () {
      final response = Response.text('OK');
      expect(response.statusCode, equals(200));
    });

    test('Should handle empty text', () async {
      final response = Response.text('');
      final body = await response.readAsString();
      expect(body, equals(''));
    });
  });

  group('Response - Redirect responses', () {
    test('Should create 302 redirect by default', () {
      final response = Response.redirect('/new-page');
      expect(response.statusCode, equals(302));
    });

    test('Should set Location header for redirect', () {
      final response = Response.redirect('/login');
      expect(response.headers['location'], equals('/login'));
    });

    test('Should support 301 permanent redirect', () {
      final response = Response.redirect('/new-page', 301);
      expect(response.statusCode, equals(301));
      expect(response.headers['location'], equals('/new-page'));
    });

    test('Should support 303 See Other redirect', () {
      final response = Response.redirect('/other', 303);
      expect(response.statusCode, equals(303));
    });

    test('Should support 307 Temporary Redirect', () {
      final response = Response.redirect('/temp', 307);
      expect(response.statusCode, equals(307));
    });

    test('Should support 308 Permanent Redirect', () {
      final response = Response.redirect('/permanent', 308);
      expect(response.statusCode, equals(308));
    });

    test('Should reject non-3xx status codes for redirect', () {
      expect(() => Response.redirect('/page', 200), throwsArgumentError);
      expect(() => Response.redirect('/page', 299), throwsArgumentError);
      expect(() => Response.redirect('/page', 400), throwsArgumentError);
    });

    test('Should handle relative and absolute URLs', () {
      final response1 = Response.redirect('/relative/path');
      expect(response1.headers['location'], equals('/relative/path'));

      final response2 = Response.redirect('https://example.com/absolute');
      expect(
        response2.headers['location'],
        equals('https://example.com/absolute'),
      );
    });

    test('Should have empty body for redirect', () async {
      final response = Response.redirect('/new-page');
      final body = await response.readAsString();
      expect(body, equals(''));
    });
  });

  group('Response - Stream responses', () {
    test('Should create streaming response', () {
      final stream = Stream<List<int>>.fromIterable([
        [1, 2, 3],
        [4, 5, 6],
      ]);
      final response = Response.stream(stream);
      expect(response.statusCode, equals(200));
    });

    test('Should allow custom status code for stream response', () {
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final response = Response.stream(stream, statusCode: 201);
      expect(response.statusCode, equals(201));
    });

    test('Should set custom headers for stream response', () {
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final response = Response.stream(
        stream,
        headers: {'content-type': 'image/png'},
      );
      expect(response.headers['content-type'], equals('image/png'));
    });

    test('Should handle binary streams', () async {
      final bytes = [137, 80, 78, 71]; // PNG header
      final stream = Stream<List<int>>.value(bytes);
      final response = Response.stream(stream);
      final result = await response.read().first;
      expect(result, equals(bytes));
    });
  });

  group('Response - Special responses', () {
    test('Should create 404 Not Found response', () {
      final response = Response.notFound();
      expect(response.statusCode, equals(404));
    });

    test('Should use default body for 404', () async {
      final response = Response.notFound();
      final body = await response.readAsString();
      expect(body, equals('Not Found'));
    });

    test('Should allow custom body for 404', () async {
      final response = Response.notFound(body: 'Page not found');
      final body = await response.readAsString();
      expect(body, equals('Page not found'));
    });

    test('Should create 500 Internal Server Error response', () {
      final response = Response.internalServerError();
      expect(response.statusCode, equals(500));
    });

    test('Should use default body for 500', () async {
      final response = Response.internalServerError();
      final body = await response.readAsString();
      expect(body, equals('Internal Server Error'));
    });

    test('Should allow custom body for 500', () async {
      final response = Response.internalServerError(body: 'Error occurred');
      final body = await response.readAsString();
      expect(body, equals('Error occurred'));
    });

    test('Should allow custom headers for special responses', () {
      final response = Response.notFound(
        headers: {'X-Error-Code': 'NOT_FOUND'},
      );
      expect(response.headers['X-Error-Code'], equals('NOT_FOUND'));
    });
  });

  group('Response - Body handling', () {
    test('Should handle string body', () async {
      final response = Response.text('Hello');
      final body = await response.readAsString();
      expect(body, equals('Hello'));
    });

    test('Should handle null body with default message', () async {
      final response = Response.notFound(body: null);
      final body = await response.readAsString();
      // notFound uses 'Not Found' as default when body is null
      expect(body, equals('Not Found'));
    });

    test('Should only allow reading body once', () async {
      final response = Response.text('Once');
      await response.readAsString(); // First read

      expect(
        () => response.read(), // Second read
        throwsStateError,
      );
    });

    test('Should calculate content length for string body', () {
      final response = Response.text('Hello');
      expect(response.body.contentLength, isNotNull);
      expect(response.body.contentLength, greaterThan(0));
    });

    test('Should leave content length null for streams', () {
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final response = Response.stream(stream);
      expect(response.body.contentLength, isNull);
    });

    test('Should handle UTF-8 encoding correctly', () async {
      final response = Response.text('Hello 世界');
      final body = await response.readAsString(utf8);
      expect(body, equals('Hello 世界'));
    });

    test('Should support custom context', () {
      final response = Response.text('Hello', context: {'key': 'value'});
      expect(response.context['key'], equals('value'));
    });
  });

  group('Response - Header merging', () {
    test('Should allow overriding default Content-Type', () {
      final response = Response.json(
        body: {'message': 'hello'},
        headers: {'content-type': 'application/custom+json'},
      );
      expect(
        response.headers['content-type'],
        equals('application/custom+json'),
      );
    });

    test('Should merge custom headers with default headers', () {
      final response = Response.text('Hello', headers: {'X-Custom': 'value'});
      expect(
        response.headers['content-type'],
        equals('text/plain; charset=utf-8'),
      );
      expect(response.headers['X-Custom'], equals('value'));
    });

    test('Should preserve all custom headers', () {
      final response = Response.json(
        body: {},
        headers: {'X-Header-1': 'value1', 'X-Header-2': 'value2'},
      );
      expect(response.headers['X-Header-1'], equals('value1'));
      expect(response.headers['X-Header-2'], equals('value2'));
    });
  });
}
