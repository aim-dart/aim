import 'dart:convert';
import 'dart:io';

/// Represents parsed multipart form data containing text fields and uploaded files.
///
/// This class provides methods to access both single and multiple values for
/// fields and files submitted in a multipart/form-data request.
class MultipartFormData {
  /// Creates a [MultipartFormData] instance.
  const MultipartFormData({
    required Map<String, List<String>> fields,
    required Map<String, List<UploadedFile>> files,
  })  : _fields = fields,
        _files = files;

  final Map<String, List<String>> _fields;
  final Map<String, List<UploadedFile>> _files;

  /// Gets a single text field value by [name].
  ///
  /// Returns the first value if multiple values exist, or null if the field doesn't exist.
  ///
  /// Example:
  /// ```dart
  /// final title = form.field('title'); // String?
  /// ```
  String? field(String name) {
    final values = _fields[name];
    if (values != null && values.isNotEmpty) {
      return values.first;
    }
    return null;
  }

  /// Gets all text field values with the same [name].
  ///
  /// Returns an empty list if no fields with the given name exist.
  ///
  /// Example:
  /// ```dart
  /// final tags = form.fields('tags'); // List<String>
  /// ```
  List<String> fields(String name) {
    return _fields[name] ?? [];
  }

  /// Gets a single uploaded file by [name].
  ///
  /// Returns the first file if multiple files exist, or null if no file with that name exists.
  ///
  /// Example:
  /// ```dart
  /// final avatar = form.file('avatar'); // UploadedFile?
  /// if (avatar != null) {
  ///   await avatar.saveTo('uploads/${avatar.filename}');
  /// }
  /// ```
  UploadedFile? file(String name) {
    final files = _files[name];
    if (files != null && files.isNotEmpty) {
      return files.first;
    }
    return null;
  }

  /// Gets all uploaded files with the same [name].
  ///
  /// Returns an empty list if no files with the given name exist.
  ///
  /// Example:
  /// ```dart
  /// final images = form.files('images'); // List<UploadedFile>
  /// for (final image in images) {
  ///   await image.saveTo('uploads/${image.filename}');
  /// }
  /// ```
  List<UploadedFile> files(String name) {
    return _files[name] ?? [];
  }

  /// Checks if a field or file with the given [name] exists.
  ///
  /// Returns true if either a text field or file with the name exists.
  ///
  /// Example:
  /// ```dart
  /// if (form.has('avatar')) {
  ///   // Process avatar
  /// }
  /// ```
  bool has(String name) {
    return _fields.containsKey(name) || _files.containsKey(name);
  }
}

/// Represents an uploaded file from a multipart/form-data request.
///
/// Contains the file's contents as bytes along with metadata like filename and MIME type.
/// The [filename] is automatically sanitized for security, while [originalFilename]
/// preserves the original name from the client.
class UploadedFile {
  /// Creates an [UploadedFile] instance.
  const UploadedFile({
    required this.filename,
    required this.originalFilename,
    required this.contentType,
    required this.bytes,
  });

  /// Sanitized filename that is safe to use for storage.
  ///
  /// This filename has been processed to prevent path traversal attacks
  /// and is guaranteed to be unique. Format: `file_<timestamp>_<random>.<ext>`
  ///
  /// Example: `file_1234567890_abc123de.jpg`
  final String filename;

  /// Original filename as sent by the client.
  ///
  /// This may contain unsafe characters or path information and should not
  /// be used directly for file storage. Use [filename] instead.
  final String? originalFilename;

  /// MIME type of the uploaded file (e.g., 'image/png', 'application/pdf').
  ///
  /// Defaults to 'application/octet-stream' if not specified in the request.
  final String contentType;

  /// File contents as a list of bytes.
  ///
  /// Use [asString] to decode as text for text files.
  final List<int> bytes;

  /// File size in bytes.
  ///
  /// Example:
  /// ```dart
  /// print('File size: ${file.size} bytes');
  /// ```
  int get size => bytes.length;

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

  /// Decodes the file contents as a string using the specified [encoding].
  ///
  /// Useful for reading text files like CSV, JSON, or plain text.
  /// Defaults to UTF-8 encoding.
  ///
  /// Example:
  /// ```dart
  /// final csvContent = file.asString();
  /// final rows = csvContent.split('\n');
  /// ```
  ///
  /// Throws [FormatException] if the bytes are not valid for the encoding.
  String asString([Encoding encoding = utf8]) {
    return encoding.decode(bytes);
  }
}
