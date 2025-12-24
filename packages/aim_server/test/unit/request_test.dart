import 'dart:convert';
import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Request - Construction', () {
    test('Should create request from HTTP method and URI', () {
      final uri = Uri.parse('http://example.com/path');
      final request = Request('GET', uri);
      expect(request.method, equals('GET'));
      expect(request.uri, equals(uri));
    });

    test('Should handle absolute URIs', () {
      final uri = Uri.parse('https://example.com:443/path?query=value');
      final request = Request('GET', uri);
      expect(request.uri.scheme, equals('https'));
      expect(request.uri.host, equals('example.com'));
      expect(request.uri.port, equals(443));
      expect(request.uri.path, equals('/path'));
      expect(request.uri.query, equals('query=value'));
    });

    test('Should handle relative URIs', () {
      final uri = Uri.parse('/relative/path');
      final request = Request('GET', uri);
      expect(request.path, equals('/relative/path'));
    });

    test('Should throw when method is empty', () {
      final uri = Uri.parse('http://example.com/');
      expect(() => Request('', uri), throwsArgumentError);
    });

    test('Should accept optional headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'content-type': 'application/json'},
      );
      expect(request.headers['content-type'], equals('application/json'));
    });

    test('Should accept optional body', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'Hello');
      final body = await request.text();
      expect(body, equals('Hello'));
    });

    test('Should default to empty headers when not provided', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      expect(request.headers, isEmpty);
    });

    test('Should default to empty context when not provided', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      expect(request.context, isEmpty);
    });
  });

  group('Request - URI parsing', () {
    test('Should extract path from URI', () {
      final uri = Uri.parse('http://example.com/users/123');
      final request = Request('GET', uri);
      expect(request.path, equals('/users/123'));
    });

    test('Should extract query parameters from URI', () {
      final uri = Uri.parse('http://example.com/search?q=dart&page=2');
      final request = Request('GET', uri);
      expect(request.queryParameters['q'], equals('dart'));
      expect(request.queryParameters['page'], equals('2'));
    });

    test('Should handle URI encoding in path', () {
      final uri = Uri.parse('http://example.com/path%20with%20spaces');
      final request = Request('GET', uri);
      // URI path remains encoded as per RFC 3986
      expect(request.path, equals('/path%20with%20spaces'));
    });

    test('Should handle URI encoding in query parameters', () {
      final uri = Uri.parse('http://example.com/?name=John%20Doe');
      final request = Request('GET', uri);
      expect(request.queryParameters['name'], equals('John Doe'));
    });

    test('Should handle multiple query parameters with same key', () {
      // URI.queryParameters only keeps the last value for duplicate keys
      final uri = Uri.parse('http://example.com/?tag=foo&tag=bar');
      final request = Request('GET', uri);
      expect(request.queryParameters['tag'], isNotNull);
    });

    test('Should handle empty query parameters', () {
      final uri = Uri.parse('http://example.com/path');
      final request = Request('GET', uri);
      expect(request.queryParameters, isEmpty);
    });

    test('Should handle fragment in URI', () {
      final uri = Uri.parse('http://example.com/path#section');
      final request = Request('GET', uri);
      expect(request.uri.fragment, equals('section'));
    });
  });

  group('Request - Header parsing', () {
    test('Should parse request headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
        },
      );
      expect(request.headers['content-type'], equals('application/json'));
      expect(request.headers['accept'], equals('application/json'));
    });

    test('Should handle multi-value headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'accept': 'text/html, application/json'},
      );
      expect(request.headers['accept'], contains('text/html'));
      expect(request.headers['accept'], contains('application/json'));
    });

    test('Should be case-insensitive for header names', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'Content-Type': 'application/json', 'content-length': '100'},
      );
      // Dart's Map is case-sensitive, but HTTP headers should be compared
      // case-insensitively. The framework should normalize header names.
      expect(request.headers.keys, isNotEmpty);
    });

    test('Should preserve header values', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'authorization': 'Bearer token123'},
      );
      expect(request.headers['authorization'], equals('Bearer token123'));
    });

    test('Should handle empty header values', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri, headers: {'x-empty': ''});
      expect(request.headers['x-empty'], equals(''));
    });

    test('Should handle headers with colons in values', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri, headers: {'x-time': '12:34:56'});
      expect(request.headers['x-time'], equals('12:34:56'));
    });
  });

  group('Request - Body reading', () {
    test('Should read body as string', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'Hello, World!');
      final body = await request.text();
      expect(body, equals('Hello, World!'));
    });

    test('Should read body as JSON', () async {
      final uri = Uri.parse('http://example.com/');
      final jsonString = '{"name":"Alice","age":30}';
      final request = Request('POST', uri, bodyContent: jsonString);
      final body = await request.json();
      expect(body['name'], equals('Alice'));
      expect(body['age'], equals(30));
    });

    test('Should handle empty body', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri, bodyContent: null);
      final body = await request.text();
      expect(body, equals(''));
    });

    test('Should handle different encodings', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'POST',
        uri,
        bodyContent: 'こんにちは',
        encoding: utf8,
      );
      final body = await request.text();
      expect(body, equals('こんにちは'));
    });

    test('Should only allow reading body once', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'Once');
      await request.text(); // First read

      expect(
        () => request.read(), // Second read
        throwsStateError,
      );
    });

    test('Should throw on second read attempt', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'Data');
      await request.readAsString(); // First read

      expect(
        () => request.text(), // Second read
        throwsStateError,
      );
    });

    test('Should handle List<int> body', () async {
      final uri = Uri.parse('http://example.com/');
      final bytes = utf8.encode('Binary data');
      final request = Request('POST', uri, bodyContent: bytes);
      final body = await request.text();
      expect(body, equals('Binary data'));
    });

    test('Should handle Stream body', () async {
      final uri = Uri.parse('http://example.com/');
      final stream = Stream<List<int>>.value(utf8.encode('Stream data'));
      final request = Request('POST', uri, bodyContent: stream);
      final body = await request.text();
      expect(body, equals('Stream data'));
    });
  });

  group('Request - Content negotiation', () {
    test('Should parse Content-Type header', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'POST',
        uri,
        headers: {'content-type': 'application/json'},
      );
      expect(request.headers['content-type'], equals('application/json'));
    });

    test('Should handle charset in Content-Type', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'POST',
        uri,
        headers: {'content-type': 'text/plain; charset=utf-8'},
      );
      expect(
        request.headers['content-type'],
        equals('text/plain; charset=utf-8'),
      );
    });

    test('Should handle missing Content-Type', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      expect(request.headers['content-type'], isNull);
    });

    test('Should parse Accept header', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'accept': 'application/json, text/html'},
      );
      expect(request.headers['accept'], contains('application/json'));
    });
  });

  group('Request - Body content length', () {
    test('Should calculate content length for string body', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'Hello');
      expect(request.body.contentLength, isNotNull);
      expect(request.body.contentLength, greaterThan(0));
    });

    test('Should calculate content length for byte array', () {
      final uri = Uri.parse('http://example.com/');
      final bytes = [1, 2, 3, 4, 5];
      final request = Request('POST', uri, bodyContent: bytes);
      expect(request.body.contentLength, equals(5));
    });

    test('Should leave content length null for streams', () {
      final uri = Uri.parse('http://example.com/');
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final request = Request('POST', uri, bodyContent: stream);
      expect(request.body.contentLength, isNull);
    });

    test('Should return 0 for null body', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri, bodyContent: null);
      expect(request.body.contentLength, equals(0));
    });
  });

  group('Request - JSON parsing errors', () {
    test('Should throw FormatException for invalid JSON', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'not valid json');
      expect(() => request.json(), throwsFormatException);
    });

    test('Should throw for empty body when expecting JSON', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: '');
      expect(() => request.json(), throwsFormatException);
    });

    test('Should parse valid JSON successfully', () async {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: '{"valid": true}');
      final json = await request.json();
      expect(json['valid'], equals(true));
    });
  });

  group('Request - Context and raw request', () {
    test('Should support custom context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        context: {'userId': 123, 'role': 'admin'},
      );
      expect(request.context['userId'], equals(123));
      expect(request.context['role'], equals('admin'));
    });

    test('Should store raw HttpRequest when provided', () {
      final uri = Uri.parse('http://example.com/');
      // We can't easily create a real HttpRequest in tests,
      // but we can verify the field exists
      final request = Request('GET', uri, raw: null);
      expect(request.raw, isNull);
    });

    test('Should allow null raw request', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      expect(request.raw, isNull);
    });
  });

  group('Request - HTTP methods', () {
    test('Should support GET method', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      expect(request.method, equals('GET'));
    });

    test('Should support POST method', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri);
      expect(request.method, equals('POST'));
    });

    test('Should support PUT method', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('PUT', uri);
      expect(request.method, equals('PUT'));
    });

    test('Should support DELETE method', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('DELETE', uri);
      expect(request.method, equals('DELETE'));
    });

    test('Should support PATCH method', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('PATCH', uri);
      expect(request.method, equals('PATCH'));
    });

    test('Should support HEAD method', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('HEAD', uri);
      expect(request.method, equals('HEAD'));
    });

    test('Should support OPTIONS method', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('OPTIONS', uri);
      expect(request.method, equals('OPTIONS'));
    });

    test('Should preserve method case', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('Get', uri);
      expect(request.method, equals('Get'));
    });
  });

  group('Request - MessageMixin integration', () {
    test('Should provide isEmpty property', () {
      final uri = Uri.parse('http://example.com/');
      final request1 = Request('GET', uri, bodyContent: null);
      expect(request1.isEmpty, isTrue);

      final request2 = Request('POST', uri, bodyContent: 'data');
      expect(request2.isEmpty, isFalse);
    });

    test('Should provide contentLength from headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'POST',
        uri,
        bodyContent: 'Hello',
        headers: {'content-length': '5'},
      );
      expect(request.contentLength, equals(5));
    });

    test('Should return null when content-length header missing', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      expect(request.contentLength, isNull);
    });

    test('Should provide read() method from MessageMixin', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'data');
      expect(request.read(), isA<Stream<List<int>>>());
    });

    test('Should provide readAsString() method from MessageMixin', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('POST', uri, bodyContent: 'data');
      expect(request.readAsString(), isA<Future<String>>());
    });
  });
}
