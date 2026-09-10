/// `dart:io` helpers for `aim_server_multipart`.
///
/// Import this in addition to `aim_server_multipart.dart` when running on the
/// Dart VM. It is not available when compiling to WebAssembly.
library;

import 'dart:io';

import 'package:aim_server_multipart/src/multipart_form_data.dart';

/// File-system operations for [UploadedFile].
extension UploadedFileIO on UploadedFile {
  /// Saves the uploaded file to the specified [path].
  ///
  /// Creates or overwrites the file at the given path with the uploaded content.
  ///
  /// Example:
  /// ```dart
  /// await file.saveTo('uploads/${file.filename}');
  /// ```
  ///
  /// Throws [FileSystemException] if the file cannot be written.
  Future<void> saveTo(String path) async {
    await File(path).writeAsBytes(bytes);
  }
}
