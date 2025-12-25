import 'package:aim_form/aim_form.dart';
import 'package:test/test.dart';

void main() {
  group('FormData - Construction', () {
    test('Should create FormData from Map', () {
      final data = {'username': 'alice', 'age': '30'};
      final form = FormData(data);

      expect(form['username'], equals('alice'));
      expect(form['age'], equals('30'));
    });

    test('Should create immutable data', () {
      final data = {'username': 'alice'};
      final form = FormData(data);

      // Original map can be modified
      data['username'] = 'bob';

      // But FormData should remain unchanged
      expect(form['username'], equals('alice'));
    });

    test('Should handle empty Map', () {
      final form = FormData({});

      expect(form.keys, isEmpty);
      expect(form.values, isEmpty);
    });
  });

  group('FormData - Data access', () {
    late FormData form;

    setUp(() {
      form = FormData({
        'username': 'alice',
        'email': 'alice@example.com',
        'age': '30',
      });
    });

    test('Should get value by key using []', () {
      expect(form['username'], equals('alice'));
      expect(form['email'], equals('alice@example.com'));
      expect(form['age'], equals('30'));
    });

    test('Should return null for non-existent key', () {
      expect(form['nonexistent'], isNull);
      expect(form['password'], isNull);
    });

    test('Should get value with default', () {
      expect(form.get('username', 'default'), equals('alice'));
      expect(form.get('nonexistent', 'default'), equals('default'));
      expect(form.get('password', 'secret'), equals('secret'));
    });

    test('Should get value without default', () {
      expect(form.get('username'), equals('alice'));
      expect(form.get('nonexistent'), isNull);
    });

    test('Should check key existence with has()', () {
      expect(form.has('username'), isTrue);
      expect(form.has('email'), isTrue);
      expect(form.has('nonexistent'), isFalse);
    });

    test('Should return all keys', () {
      final keys = form.keys.toList();
      expect(keys, containsAll(['username', 'email', 'age']));
      expect(keys.length, equals(3));
    });

    test('Should return all values', () {
      final values = form.values.toList();
      expect(values, containsAll(['alice', 'alice@example.com', '30']));
      expect(values.length, equals(3));
    });

    test('Should return all entries', () {
      final entries = form.entries.toList();
      expect(entries.length, equals(3));
      expect(
        entries.any((e) => e.key == 'username' && e.value == 'alice'),
        isTrue,
      );
    });
  });

  group('FormData - Conversion', () {
    test('Should convert to unmodifiable Map', () {
      final form = FormData({'username': 'alice'});
      final map = form.toMap();

      expect(map['username'], equals('alice'));

      // Map should be unmodifiable
      expect(() => map['username'] = 'bob', throwsUnsupportedError);
    });

    test('Should preserve data when converting to Map', () {
      final data = {
        'username': 'alice',
        'email': 'alice@example.com',
        'age': '30',
      };
      final form = FormData(data);
      final map = form.toMap();

      expect(map, equals(data));
    });
  });

  group('FormData - Equality', () {
    test('Should be equal for same data', () {
      final form1 = FormData({'username': 'alice', 'age': '30'});
      final form2 = FormData({'username': 'alice', 'age': '30'});

      expect(form1, equals(form2));
    });

    test('Should not be equal for different data', () {
      final form1 = FormData({'username': 'alice'});
      final form2 = FormData({'username': 'bob'});
      final form3 = FormData({'username': 'alice', 'age': '30'});

      expect(form1, isNot(equals(form2)));
      expect(form1, isNot(equals(form3)));
    });

    test('Should be equal to itself', () {
      final form = FormData({'username': 'alice'});

      expect(form, equals(form));
    });
  });

  group('FormData - Edge cases', () {
    test('Should handle keys with special characters', () {
      final form = FormData({
        'user-name': 'alice',
        'user_email': 'alice@example.com',
        'user.age': '30',
      });

      expect(form['user-name'], equals('alice'));
      expect(form['user_email'], equals('alice@example.com'));
      expect(form['user.age'], equals('30'));
    });

    test('Should handle empty string values', () {
      final form = FormData({
        'username': '',
        'email': 'alice@example.com',
      });

      expect(form['username'], equals(''));
      expect(form.has('username'), isTrue);
    });

    test('Should handle Unicode values', () {
      final form = FormData({
        'name': '太郎',
        'message': 'こんにちは',
        'emoji': '👋',
      });

      expect(form['name'], equals('太郎'));
      expect(form['message'], equals('こんにちは'));
      expect(form['emoji'], equals('👋'));
    });

    test('Should have proper toString representation', () {
      final form = FormData({'username': 'alice'});
      final str = form.toString();

      expect(str, contains('FormData'));
      expect(str, contains('username'));
      expect(str, contains('alice'));
    });
  });
}
