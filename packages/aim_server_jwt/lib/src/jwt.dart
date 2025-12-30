import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Base class for JWT signing keys.
///
/// This sealed class ensures type safety for different key types
/// used in JWT signing algorithms.
sealed class JwtKey {
  const JwtKey();
}

/// HMAC secret key for symmetric signing algorithms (HS256, HS384, HS512).
///
/// The secret must be at least 32 characters long to comply with RFC 7518
/// security requirements for HS256.
///
/// Example:
/// ```dart
/// final key = SecretKey(secret: 'your-secret-key-at-least-32-chars');
/// ```
///
/// Throws [ArgumentError] if the secret is empty or less than 32 characters.
class SecretKey extends JwtKey {
  /// Creates a secret key with validation.
  ///
  /// The [secret] must be at least 32 characters long for HS256 security.
  SecretKey({required this.secret}) {
    if (secret.isEmpty) {
      throw ArgumentError('Secret key cannot be empty');
    }

    if (secret.length < 32) {
      throw ArgumentError(
        'Secret key should be at least 32 characters long for security reasons',
      );
    }
  }

  /// The secret key string.
  final String secret;
}

/// Base class for JWT signing algorithms.
///
/// Implementations provide specific signing algorithms like HS256, RS256, etc.
sealed class JwtAlgorithm {
  const JwtAlgorithm({required this.type});

  /// The algorithm type identifier (e.g., "HS256", "RS256").
  final String type;

  /// Signs the JWT header and claims to produce a signature.
  ///
  /// Both [headerBase64] and [claimsBase64] should be Base64URL-encoded.
  String sign({required String headerBase64, required String claimsBase64});
}

/// Base class for HMAC-based signing algorithms.
///
/// HMAC algorithms use symmetric keys for both signing and verification.
sealed class HMAC extends JwtAlgorithm {
  const HMAC({required this.secretKey, required super.type});

  /// The secret key used for HMAC signing.
  final SecretKey secretKey;
}

/// HMAC-SHA256 (HS256) signing algorithm.
///
/// This is a symmetric key algorithm that uses the same secret for both
/// signing and verification. It requires a secret key of at least 32 characters.
///
/// Example:
/// ```dart
/// final algorithm = HS256(
///   secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
/// );
/// ```
class HS256 extends HMAC {
  const HS256({required super.secretKey}) : super(type: 'HS256');

  @override
  String sign({required String headerBase64, required String claimsBase64}) {
    final unsignedToken = '$headerBase64.$claimsBase64';
    final key = utf8.encode(secretKey.secret);
    final bytes = utf8.encode(unsignedToken);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    final signatureBase64 = base64Url.encode(digest.bytes).replaceAll('=', '');
    return signatureBase64;
  }
}

/// Configuration options for JWT operations.
///
/// Defines signing algorithm, standard JWT claims, and middleware behavior.
///
/// Example:
/// ```dart
/// final options = JwtOptions(
///   algorithm: HS256(
///     secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
///   ),
///   issuer: 'my-app',
///   audience: 'api.example.com',
///   expiration: Duration(hours: 24),
///   excludedPaths: ['/login', '/public'],
/// );
/// ```
class JwtOptions {
  const JwtOptions({
    required this.algorithm,
    this.issuer,
    this.subject,
    this.audience,
    this.expiration,
    this.notBefore,
    this.excludedPaths = const [],
  });

  /// The signing algorithm to use (e.g., HS256).
  final JwtAlgorithm algorithm;

  /// Token issuer (iss claim).
  ///
  /// Validated during token verification if set.
  final String? issuer;

  /// Token subject (sub claim).
  final String? subject;

  /// Intended audience (aud claim).
  ///
  /// Validated during token verification if set.
  final String? audience;

  /// Token expiration duration (exp claim).
  ///
  /// Automatically validated during verification.
  final Duration? expiration;

  /// Token not valid before duration (nbf claim).
  ///
  /// Automatically validated during verification.
  final Duration? notBefore;

  /// Paths to exclude from JWT authentication in middleware.
  ///
  /// Useful for public endpoints like /login, /register, /health.
  final List<String> excludedPaths;
}

/// JWT token creation and verification.
///
/// Provides methods to sign and verify JSON Web Tokens with support
/// for standard JWT claims and custom payloads.
///
/// Example:
/// ```dart
/// final jwt = Jwt(options: options);
///
/// // Sign a token
/// final token = jwt.sign({'user_id': 123, 'role': 'admin'});
///
/// // Verify a token
/// try {
///   final claims = jwt.verify(token);
///   print('User ID: ${claims['user_id']}');
/// } on JwtException catch (e) {
///   print('Invalid token: ${e.message}');
/// }
/// ```
class Jwt {
  const Jwt({required this.options});

  /// The JWT configuration options.
  final JwtOptions options;

