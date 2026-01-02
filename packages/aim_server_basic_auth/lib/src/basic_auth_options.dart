/// Configuration options for HTTP Basic Authentication.
///
/// Defines the authentication behavior including user verification,
/// realm identifier, and path exclusions.
///
/// Example:
/// ```dart
/// final options = BasicAuthOptions(
///   realm: 'Admin Area',
///   verify: (username, password) async {
///     // Verify against database or hash
///     return username == 'admin' &&
///            password == 'secret123';
///   },
///   excludedPaths: ['/login', '/public'],
/// );
/// ```
class BasicAuthOptions {
  const BasicAuthOptions({
    required this.verify,
    this.realm = 'Restricted Area',
    this.excludedPaths = const [],
  });

  /// The realm identifier shown to users during authentication.
  ///
  /// This string is included in the WWW-Authenticate header and
  /// displayed in the browser's authentication dialog.
  ///
  /// As per RFC 7617, the realm identifies the protection space
  /// and helps users understand what they're authenticating to.
  ///
  /// Example: `'Admin Area'`, `'API Access'`, `'Premium Content'`
  final String realm;

  /// Async function to verify username and password credentials.
  ///
  /// This function is called for each authentication attempt.
  /// Return `true` if credentials are valid, `false` otherwise.
  ///
  /// Example:
  /// ```dart
  /// verify: (username, password) async {
  ///   final user = await database.findUser(username);
  ///   if (user == null) return false;
  ///   return await verifyPassword(password, user.passwordHash);
  /// }
  /// ```
  final Future<bool> Function(String username, String password) verify;

  /// List of paths to exclude from authentication.
  ///
  /// Requests to these paths will skip authentication and proceed
  /// directly to the next middleware or handler.
  ///
  /// Useful for public endpoints like login pages, health checks,
  /// or public API documentation.
  ///
  /// Example: `['/login', '/register', '/health', '/docs']`
  final List<String> excludedPaths;
}
