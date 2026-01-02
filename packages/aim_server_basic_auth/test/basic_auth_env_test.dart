import 'package:aim_server_basic_auth/aim_server_basic_auth.dart';
import 'package:test/test.dart';

void main() {
  group('BasicAuthEnv', () {
    test('Should create with options', () {
      final options = BasicAuthOptions(
        realm: 'Test Realm',
        verify: (username, password) async => true,
      );

      final env = BasicAuthEnv(options: options);

      expect(env.options, equals(options));
      expect(env.username, isNull);
    });

    test('Should allow setting username', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
      );

      final env = BasicAuthEnv(options: options);
      env.username = 'testuser';

      expect(env.username, equals('testuser'));
    });

    test('Should allow updating username', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
      );

      final env = BasicAuthEnv(options: options);
      env.username = 'user1';
      expect(env.username, equals('user1'));

      env.username = 'user2';
      expect(env.username, equals('user2'));
    });

    test('Should allow clearing username', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
      );

      final env = BasicAuthEnv(options: options);
      env.username = 'testuser';
      expect(env.username, isNotNull);

      env.username = null;
      expect(env.username, isNull);
    });

    test('Should store options reference', () {
      final options = BasicAuthOptions(
        realm: 'Custom Realm',
        verify: (username, password) async => true,
        excludedPaths: ['/login', '/public'],
      );

      final env = BasicAuthEnv(options: options);

      expect(env.options.realm, equals('Custom Realm'));
      expect(env.options.excludedPaths, hasLength(2));
    });
  });
}
