import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

void main() {
  group('Status codes - Valid status codes', () {
    test('Should accept status codes in 100-599 range', () {
      expect(() => Response.text('Continue', statusCode: 100), returnsNormally);
      expect(() => Response.text('OK', statusCode: 200), returnsNormally);
      expect(() => Response.text('Found', statusCode: 302), returnsNormally);
      expect(
        () => Response.text('Not Found', statusCode: 404),
        returnsNormally,
      );
      expect(() => Response.text('Error', statusCode: 500), returnsNormally);
      expect(() => Response.text('Last', statusCode: 599), returnsNormally);
    });

    test('Should reject codes below 100', () {
      expect(() => Response.text('Bad', statusCode: 99), throwsArgumentError);
      expect(() => Response.text('Bad', statusCode: 50), throwsArgumentError);
      expect(() => Response.text('Bad', statusCode: 0), throwsArgumentError);
      expect(() => Response.text('Bad', statusCode: -1), throwsArgumentError);
    });

    test('Should handle all standard HTTP status codes', () {
      final standardCodes = [
        100, 101, 102, 103, // Informational
        200, 201, 202, 203, 204, 205, 206, // Success
        300, 301, 302, 303, 304, 307, 308, // Redirection
        400, 401, 403, 404, 405, 406, 408, 409, 410, 429, // Client errors
        500, 501, 502, 503, 504, 505, // Server errors
      ];

      for (final code in standardCodes) {
        expect(
          () => Response.text('Test', statusCode: code),
          returnsNormally,
          reason: 'Status code $code should be accepted',
        );
      }
    });
  });

  group('Status codes - Status code semantics', () {
    test('Should use 200 for successful GET', () {
      final response = Response.json(body: {'message': 'Success'});
      expect(response.statusCode, equals(200));
    });

    test('Should use 201 for successful POST creating resource', () {
      final response = Response.json(
        body: {'id': 123, 'created': true},
        statusCode: 201,
      );
      expect(response.statusCode, equals(201));
    });

    test('Should use 204 for successful DELETE with no content', () {
      final response = Response.text('', statusCode: 204);
      expect(response.statusCode, equals(204));
    });

    test('Should use 301 for permanent redirect', () {
      final response = Response.redirect('/new-location', 301);
      expect(response.statusCode, equals(301));
    });

    test('Should use 302 for temporary redirect', () {
      final response = Response.redirect('/temporary-location');
      expect(response.statusCode, equals(302));
    });

    test('Should use 304 for not modified', () {
      final response = Response.text('', statusCode: 304);
      expect(response.statusCode, equals(304));
    });

    test('Should use 400 for bad requests', () {
      final response = Response.text('Bad Request', statusCode: 400);
      expect(response.statusCode, equals(400));
    });

    test('Should use 401 for unauthorized', () {
      final response = Response.json(
        body: {'error': 'Unauthorized'},
        statusCode: 401,
      );
      expect(response.statusCode, equals(401));
    });

    test('Should use 403 for forbidden', () {
      final response = Response.json(
        body: {'error': 'Forbidden'},
        statusCode: 403,
      );
      expect(response.statusCode, equals(403));
    });

    test('Should use 404 for not found', () {
      final response = Response.notFound();
      expect(response.statusCode, equals(404));
    });

    test('Should use 405 for method not allowed', () {
      final response = Response.text('Method Not Allowed', statusCode: 405);
      expect(response.statusCode, equals(405));
    });

    test('Should use 500 for internal errors', () {
      final response = Response.internalServerError();
      expect(response.statusCode, equals(500));
    });

    test('Should use 502 for bad gateway', () {
      final response = Response.text('Bad Gateway', statusCode: 502);
      expect(response.statusCode, equals(502));
    });

    test('Should use 503 for service unavailable', () {
      final response = Response.text('Service Unavailable', statusCode: 503);
      expect(response.statusCode, equals(503));
    });

    test('Should use 504 for gateway timeout', () {
      final response = Response.text('Gateway Timeout', statusCode: 504);
      expect(response.statusCode, equals(504));
    });
  });

  group('Status codes - Default status codes', () {
    test('Should default to 200 for json()', () {
      final response = Response.json(body: {});
      expect(response.statusCode, equals(200));
    });

    test('Should default to 200 for text()', () {
      final response = Response.text('Hello');
      expect(response.statusCode, equals(200));
    });

    test('Should default to 404 for notFound()', () {
      final response = Response.notFound();
      expect(response.statusCode, equals(404));
    });

    test('Should default to 500 for internalServerError()', () {
      final response = Response.internalServerError();
      expect(response.statusCode, equals(500));
    });

    test('Should default to 302 for redirect()', () {
      final response = Response.redirect('/location');
      expect(response.statusCode, equals(302));
    });

    test('Should default to 200 for stream()', () {
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final response = Response.stream(stream);
      expect(response.statusCode, equals(200));
    });
  });

  group('Status codes - Custom status codes', () {
    test('Should allow custom status code for json()', () {
      final response = Response.json(body: {}, statusCode: 201);
      expect(response.statusCode, equals(201));
    });

    test('Should allow custom status code for text()', () {
      final response = Response.text('Error', statusCode: 400);
      expect(response.statusCode, equals(400));
    });

    test('Should allow custom status code for stream()', () {
      final stream = Stream<List<int>>.value([1, 2, 3]);
      final response = Response.stream(stream, statusCode: 206);
      expect(response.statusCode, equals(206));
    });

    test('Should allow custom 3xx redirect codes', () {
      expect(Response.redirect('/loc', 301).statusCode, equals(301));
      expect(Response.redirect('/loc', 302).statusCode, equals(302));
      expect(Response.redirect('/loc', 303).statusCode, equals(303));
      expect(Response.redirect('/loc', 307).statusCode, equals(307));
      expect(Response.redirect('/loc', 308).statusCode, equals(308));
    });
  });

  group('Status codes - Informational (1xx)', () {
    test('Should support 100 Continue', () {
      final response = Response.text('', statusCode: 100);
      expect(response.statusCode, equals(100));
    });

    test('Should support 101 Switching Protocols', () {
      final response = Response.text('', statusCode: 101);
      expect(response.statusCode, equals(101));
    });

    test('Should support 102 Processing', () {
      final response = Response.text('', statusCode: 102);
      expect(response.statusCode, equals(102));
    });

    test('Should support 103 Early Hints', () {
      final response = Response.text('', statusCode: 103);
      expect(response.statusCode, equals(103));
    });
  });

  group('Status codes - Success (2xx)', () {
    test('Should support 200 OK', () {
      final response = Response.text('OK', statusCode: 200);
      expect(response.statusCode, equals(200));
    });

    test('Should support 201 Created', () {
      final response = Response.json(body: {}, statusCode: 201);
      expect(response.statusCode, equals(201));
    });

    test('Should support 202 Accepted', () {
      final response = Response.text('Accepted', statusCode: 202);
      expect(response.statusCode, equals(202));
    });

    test('Should support 204 No Content', () {
      final response = Response.text('', statusCode: 204);
      expect(response.statusCode, equals(204));
    });

    test('Should support 206 Partial Content', () {
      final response = Response.text('Partial', statusCode: 206);
      expect(response.statusCode, equals(206));
    });
  });

  group('Status codes - Redirection (3xx)', () {
    test('Should support 300 Multiple Choices', () {
      final response = Response.text('', statusCode: 300);
      expect(response.statusCode, equals(300));
    });

    test('Should support 301 Moved Permanently', () {
      final response = Response.redirect('/new', 301);
      expect(response.statusCode, equals(301));
    });

    test('Should support 302 Found', () {
      final response = Response.redirect('/found', 302);
      expect(response.statusCode, equals(302));
    });

    test('Should support 303 See Other', () {
      final response = Response.redirect('/other', 303);
      expect(response.statusCode, equals(303));
    });

    test('Should support 304 Not Modified', () {
      final response = Response.text('', statusCode: 304);
      expect(response.statusCode, equals(304));
    });

    test('Should support 307 Temporary Redirect', () {
      final response = Response.redirect('/temp', 307);
      expect(response.statusCode, equals(307));
    });

    test('Should support 308 Permanent Redirect', () {
      final response = Response.redirect('/perm', 308);
      expect(response.statusCode, equals(308));
    });

    test('Should reject non-3xx codes for redirect', () {
      expect(() => Response.redirect('/loc', 200), throwsArgumentError);
      expect(() => Response.redirect('/loc', 299), throwsArgumentError);
      expect(() => Response.redirect('/loc', 400), throwsArgumentError);
      expect(() => Response.redirect('/loc', 500), throwsArgumentError);
    });
  });

  group('Status codes - Client errors (4xx)', () {
    test('Should support 400 Bad Request', () {
      final response = Response.text('Bad Request', statusCode: 400);
      expect(response.statusCode, equals(400));
    });

    test('Should support 401 Unauthorized', () {
      final response = Response.text('Unauthorized', statusCode: 401);
      expect(response.statusCode, equals(401));
    });

    test('Should support 403 Forbidden', () {
      final response = Response.text('Forbidden', statusCode: 403);
      expect(response.statusCode, equals(403));
    });

    test('Should support 404 Not Found', () {
      final response = Response.notFound();
      expect(response.statusCode, equals(404));
    });

    test('Should support 405 Method Not Allowed', () {
      final response = Response.text('Method Not Allowed', statusCode: 405);
      expect(response.statusCode, equals(405));
    });

    test('Should support 408 Request Timeout', () {
      final response = Response.text('Timeout', statusCode: 408);
      expect(response.statusCode, equals(408));
    });

    test('Should support 409 Conflict', () {
      final response = Response.text('Conflict', statusCode: 409);
      expect(response.statusCode, equals(409));
    });

    test('Should support 410 Gone', () {
      final response = Response.text('Gone', statusCode: 410);
      expect(response.statusCode, equals(410));
    });

    test('Should support 429 Too Many Requests', () {
      final response = Response.text('Too Many Requests', statusCode: 429);
      expect(response.statusCode, equals(429));
    });
  });

  group('Status codes - Server errors (5xx)', () {
    test('Should support 500 Internal Server Error', () {
      final response = Response.internalServerError();
      expect(response.statusCode, equals(500));
    });

    test('Should support 501 Not Implemented', () {
      final response = Response.text('Not Implemented', statusCode: 501);
      expect(response.statusCode, equals(501));
    });

    test('Should support 502 Bad Gateway', () {
      final response = Response.text('Bad Gateway', statusCode: 502);
      expect(response.statusCode, equals(502));
    });

    test('Should support 503 Service Unavailable', () {
      final response = Response.text('Service Unavailable', statusCode: 503);
      expect(response.statusCode, equals(503));
    });

    test('Should support 504 Gateway Timeout', () {
      final response = Response.text('Gateway Timeout', statusCode: 504);
      expect(response.statusCode, equals(504));
    });

    test('Should support 505 HTTP Version Not Supported', () {
      final response = Response.text('Version Not Supported', statusCode: 505);
      expect(response.statusCode, equals(505));
    });
  });

  group('Status codes - Edge cases', () {
    test('Should accept uncommon but valid status codes', () {
      expect(
        () => Response.text('', statusCode: 418),
        returnsNormally,
      ); // I'm a teapot
      expect(
        () => Response.text('', statusCode: 451),
        returnsNormally,
      ); // Unavailable For Legal Reasons
      expect(
        () => Response.text('', statusCode: 511),
        returnsNormally,
      ); // Network Authentication Required
    });

    test('Should accept custom status codes in valid ranges', () {
      expect(() => Response.text('', statusCode: 199), returnsNormally);
      expect(() => Response.text('', statusCode: 299), returnsNormally);
      expect(() => Response.text('', statusCode: 499), returnsNormally);
      expect(() => Response.text('', statusCode: 599), returnsNormally);
    });

    test('Should validate status code on construction', () {
      expect(
        () => Response.text('Bad', statusCode: 99),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Should provide meaningful error message for invalid code', () {
      try {
        Response.text('Bad', statusCode: 50);
        fail('Should have thrown ArgumentError');
      } catch (e) {
        expect(e, isA<ArgumentError>());
        expect(e.toString(), contains('Invalid status code'));
      }
    });
  });
}
