enum SameSite { strict, lax, none }

class CookieOptions {
  const CookieOptions({
    this.maxAge,
    this.expires,
    this.domain,
    this.path,
    this.secure,
    this.httpOnly,
    this.sameSite,
  });
  final Duration? maxAge;
  final DateTime? expires;
  final String? domain;
  final String? path;
  final bool? secure;
  final bool? httpOnly;
  final SameSite? sameSite;
}