  /// Creates a JWT token using static method.
  ///
  /// This is a convenience method equivalent to creating a [Jwt] instance
  /// and calling [sign].
  ///
  /// Example:
  /// ```dart
  /// final token = Jwt.createToken(
  ///   payload: {'user_id': 123, 'role': 'admin'},
  ///   options: options,
  /// );
  /// ```
  static String createToken({
    required Map<String, dynamic> payload,
    required JwtOptions options,
  }) {
    final jwt = Jwt(options: options);
    return jwt.sign(payload);
  }

  /// Signs a JWT token with the given payload.
  ///
  /// The [payload] will be merged with standard JWT claims based on
  /// the configured [options]. Standard claims (iss, sub, aud, exp, nbf, iat)
  /// are automatically added when configured.
  ///
  /// Returns a signed JWT token string in the format:
  /// `<header>.<payload>.<signature>`
  ///
  /// Example:
  /// ```dart
  /// final token = jwt.sign({
  ///   'user_id': 123,
  ///   'username': 'alice',
  ///   'role': 'admin',
  /// });
  /// ```
  String sign(Map<String, dynamic> payload) {
    final header = {'alg': options.algorithm.type, 'typ': 'JWT'};

    final claims = Map<String, dynamic>.from(payload);
    if (options.issuer != null) {
      claims['iss'] = options.issuer;
    }
    if (options.subject != null) {
      claims['sub'] = options.subject;
    }
    if (options.audience != null) {
      claims['aud'] = options.audience;
    }
    if (options.expiration != null) {
      final exp = DateTime.now().add(options.expiration!);
      claims['exp'] = exp.millisecondsSinceEpoch ~/ 1000;
    }
    if (options.notBefore != null) {
      final nbf = DateTime.now().add(options.notBefore!);
      claims['nbf'] = nbf.millisecondsSinceEpoch ~/ 1000;
    }

    final now = DateTime.now();
    claims['iat'] = now.millisecondsSinceEpoch ~/ 1000;

    final headerBase64 = base64Url
        .encode(utf8.encode(jsonEncode(header)))
        .replaceAll('=', '');
    final claimsBase64 = base64Url
        .encode(utf8.encode(jsonEncode(claims)))
        .replaceAll('=', '');

    final signatureBase64 = options.algorithm.sign(
      headerBase64: headerBase64,
      claimsBase64: claimsBase64,
    );

    return '$headerBase64.$claimsBase64.$signatureBase64';
  }

  /// Verifies a JWT token and returns its claims.
  ///
  /// Validates:
  /// - Token format (must have 3 parts separated by dots)
  /// - Signature validity
  /// - Expiration (exp claim)
  /// - Not before time (nbf claim)
  /// - Issuer match (iss claim)
  /// - Audience match (aud claim)
  ///
  /// Returns the decoded claims as a Map.
  ///
  /// Throws [JwtException] if validation fails.
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final claims = jwt.verify(token);
  ///   print('Token valid for user: ${claims['user_id']}');
  /// } on JwtException catch (e) {
  ///   print('Verification failed: ${e.message}');
  /// }
  /// ```
  Map<String, dynamic> verify(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw JwtException('Invalid JWT token format');
    }

    final headerBase64 = parts[0];
    final claimsBase64 = parts[1];
    final signatureBase64 = parts[2];

    final expectedSignature = options.algorithm.sign(
      headerBase64: headerBase64,
      claimsBase64: claimsBase64,
    );

    if (signatureBase64 != expectedSignature) {
      throw JwtException('Invalid JWT signature');
    }

    final claims =
        jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(claimsBase64))),
            )
            as Map<String, dynamic>;

    if (claims.containsKey('exp')) {
      final exp = DateTime.fromMillisecondsSinceEpoch(
        (claims['exp'] as int) * 1000,
      );
      if (DateTime.now().isAfter(exp)) {
        throw JwtException('JWT token has expired');
      }
    }

    if (options.issuer != null && claims['iss'] != options.issuer) {
      throw JwtException('Invalid issuer');
    }
    if (options.audience != null && claims['aud'] != options.audience) {
      throw JwtException('Invalid audience');
    }

    if (claims.containsKey('nbf')) {
      final nbf = DateTime.fromMillisecondsSinceEpoch(
        (claims['nbf'] as int) * 1000,
      );
      if (DateTime.now().isBefore(nbf)) {
        throw JwtException('Token not yet valid');
      }
    }

    return claims;
  }
}

/// Exception thrown when JWT operations fail.
///
/// This exception is thrown during token verification when:
/// - Token format is invalid
/// - Signature verification fails
/// - Token has expired
/// - Token is not yet valid (nbf claim)
/// - Issuer or audience doesn't match
///
/// Example:
/// ```dart
/// try {
///   jwt.verify(token);
/// } on JwtException catch (e) {
///   print('JWT error: ${e.message}');
/// }
/// ```
class JwtException implements Exception {
  const JwtException(this.message);

  /// The error message describing what went wrong.
  final String message;

  @override
  String toString() => 'JwtException: $message';
}
