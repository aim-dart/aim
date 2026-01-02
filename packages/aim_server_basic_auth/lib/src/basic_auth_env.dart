import 'package:aim_server/aim_server.dart';
import 'package:aim_server_basic_auth/src/basic_auth_options.dart';

/// Environment variables for HTTP Basic Authentication.
///
/// This class extends [Env] to provide type-safe access to Basic Auth
/// configuration and the authenticated username.
///
/// Example:
/// ```dart
/// final app = Aim<BasicAuthEnv>(
///   envFactory: () => BasicAuthEnv(
///     options: BasicAuthOptions(
///       realm: 'Admin Area',
///       verify: (username, password) async {
///         return username == 'admin' && password == 'secret';
///       },
///     ),
///   ),
/// );
///
/// app.use(basicAuth());
///
/// app.get('/profile', (c) async {
///   final username = c.variables.username;
///   return c.json({'username': username});
/// });
/// ```
class BasicAuthEnv extends Env {
  BasicAuthEnv({required this.options});

  /// The Basic Authentication configuration options.
  ///
  /// Contains the realm, verification function, and excluded paths
  /// for the middleware.
  final BasicAuthOptions options;

  /// The authenticated username.
  ///
  /// This is set by the Basic Auth middleware after successful
  /// credential verification. It will be `null` for unauthenticated
  /// requests or on excluded paths.
  ///
  /// Access this in your handlers to get the current user:
  /// ```dart
  /// app.get('/profile', (c) async {
  ///   final username = c.variables.username;
  ///   return c.json({'user': username});
  /// });
  /// ```
  String? username;
}
