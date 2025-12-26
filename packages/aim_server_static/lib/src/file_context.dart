import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' hide Context;

/// Extension on [Context] to provide single file serving functionality.
extension FileContext on Context {
  /// Serves a single file from the filesystem.
  ///
  /// This method serves a file from the specified [path] relative to the
  /// current working directory. It includes built-in security features to
  /// prevent path traversal attacks.
  ///
  /// **Parameters:**
  ///
  /// - [path] - Relative path to the file from the current directory.
  ///   Must be a relative path; absolute paths are rejected.
  ///
  ///   Example: `'docs/manual.pdf'`, `'images/logo.png'`
  ///
  /// - [download] - If `true`, the file will be downloaded instead of
  ///   displayed in the browser. Defaults to `false`.
  ///
  ///   When `true`, sets `Content-Disposition: attachment` header.
  ///
  /// - [filename] - Custom filename for downloads. Only used when
  ///   [download] is `true`. If not specified, uses the original filename.
  ///
  /// **Returns:** A [Response] that streams the file content.
  ///
  /// **Throws:**
  ///
  /// - [ArgumentError] if [path] is an absolute path
  /// - [ArgumentError] if path traversal is detected (e.g., `../`)
  /// - [ArgumentError] if [path] points to a directory instead of a file
  ///
  /// **Security:**
  ///
  /// - Rejects absolute paths to prevent arbitrary file access
  /// - Validates that the resolved path is within the current directory
  /// - Returns 404 if the file doesn't exist
  ///
  /// **Example:**
  ///
  /// Display a PDF in the browser:
  /// ```dart
  /// app.get('/view/manual', (c) {
  ///   return c.file('docs/manual.pdf');
  /// });
  /// ```
  ///
  /// Force download with custom filename:
  /// ```dart
  /// app.get('/download/report', (c) {
  ///   return c.file('reports/2024.pdf',
  ///     download: true,
  ///     filename: 'Annual-Report-2024.pdf',
  ///   );
  /// });
  /// ```
  ///
  /// Serve user-specific files:
  /// ```dart
  /// app.get('/users/:id/avatar', (c) {
  ///   final id = c.param('id');
  ///   return c.file('avatars/$id.png');
  /// });
  /// ```
  Future<Response> file(String path, {bool download = false, String? filename}) async {
    if (isAbsolute(path)) {
      throw ArgumentError('Absolute paths are not allowed: $path');
    }

    final currentDir = Directory.current.path;
    final normalizedPath = normalize(join(currentDir, path));

    if (!isWithin(currentDir, normalizedPath)) {
      throw ArgumentError('Path traversal detected: $path');
    }

    final file = File(normalizedPath);

    if (!await file.exists()) {
      return notFound('File not found: $path');
    }

    final stat = await file.stat();
    if (stat.type == FileSystemEntityType.directory) {
      throw ArgumentError('Path is a directory, not a file: $path');
    }

    final headers = <String, String>{};

    // MIME type
    final mimeType = lookupMimeType(path) ?? 'application/octet-stream';
    headers['Content-Type'] = mimeType;
    headers['Content-Length'] = stat.size.toString();

    // Download header
    if (download) {
      final downloadName = filename ?? basename(path);
      headers['Content-Disposition'] = 'attachment; filename="$downloadName"';
    }

    return stream(file.openRead(), headers: headers);
  }
}