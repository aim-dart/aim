import 'package:aim_server_basic_auth/aim_server_basic_auth.dart';
import 'package:test/test.dart';

void main() {
  group('BasicAuthVariables', () {
    test('Should create with options', () {
      final options = BasicAuthOptions(
        realm: 'Test Realm',
        verify: (username, password) async => true,
      );

      final variables = BasicAuthVariables(options: options);

      expect(variables.options, equals(options));
      expect(variables.username, isNull);
    });

    test('Should allow setting username', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
      );

      final variables = BasicAuthVariables(options: options);
      variables.username = 'testuser';

      expect(variables.username, equals('testuser'));
    });

    test('Should allow updating username', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
      );

      final variables = BasicAuthVariables(options: options);
      variables.username = 'user1';
      expect(variables.username, equals('user1'));

      variables.username = 'user2';
      expect(variables.username, equals('user2'));
    });

    test('Should allow clearing username', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
      );

      final variables = BasicAuthVariables(options: options);
      variables.username = 'testuser';
      expect(variables.username, isNotNull);

      variables.username = null;
      expect(variables.username, isNull);
    });

    test('Should store options reference', () {
      final options = BasicAuthOptions(
        realm: 'Custom Realm',
        verify: (username, password) async => true,
        excludedPaths: ['/login', '/public'],
      );

      final variables = BasicAuthVariables(options: options);

      expect(variables.options.realm, equals('Custom Realm'));
      expect(variables.options.excludedPaths, hasLength(2));
    });
  });
}
