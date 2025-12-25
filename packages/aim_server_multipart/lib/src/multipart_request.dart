import 'package:aim_server/aim_server.dart';
import 'package:aim_server_multipart/src/multipart_form_data.dart';
import 'package:aim_server_multipart/src/multipart_parser.dart';

/// Extension on [Request] to add multipart/form-data parsing support.
extension MultipartRequest on Request {
  /// Parses a multipart/form-data request body.
  ///
  /// Validates the Content-Type header and extracts the boundary parameter,
  /// then parses the request body into fields and files.
  ///
  /// Parameters:
  /// - [maxFileSize]: Optional maximum size per file in bytes
  /// - [maxTotalSize]: Optional maximum total upload size in bytes
  /// - [allowedMimeTypes]: Optional list of allowed MIME types (supports wildcards like 'image/*')
  ///
  /// Example:
  /// ```dart
  /// app.post('/upload', (c) async {
  ///   final form = await c.req.multipart(
  ///     maxFileSize: 10 * 1024 * 1024,  // 10MB
  ///     allowedMimeTypes: ['image/*'],
  ///   );
  ///
  ///   final avatar = form.file('avatar');
  ///   if (avatar != null) {
  ///     await avatar.saveTo('uploads/${avatar.filename}');
  ///   }
  ///
  ///   return c.json({'uploaded': avatar != null});
  /// });
  /// ```
  ///
  /// Throws:
  /// - [FormatException] if Content-Type is not multipart/form-data or boundary is invalid
  /// - [Exception] if file size limits are exceeded or MIME type is not allowed
  Future<MultipartFormData> multipart({
    int? maxFileSize,
    int? maxTotalSize,
    List<String>? allowedMimeTypes,
  }) async {
    final contentType = headers['content-type'] ?? '';
    final mediaType = contentType.split(';').first.trim().toLowerCase();
    if (mediaType != 'multipart/form-data') {
      throw FormatException(
        'Expected Content-Type: multipart/form-data, got $contentType',
      );
    }

    final boundary = _extractBoundary(contentType);
    return await parseMultipart(
      body: read(),
      boundary: boundary,
      maxFileSize: maxFileSize,
      maxTotalSize: maxTotalSize,
      allowedMimeTypes: allowedMimeTypes,
    );
  }

  /// Extracts the boundary parameter from the Content-Type header.
  ///
  /// Validates the boundary according to RFC 2046:
  /// - Must be present
  /// - Cannot be empty
  /// - Must be 70 characters or less
  /// - Cannot end with a space
  ///
  /// Handles quoted boundaries and unescapes them according to RFC 2822.
  String _extractBoundary(String contentType) {
    final parts = contentType.split(';');

    final boundaryPart = parts
        .firstWhere(
          (part) => part.trim().startsWith('boundary='),
          orElse: () => '',
        )
        .trim();

    if (boundaryPart.isEmpty) {
      throw FormatException(
        'Missing boundary in Content-Type header: $contentType',
      );
    }

    var boundary = boundaryPart.substring('boundary='.length).trim();
    if (boundary.startsWith('"') &&
        boundary.endsWith('"') &&
        boundary.length >= 2) {
      final unquote = boundary.substring(1, boundary.length - 1);
      boundary = _unescapeQuotedString(unquote);
    }

    if (boundary.isEmpty) {
      throw FormatException(
        'Boundary cannot be empty in Content-Type header: $contentType',
      );
    }

    if (boundary.length > 70) {
      throw FormatException('Boundary length exceeds 70 characters: $boundary');
    }

    if (boundary.endsWith(' ')) {
      throw FormatException(
        'Boundary cannot end with a space character: "$boundary"',
      );
    }

    return boundary;
  }

  /// Unescapes a quoted string according to RFC 2822.
  ///
  /// Processes escape sequences in quoted-string format where backslash
  /// escapes the following character.
  ///
  /// Example: `\"` becomes `"`, `\\` becomes `\`
  String _unescapeQuotedString(String quoted) {
    final result = StringBuffer();
    var i = 0;

    while (i < quoted.length) {
      if (quoted[i] == '\\' && i + 1 < quoted.length) {
        // Escape sequence: use the next character as-is
        result.write(quoted[i + 1]);
        i += 2; // Skip both characters
      } else {
        result.write(quoted[i]);
        i++;
      }
    }

    return result.toString();
  }
}
