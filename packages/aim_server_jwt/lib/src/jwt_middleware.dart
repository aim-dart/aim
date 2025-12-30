import 'package:aim_server/aim_server.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';

/// Creates JWT authentication middleware.
///
/// This middleware validates Bearer tokens from the Authorization header
/// and makes the decoded payload available via `c.variables.jwtPayload`.
///
/// The middleware will:
/// - Return 401 if Authorization header is missing or invalid
/// - Skip authentication for paths in `excludedPaths`
/// - Verify token signature and standard claims (exp, nbf, iss, aud)
/// - Store decoded payload in context variables
///
/// Example:
/// ```dart
/// final app = Aim<JwtEnv>(
///   envFactory: () => JwtEnv.create(
///     JwtOptions(
///       algorithm: HS256(
///         secretKey: SecretKey(secret: 'your-secret-key-at-least-32-chars'),
///       ),
///       excludedPaths: ['/login', '/public'],
///     ),
///   ),
/// );
///
/// app.use(jwt());
///
/// app.get('/protected', (c) async {
///   final payload = c.variables.jwtPayload;
///   return c.json({'user_id': payload['user_id']});
/// });
/// ```
Middleware<E> jwt<E extends JwtEnv>() {
  return (c, next) async {
    if (c.variables.jwtOptions.excludedPaths.contains(c.req.path)) {
      return next();
    }
    final authHeader = c.req.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      c.json({'error': 'Unauthorized'}, statusCode: 401);
      return;
    }

    final token = authHeader.substring('Bearer '.length);

    try {
      final jwt = Jwt(options: c.variables.jwtOptions);
      final payload = jwt.verify(token);
      c.variables.jwtPayload = payload;
      return next();
    } catch (e) {
      c.json({'error': 'Invalid token'}, statusCode: 401);
      return;
    }
  };
}
