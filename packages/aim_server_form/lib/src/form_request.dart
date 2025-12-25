import 'package:aim_server/aim_server.dart';
import 'package:aim_server_form/src/form_data.dart';

/// Extension on [Request] to parse form data.
///
/// Provides the [formData] method to parse request body as
/// `application/x-www-form-urlencoded` format.
extension FormRequest on Request {
  /// Parses the request body as `application/x-www-form-urlencoded`.
  ///
  /// Throws [FormatException] if the Content-Type header is not
  /// `application/x-www-form-urlencoded`.
  ///
  /// Returns an empty [FormData] if the request body is empty.
  ///
  /// Example:
  /// ```dart
  /// app.post('/login', (c) async {
  ///   final form = await c.req.formData();
  ///   final username = form['username'];
  ///   final password = form['password'];
  ///   return c.json({'user': username});
  /// });
  /// ```
  Future<FormData> formData() async {
    // Check Content-Type header
    final contentType = headers['content-type'] ?? '';

    // Validate that Content-Type is application/x-www-form-urlencoded
    // Also accepts with charset parameter (e.g., "application/x-www-form-urlencoded; charset=utf-8")
    if (!contentType.contains('application/x-www-form-urlencoded')) {
      throw FormatException(
        'Expected Content-Type: application/x-www-form-urlencoded, '
        'but got: ${contentType.isEmpty ? '(empty)' : contentType}',
      );
    }

    // Read the request body as text
    final body = await text();

    // Return empty FormData if body is empty
    if (body.isEmpty) {
      return FormData({});
    }

    // Parse the URL-encoded body using Uri.splitQueryString
    // This automatically handles URL decoding
    final params = Uri.splitQueryString(body);

    return FormData(params);
  }
}
