import 'package:aim_server_basic_auth/aim_server_basic_auth.dart';
import 'package:test/test.dart';

void main() {
  group('BasicAuthOptions', () {
    test('Should create with required verify function', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
      );

      expect(options.verify, isNotNull);
      expect(options.realm, equals('Restricted Area')); // Default
      expect(options.excludedPaths, isEmpty); // Default
    });

    test('Should use custom realm', () {
      final options = BasicAuthOptions(
        realm: 'Admin Area',
        verify: (username, password) async => true,
      );

      expect(options.realm, equals('Admin Area'));
    });

    test('Should use custom excludedPaths', () {
      final options = BasicAuthOptions(
        verify: (username, password) async => true,
        excludedPaths: ['/login', '/public', '/health'],
      );

      expect(options.excludedPaths, hasLength(3));
      expect(options.excludedPaths, contains('/login'));
      expect(options.excludedPaths, contains('/public'));
      expect(options.excludedPaths, contains('/health'));
    });

    test('Should call verify function with correct parameters', () async {
      String? capturedUsername;
      String? capturedPassword;

      final options = BasicAuthOptions(
        verify: (username, password) async {
          capturedUsername = username;
          capturedPassword = password;
          return true;
        },
      );

      await options.verify('testuser', 'testpass');

      expect(capturedUsername, equals('testuser'));
      expect(capturedPassword, equals('testpass'));
    });

    test('Should return true when credentials are valid', () async {
      final options = BasicAuthOptions(
        verify: (username, password) async {
          return username == 'admin' && password == 'secret';
        },
      );

      final result = await options.verify('admin', 'secret');
      expect(result, isTrue);
    });

    test('Should return false when credentials are invalid', () async {
      final options = BasicAuthOptions(
        verify: (username, password) async {
          return username == 'admin' && password == 'secret';
        },
      );

      final result = await options.verify('admin', 'wrong');
      expect(result, isFalse);
    });

    test('Should support async verification', () async {
      final options = BasicAuthOptions(
        verify: (username, password) async {
          // Simulate database lookup
          await Future.delayed(Duration(milliseconds: 10));
          return username == 'admin' && password == 'secret';
        },
      );

      final result = await options.verify('admin', 'secret');
      expect(result, isTrue);
    });

    test('Should be const constructible', () {
      const options = BasicAuthOptions(
        realm: 'Test Realm',
        verify: _staticVerify,
        excludedPaths: ['/login'],
      );

      expect(options.realm, equals('Test Realm'));
    });
  });
}

// Static function for const constructor test
Future<bool> _staticVerify(String username, String password) async {
  return username == 'admin' && password == 'secret';
}
