import 'package:aim_server_jwt/aim_server_jwt.dart';
import 'package:test/test.dart';

void main() {
  group('SecretKey', () {
    test('Should create successfully with secret key of 32+ characters', () {
      expect(
        () => SecretKey(secret: 'a' * 32),
        returnsNormally,
      );
      expect(
        () => SecretKey(secret: 'a' * 64),
        returnsNormally,
      );
    });

    test('Should throw error with empty secret key', () {
      expect(
        () => SecretKey(secret: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('Should throw error with secret key less than 32 characters', () {
      expect(
        () => SecretKey(secret: 'short'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => SecretKey(secret: 'a' * 31),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('JWT - Sign and Verify', () {
    late JwtOptions options;

    setUp(() {
      options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
      );
    });

    test('Should generate JWT token correctly', () {
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1, 'role': 'admin'});

      expect(token, isNotEmpty);
      expect(token.split('.').length, equals(3));
    });

    test('Should verify generated token correctly', () {
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1, 'role': 'admin'});

      final claims = jwt.verify(token);
      expect(claims['user_id'], equals(1));
      expect(claims['role'], equals('admin'));
    });

    test('Should throw JwtException for invalid signature', () {
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      // Tamper with signature
      final parts = token.split('.');
      final invalidToken = '${parts[0]}.${parts[1]}.invalidsignature';

      expect(
        () => jwt.verify(invalidToken),
        throwsA(isA<JwtException>()),
      );
    });

    test('Should throw JwtException for invalid token format', () {
      final jwt = Jwt(options: options);

      // Only 2 parts
      expect(
        () => jwt.verify('header.payload'),
        throwsA(isA<JwtException>()),
      );

      // 4 parts
      expect(
        () => jwt.verify('header.payload.signature.extra'),
        throwsA(isA<JwtException>()),
      );

      // Empty string
      expect(
        () => jwt.verify(''),
        throwsA(isA<JwtException>()),
      );
    });

    test('Should throw error for tampered payload', () {
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      // Tamper with payload
      final parts = token.split('.');
      final invalidToken = '${parts[0]}.fakePayload.${parts[2]}';

      expect(
        () => jwt.verify(invalidToken),
        throwsA(isA<JwtException>()),
      );
    });
  });

  group('JWT - Standard Claims', () {
    test('Should automatically set iat claim', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      final claims = jwt.verify(token);
      expect(claims['iat'], isNotNull);
      expect(claims['iat'], isA<int>());
    });

    test('Should set issuer claim correctly', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        issuer: 'test-issuer',
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      final claims = jwt.verify(token);
      expect(claims['iss'], equals('test-issuer'));
    });

    test('Should set subject claim correctly', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        subject: 'user:123',
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'data': 'test'});

      final claims = jwt.verify(token);
      expect(claims['sub'], equals('user:123'));
    });

    test('Should set audience claim correctly', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        audience: 'api.example.com',
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      final claims = jwt.verify(token);
      expect(claims['aud'], equals('api.example.com'));
    });

    test('Should set expiration claim correctly', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        expiration: Duration(hours: 1),
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      final claims = jwt.verify(token);
      expect(claims['exp'], isNotNull);
      expect(claims['exp'], isA<int>());

      final exp = DateTime.fromMillisecondsSinceEpoch(
        (claims['exp'] as int) * 1000,
      );
      final now = DateTime.now();
      expect(exp.isAfter(now), isTrue);
      expect(
        exp.difference(now).inMinutes,
        greaterThanOrEqualTo(59),
      ); // Approximately 1 hour later
    });

    test('Should set notBefore claim correctly', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        notBefore: Duration(milliseconds: -100), // Past time (already valid)
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      final claims = jwt.verify(token);
      expect(claims['nbf'], isNotNull);
      expect(claims['nbf'], isA<int>());
    });
  });

  group('JWT - Expiration Validation', () {
    test('Should verify token within expiration period', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        expiration: Duration(hours: 1),
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      expect(() => jwt.verify(token), returnsNormally);
    });

    test('Should throw JwtException for expired token', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        expiration: Duration(milliseconds: 1),
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      // Wait for token to expire
      return Future.delayed(Duration(milliseconds: 10), () {
        expect(
          () => jwt.verify(token),
          throwsA(
            isA<JwtException>().having(
              (e) => e.message,
              'message',
              contains('expired'),
            ),
          ),
        );
      });
    });
  });

  group('JWT - Issuer Validation', () {
    test('Should verify token with matching issuer', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        issuer: 'test-issuer',
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      expect(() => jwt.verify(token), returnsNormally);
    });

    test('Should throw JwtException for mismatched issuer', () {
      // Sign with different issuer
      final signOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        issuer: 'wrong-issuer',
      );
      final signJwt = Jwt(options: signOptions);
      final token = signJwt.sign({'user_id': 1});

      // Verify with correct issuer
      final verifyOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        issuer: 'correct-issuer',
      );
      final verifyJwt = Jwt(options: verifyOptions);

      expect(
        () => verifyJwt.verify(token),
        throwsA(
          isA<JwtException>().having(
            (e) => e.message,
            'message',
            contains('Invalid issuer'),
          ),
        ),
      );
    });
  });

  group('JWT - Audience Validation', () {
    test('Should verify token with matching audience', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        audience: 'api.example.com',
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      expect(() => jwt.verify(token), returnsNormally);
    });

    test('Should throw JwtException for mismatched audience', () {
      // Sign with different audience
      final signOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        audience: 'wrong-audience',
      );
      final signJwt = Jwt(options: signOptions);
      final token = signJwt.sign({'user_id': 1});

      // Verify with correct audience
      final verifyOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        audience: 'correct-audience',
      );
      final verifyJwt = Jwt(options: verifyOptions);

      expect(
        () => verifyJwt.verify(token),
        throwsA(
          isA<JwtException>().having(
            (e) => e.message,
            'message',
            contains('Invalid audience'),
          ),
        ),
      );
    });
  });

  group('JWT - NotBefore Validation', () {
    test('Should verify token after notBefore time', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        notBefore: Duration(milliseconds: 1),
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      // Wait for nbf to pass
      return Future.delayed(Duration(milliseconds: 10), () {
        expect(() => jwt.verify(token), returnsNormally);
      });
    });

    test('Should throw JwtException for token not yet valid', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        notBefore: Duration(hours: 1), // Valid 1 hour from now
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1});

      expect(
        () => jwt.verify(token),
        throwsA(
          isA<JwtException>().having(
            (e) => e.message,
            'message',
            contains('not yet valid'),
          ),
        ),
      );
    });
  });

  group('JWT - createToken Static Method', () {
    test('Should generate token correctly using createToken', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
      );

      final token = Jwt.createToken(
        payload: {'user_id': 1, 'role': 'admin'},
        options: options,
      );

      expect(token, isNotEmpty);
      expect(token.split('.').length, equals(3));

      final jwt = Jwt(options: options);
      final claims = jwt.verify(token);
      expect(claims['user_id'], equals(1));
      expect(claims['role'], equals('admin'));
    });
  });

  group('JWT - Complex Scenarios', () {
    test('Should use all standard claims simultaneously', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        issuer: 'test-issuer',
        subject: 'user:123',
        audience: 'api.example.com',
        expiration: Duration(hours: 1),
        notBefore: Duration(seconds: 1),
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({'user_id': 1, 'role': 'admin'});

      return Future.delayed(Duration(seconds: 2), () {
        final claims = jwt.verify(token);
        expect(claims['iss'], equals('test-issuer'));
        expect(claims['sub'], equals('user:123'));
        expect(claims['aud'], equals('api.example.com'));
        expect(claims['exp'], isNotNull);
        expect(claims['nbf'], isNotNull);
        expect(claims['iat'], isNotNull);
        expect(claims['user_id'], equals(1));
        expect(claims['role'], equals('admin'));
      });
    });

    test('Should coexist custom payload with standard claims', () {
      final options = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
        issuer: 'test-issuer',
      );
      final jwt = Jwt(options: options);
      final token = jwt.sign({
        'user_id': 1,
        'username': 'alice',
        'permissions': ['read', 'write'],
      });

      final claims = jwt.verify(token);
      expect(claims['iss'], equals('test-issuer'));
      expect(claims['user_id'], equals(1));
      expect(claims['username'], equals('alice'));
      expect(claims['permissions'], equals(['read', 'write']));
    });

    test('Should fail verification with different secret key', () {
      final signOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-at-least-32-chars'),
        ),
      );
      final signJwt = Jwt(options: signOptions);
      final token = signJwt.sign({'user_id': 1});

      final verifyOptions = JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'different-secret-key-32-chars!!!'),
        ),
      );
      final verifyJwt = Jwt(options: verifyOptions);

      expect(
        () => verifyJwt.verify(token),
        throwsA(isA<JwtException>()),
      );
    });
  });
}
