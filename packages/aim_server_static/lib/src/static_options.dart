/// Controls how dotfiles (files starting with `.`) are handled
/// when serving static files.
///
/// Dotfiles often contain sensitive information (e.g., `.env`, `.git/config`)
/// and should typically not be served to clients.
enum DotFiles {
  /// Allow serving dotfiles normally.
  ///
  /// Use this only if you need to serve dotfiles intentionally.
  allow,

  /// Deny access to dotfiles with a 403 Forbidden response.
  ///
  /// This explicitly tells the client that the resource exists
  /// but access is forbidden.
  deny,

  /// Ignore dotfiles and pass the request to the next handler.
  ///
  /// This is the default behavior. Dotfile requests will result in 404
  /// if no other handler matches the request.
  ignore,
}