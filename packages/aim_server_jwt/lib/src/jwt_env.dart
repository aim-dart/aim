import 'package:aim_server/aim_server.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';

/// Environment variables for JWT authentication.
///
/// This class extends [Env] to provide type-safe access to JWT-related
/// context variables including configuration options and decoded payload.
///
/// Example:
/// ```dart
/// final app = Aim<JwtEnv>(
///   envFactory: () => JwtEnv.create(
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
class JwtEnv extends Env {
  /// Creates a new JWT environment with the given options.
  ///
  /// The [jwtPayload] is initially empty and will be populated by the
  /// JWT middleware after successful token verification.
  static JwtEnv create(JwtOptions options) =>
      JwtEnv(jwtOptions: options, jwtPayload: {});

  JwtEnv({required this.jwtOptions, required this.jwtPayload});

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
