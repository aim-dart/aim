import 'package:aim_core/aim_core.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';

/// Environment variables for JWT authentication.
///
/// This class extends [Variables] to provide type-safe access to JWT-related
/// context variables including configuration options and decoded payload.
///
/// Example:
/// ```dart
/// final app = Aim<JwtVariables>(
///   variablesFactory: () => JwtVariables.create(
///     JwtOptions(
///       algorithm: HS256(
///         secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
///       ),
///     ),
///   ),
/// );
///
/// app.get('/profile', (c) async {
///   final payload = c.variables.jwtPayload;
///   return c.json({'user_id': payload['user_id']});
/// });
/// ```
class JwtVariables extends Variables {
  /// Creates a new JWT environment with the given options.
  ///
  /// The [jwtPayload] is initially empty and will be populated by the
  /// JWT middleware after successful token verification.
  static JwtVariables create(JwtOptions options) =>
      JwtVariables(jwtOptions: options, jwtPayload: {});

  JwtVariables({required this.jwtOptions, required this.jwtPayload});

  /// The decoded JWT payload.
  ///
  /// This is populated by the JWT middleware after successful token
  /// verification. Contains all claims from the JWT token including
  /// custom payload data.
  Map<String, dynamic> jwtPayload;

  /// The JWT configuration options.
  ///
  /// Contains signing algorithm, standard claims configuration,
  /// and excluded paths for the middleware.
  final JwtOptions jwtOptions;
}

/// Former name of [JwtVariables]. Will be removed in a future release.
@Deprecated('Use JwtVariables')
typedef JwtEnv = JwtVariables;
