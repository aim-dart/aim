import 'package:aim_server/aim_server.dart';
import 'package:aim_server_form/aim_server_form.dart';
import 'package:test/test.dart';

void main() {
  group('FormRequest - Successful parsing', () {
    test('Should parse simple form data', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'username=alice',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['username'], equals('alice'));
    });

    test('Should parse multiple fields', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'username=alice&email=alice@example.com&age=30',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['username'], equals('alice'));
      expect(form['email'], equals('alice@example.com'));
      expect(form['age'], equals('30'));
    });

    test('Should decode URL-encoded values', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'message=Hello%20World%21&email=test%40example.com',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['message'], equals('Hello World!'));
      expect(form['email'], equals('test@example.com'));
    });

    test('Should handle empty body as empty FormData', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: '',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form.keys, isEmpty);
    });

    test('Should parse with charset parameter in Content-Type', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'username=alice',
        headers: {
          'content-type': 'application/x-www-form-urlencoded; charset=utf-8',
        },
      );

      final form = await request.formData();

      expect(form['username'], equals('alice'));
    });

    test('Should handle special characters', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'user-name=alice&user_email=test%40example.com',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['user-name'], equals('alice'));
      expect(form['user_email'], equals('test@example.com'));
    });

    test('Should handle Unicode characters', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent:
            'name=%E5%A4%AA%E9%83%8E&message=%E3%81%93%E3%82%93%E3%81%AB%E3%81%A1%E3%81%AF',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['name'], equals('太郎'));
      expect(form['message'], equals('こんにちは'));
    });

    test('Should handle empty values', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'username=&email=alice@example.com',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['username'], equals(''));
      expect(form['email'], equals('alice@example.com'));
    });

    test('Should handle value-less keys', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'remember&username=alice',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['remember'], equals(''));
      expect(form['username'], equals('alice'));
    });
  });

  group('FormRequest - Content-Type validation', () {
    test('Should throw FormatException for missing Content-Type', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'username=alice',
      );

      expect(
        () => request.formData(),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains(
              'Expected Content-Type: application/x-www-form-urlencoded',
            ),
          ),
        ),
      );
    });

    test(
      'Should throw FormatException for wrong Content-Type (application/json)',
      () async {
        final request = Request(
          'POST',
          Uri.parse('/test'),
          bodyContent: '{"username":"alice"}',
          headers: {'content-type': 'application/json'},
        );

        expect(
          () => request.formData(),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('application/json'),
            ),
          ),
        );
      },
    );

    test('Should throw FormatException for multipart/form-data', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'username=alice',
        headers: {'content-type': 'multipart/form-data'},
      );

      expect(() => request.formData(), throwsA(isA<FormatException>()));
    });

    test('Should accept application/x-www-form-urlencoded', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'username=alice',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['username'], equals('alice'));
    });
  });

  group('FormRequest - Real-world scenarios', () {
    test('Should parse login form', () async {
      final request = Request(
        'POST',
        Uri.parse('/login'),
        bodyContent: 'username=alice&password=secret123&remember=on',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['username'], equals('alice'));
      expect(form['password'], equals('secret123'));
      expect(form['remember'], equals('on'));
    });

    test('Should parse search query', () async {
      final request = Request(
        'POST',
        Uri.parse('/search'),
        bodyContent: 'q=dart+programming&filter=recent&sort=relevance',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['q'], equals('dart programming'));
      expect(form['filter'], equals('recent'));
      expect(form['sort'], equals('relevance'));
    });

    test('Should handle form with optional fields', () async {
      final request = Request(
        'POST',
        Uri.parse('/register'),
        bodyContent: 'username=alice&email=alice@example.com',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      expect(form['username'], equals('alice'));
      expect(form['email'], equals('alice@example.com'));
      expect(form['phone'], isNull);
      expect(form.get('phone', ''), equals(''));
    });

    test('Should handle form with repeated keys (last value wins)', () async {
      final request = Request(
        'POST',
        Uri.parse('/test'),
        bodyContent: 'tag=foo&tag=bar&tag=baz',
        headers: {'content-type': 'application/x-www-form-urlencoded'},
      );

      final form = await request.formData();

      // Uri.splitQueryString keeps the last value for duplicate keys
      expect(form['tag'], equals('baz'));
    });
  });
}
