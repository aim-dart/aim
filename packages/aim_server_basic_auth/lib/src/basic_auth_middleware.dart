import 'dart:convert';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_basic_auth/src/basic_auth_env.dart';

/// Creates HTTP Basic Authentication middleware.
///
/// This middleware implements RFC 7617 compliant HTTP Basic Authentication.
/// It validates credentials from the Authorization header and makes the
/// authenticated username available via `c.variables.username`.
///
/// The middleware will:
/// - Return 401 with WWW-Authenticate header if credentials are missing or invalid
/// - Skip authentication for paths in `excludedPaths`
/// - Verify credentials using the provided `verify` function
/// - Store the authenticated username in context variables
///
/// Authentication Flow:
/// 1. Client sends: `Authorization: Basic base64(username:password)`
/// 2. Server decodes and verifies credentials
/// 3. On success: sets `c.variables.username` and continues
/// 4. On failure: returns 401 with WWW-Authenticate header
///
/// Example:
/// ```dart
/// final app = Aim<BasicAuthEnv>(
///   envFactory: () => BasicAuthEnv(
///     options: BasicAuthOptions(
///       realm: 'Admin Area',
///       verify: (username, password) async {
///         // Hash verification example
///         final user = await db.findUser(username);
///         if (user == null) return false;
///         return await verifyPassword(password, user.passwordHash);
///       },
///       excludedPaths: ['/login', '/public'],
///     ),
///   ),
/// );
///
/// app.use(basicAuth());
///
/// app.get('/admin', (c) async {
///   final username = c.variables.username;
///   return c.json({'message': 'Welcome, $username!'});
/// });
/// ```
///
/// Security Notes:
/// - Always use HTTPS in production (credentials are Base64 encoded, not encrypted)
/// - Use password hashing (bcrypt, argon2) in the verify function
/// - Consider rate limiting to prevent brute force attacks
/// - Never log or store plaintext passwords
Middleware<E> basicAuth<E extends BasicAuthEnv>() {
  return (c, next) async {
    if (c.variables.options.excludedPaths.contains(c.req.path)) {
      return next();
    }

    final authHeader = c.req.headers['authorization'];
    if (authHeader == null || !authHeader.startsWith('Basic ')) {
      c.header('WWW-Authenticate', 'Basic realm="${c.variables.options.realm}"');
      c.json({'error': 'Unauthorized'}, statusCode: 401);
      return;
    }

    try {
      final encodedCredentials = authHeader.substring('Basic '.length);
      final decodedBytes = base64Decode(encodedCredentials);
      final decodedCredentials = utf8.decode(decodedBytes);

      final colonIndex = decodedCredentials.indexOf(':');
      if (colonIndex == -1) {
        c.header('WWW-Authenticate', 'Basic realm="${c.variables.options.realm}"');
        c.json({'error': 'Unauthorized'}, statusCode: 401);
        return;
      }

      final username = decodedCredentials.substring(0, colonIndex);
      final password = decodedCredentials.substring(colonIndex + 1);

      final isValid = await c.variables.options.verify(username, password);
      if (!isValid) {
        c.header('WWW-Authenticate', 'Basic realm="${c.variables.options.realm}"');
        c.json({'error': 'Unauthorized'}, statusCode: 401);
        return;
      }

      c.variables.username = username;
      return next();
    } on FormatException {
      c.header('WWW-Authenticate', 'Basic realm="${c.variables.options.realm}"');
      c.json({'error': 'Unauthorized'}, statusCode: 401);
      return;
    }
  };
}
