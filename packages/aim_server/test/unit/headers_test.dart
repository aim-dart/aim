import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Headers - Request headers', () {
    test('Should parse standard headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {
          'content-type': 'application/json',
          'accept': 'application/json',
          'user-agent': 'Test/1.0',
        },
      );
      expect(request.headers['content-type'], equals('application/json'));
      expect(request.headers['accept'], equals('application/json'));
      expect(request.headers['user-agent'], equals('Test/1.0'));
    });

    test('Should handle custom headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'X-Custom-Header': 'custom-value', 'X-Request-ID': '12345'},
      );
      expect(request.headers['X-Custom-Header'], equals('custom-value'));
      expect(request.headers['X-Request-ID'], equals('12345'));
    });

    test('Should handle multi-value headers joined by comma', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'accept': 'text/html, application/json, application/xml'},
      );
      expect(request.headers['accept'], contains('text/html'));
      expect(request.headers['accept'], contains('application/json'));
    });

    test('Should preserve original case in values', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'authorization': 'Bearer Token123ABC'},
      );
      expect(request.headers['authorization'], equals('Bearer Token123ABC'));
    });

    test('Should handle empty header values', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri, headers: {'x-empty': ''});
      expect(request.headers['x-empty'], equals(''));
    });

    test('Should handle headers with special characters', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {
          'x-special': 'value-with-dash',
          'x-number': '12345',
          'x-symbols': 'value@#\$%',
        },
      );
      expect(request.headers['x-special'], equals('value-with-dash'));
      expect(request.headers['x-number'], equals('12345'));
      expect(request.headers['x-symbols'], equals('value@#\$%'));
    });
  });

  group('Headers - Response headers', () {
    test('Should set standard headers', () {
      final response = Response.text(
        'Hello',
        headers: {
          'cache-control': 'no-cache',
          'expires': 'Wed, 21 Oct 2025 07:28:00 GMT',
        },
      );
      expect(response.headers['cache-control'], equals('no-cache'));
      expect(
        response.headers['expires'],
        equals('Wed, 21 Oct 2025 07:28:00 GMT'),
      );
    });

    test('Should set custom headers', () {
      final response = Response.json(
        body: {},
        headers: {'X-Response-Time': '100ms', 'X-Server': 'Aim/1.0'},
      );
      expect(response.headers['X-Response-Time'], equals('100ms'));
      expect(response.headers['X-Server'], equals('Aim/1.0'));
    });

    test('Should allow multiple custom headers', () {
      final response = Response.text(
        'Hello',
        headers: {
          'X-Header-1': 'value1',
          'X-Header-2': 'value2',
          'X-Header-3': 'value3',
        },
      );
      expect(response.headers['X-Header-1'], equals('value1'));
      expect(response.headers['X-Header-2'], equals('value2'));
      expect(response.headers['X-Header-3'], equals('value3'));
    });

    test('Should handle security headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      final response = context.html(
        '<h1>Hello</h1>',
        headers: {
          'X-Frame-Options': 'DENY',
          'X-Content-Type-Options': 'nosniff',
          'X-XSS-Protection': '1; mode=block',
        },
      );
      expect(response.headers['X-Frame-Options'], equals('DENY'));
      expect(response.headers['X-Content-Type-Options'], equals('nosniff'));
      expect(response.headers['X-XSS-Protection'], equals('1; mode=block'));
    });
  });

  group('Headers - Content-Type header', () {
    test('Should set Content-Type for JSON responses', () {
      final response = Response.json(body: {});
      expect(response.headers['content-type'], equals('application/json'));
    });

    test('Should set Content-Type for text responses', () {
      final response = Response.text('Hello');
      expect(
        response.headers['content-type'],
        equals('text/plain; charset=utf-8'),
      );
    });

    test('Should set Content-Type for HTML responses via Context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());
      final response = context.html('<h1>Hello</h1>');
      expect(
        response.headers['content-type'],
        equals('text/html; charset=utf-8'),
      );
    });

    test('Should allow overriding Content-Type', () {
      final response = Response.json(
        body: {},
        headers: {'content-type': 'application/custom+json'},
      );
      expect(
        response.headers['content-type'],
        equals('application/custom+json'),
      );
    });

    test('Should preserve charset parameter', () {
      final response = Response.text(
        'Hello',
        headers: {'content-type': 'text/plain; charset=iso-8859-1'},
      );
      expect(
        response.headers['content-type'],
        equals('text/plain; charset=iso-8859-1'),
      );
    });
  });

  group('Headers - Header validation', () {
    test('Should handle headers with colons in values', () {
      final response = Response.text('Hello', headers: {'x-time': '12:34:56'});
      expect(response.headers['x-time'], equals('12:34:56'));
    });

    test('Should handle empty header values', () {
      final response = Response.text('Hello', headers: {'x-empty': ''});
      expect(response.headers['x-empty'], equals(''));
    });

    test('Should handle very long header values', () {
      final longValue = 'x' * 1000;
      final response = Response.text('Hello', headers: {'x-long': longValue});
      expect(response.headers['x-long'], equals(longValue));
    });

    test('Should handle header values with newlines', () {
      // Note: HTTP headers shouldn't contain newlines, but we test the behavior
      final response = Response.text(
        'Hello',
        headers: {'x-test': 'line1\\nline2'},
      );
      expect(response.headers['x-test'], equals('line1\\nline2'));
    });

    test('Should handle Unicode in header values', () {
      final response = Response.text('Hello', headers: {'x-unicode': 'こんにちは'});
      expect(response.headers['x-unicode'], equals('こんにちは'));
    });
  });

  group('Headers - Middleware header manipulation', () {
    test('Should allow adding headers via Context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('X-Custom-Header', 'value');
      final response = context.json({'message': 'Hello'});

      expect(response.headers['X-Custom-Header'], equals('value'));
    });

    test('Should merge multiple headers added via Context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('X-Header-1', 'value1');
      context.header('X-Header-2', 'value2');
      final response = context.json({});

      expect(response.headers['X-Header-1'], equals('value1'));
      expect(response.headers['X-Header-2'], equals('value2'));
    });

    test('Should preserve both default and custom headers', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('X-Custom', 'custom-value');
      final response = context.json({});

      expect(response.headers['content-type'], equals('application/json'));
      expect(response.headers['X-Custom'], equals('custom-value'));
    });

    test('Should allow overriding headers via Context', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request('GET', uri);
      final context = Context(request, EmptyEnv());

      context.header('content-type', 'application/custom');
      final response = context.json({});

      // Context headers are added after response creation, so they override
      expect(response.headers['content-type'], equals('application/custom'));
    });
  });

  group('Headers - Common HTTP headers', () {
    test('Should handle Cache-Control header', () {
      final response = Response.text(
        'Hello',
        headers: {'cache-control': 'max-age=3600, public'},
      );
      expect(response.headers['cache-control'], equals('max-age=3600, public'));
    });

    test('Should handle Authorization header', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'authorization': 'Bearer token123'},
      );
      expect(request.headers['authorization'], equals('Bearer token123'));
    });

    test('Should handle Accept header', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'accept': 'application/json, text/html;q=0.9'},
      );
      expect(request.headers['accept'], contains('application/json'));
    });

    test('Should handle User-Agent header', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'user-agent': 'Mozilla/5.0 (Custom)'},
      );
      expect(request.headers['user-agent'], equals('Mozilla/5.0 (Custom)'));
    });

    test('Should handle Location header for redirects', () {
      final response = Response.redirect('https://example.com/new-location');
      expect(
        response.headers['location'],
        equals('https://example.com/new-location'),
      );
    });

    test('Should handle ETag header', () {
      final response = Response.text(
        'Hello',
        headers: {'etag': '"33a64df551425fcc55e4d42a148795d9f25f89d4"'},
      );
      expect(
        response.headers['etag'],
        equals('"33a64df551425fcc55e4d42a148795d9f25f89d4"'),
      );
    });

    test('Should handle Last-Modified header', () {
      final response = Response.text(
        'Hello',
        headers: {'last-modified': 'Wed, 21 Oct 2025 07:28:00 GMT'},
      );
      expect(
        response.headers['last-modified'],
        equals('Wed, 21 Oct 2025 07:28:00 GMT'),
      );
    });
  });

  group('Headers - CORS headers', () {
    test('Should handle Access-Control-Allow-Origin', () {
      final response = Response.json(
        body: {},
        headers: {'access-control-allow-origin': '*'},
      );
      expect(response.headers['access-control-allow-origin'], equals('*'));
    });

    test('Should handle Access-Control-Allow-Methods', () {
      final response = Response.json(
        body: {},
        headers: {'access-control-allow-methods': 'GET, POST, PUT, DELETE'},
      );
      expect(
        response.headers['access-control-allow-methods'],
        equals('GET, POST, PUT, DELETE'),
      );
    });

    test('Should handle Access-Control-Allow-Headers', () {
      final response = Response.json(
        body: {},
        headers: {
          'access-control-allow-headers': 'Content-Type, Authorization',
        },
      );
      expect(
        response.headers['access-control-allow-headers'],
        equals('Content-Type, Authorization'),
      );
    });

    test('Should handle Access-Control-Max-Age', () {
      final response = Response.json(
        body: {},
        headers: {'access-control-max-age': '86400'},
      );
      expect(response.headers['access-control-max-age'], equals('86400'));
    });
  });

  group('Headers - Content negotiation', () {
    test('Should handle Accept-Encoding header', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'accept-encoding': 'gzip, deflate, br'},
      );
      expect(request.headers['accept-encoding'], equals('gzip, deflate, br'));
    });

    test('Should handle Accept-Language header', () {
      final uri = Uri.parse('http://example.com/');
      final request = Request(
        'GET',
        uri,
        headers: {'accept-language': 'en-US,en;q=0.9,ja;q=0.8'},
      );
      expect(
        request.headers['accept-language'],
        equals('en-US,en;q=0.9,ja;q=0.8'),
      );
    });

    test('Should handle Content-Encoding header', () {
      final response = Response.text(
        'Compressed',
        headers: {'content-encoding': 'gzip'},
      );
      expect(response.headers['content-encoding'], equals('gzip'));
    });

    test('Should handle Vary header', () {
      final response = Response.json(
        body: {},
        headers: {'vary': 'Accept-Encoding, Accept-Language'},
      );
      expect(
        response.headers['vary'],
        equals('Accept-Encoding, Accept-Language'),
      );
    });
  });

  group('Headers - Header merging', () {
    test('Should merge headers without conflict', () {
      final response = Response.json(
        body: {},
        headers: {'X-Custom-1': 'value1', 'X-Custom-2': 'value2'},
      );
      expect(response.headers['content-type'], equals('application/json'));
      expect(response.headers['X-Custom-1'], equals('value1'));
      expect(response.headers['X-Custom-2'], equals('value2'));
    });

    test('Should allow header override in custom headers', () {
      final response = Response.json(
        body: {},
        headers: {'content-type': 'application/vnd.api+json'},
      );
      expect(
        response.headers['content-type'],
        equals('application/vnd.api+json'),
      );
    });

    test('Should preserve all headers after merge', () {
      final response = Response.text(
        'Hello',
        headers: {'cache-control': 'no-cache', 'X-Custom': 'value'},
      );
      expect(
        response.headers['content-type'],
        equals('text/plain; charset=utf-8'),
      );
      expect(response.headers['cache-control'], equals('no-cache'));
      expect(response.headers['X-Custom'], equals('value'));
    });
  });
}
