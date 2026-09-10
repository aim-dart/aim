/// Cookie support for Aim framework with secure options.
///
/// Provides the `setCookie` extension method for `Context` to set cookies
/// with options like HttpOnly, Secure, SameSite, and expiration.
///
/// Example:
/// ```dart
/// import 'package:aim_server/aim_server.dart';
/// import 'package:aim_server_cookie/aim_server_cookie.dart';
///
/// void main() {
///   final app = Aim();
///
///   app.get('/login', (c) {
///     c.setCookie('session_id', 'abc123', options: CookieOptions(
///       httpOnly: true,
///       secure: true,
///       maxAge: Duration(hours: 24),
///       sameSite: SameSite.strict,
///     ));
///     return c.json({'status': 'logged in'});
///   });
///
///   app.listen(port: 3000);
/// }
/// ```
library;

export 'src/aim_server_cookie.dart';
export 'src/cookie_options.dart';
