import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:aim_server_multipart/src/multipart_form_data.dart';
import 'package:mime/mime.dart';

/// Parses a multipart/form-data request body.
///
/// Validates the request against optional size and MIME type constraints,
/// and returns a [MultipartFormData] object containing parsed fields and files.
///
/// Parameters:
/// - [body]: The request body stream containing multipart data
/// - [boundary]: The boundary string from Content-Type header
/// - [maxFileSize]: Optional maximum size per file in bytes
/// - [maxTotalSize]: Optional maximum total size in bytes
/// - [allowedMimeTypes]: Optional list of allowed MIME types (supports wildcards like 'image/*')
///
/// Throws:
/// - [FormatException] if Content-Disposition is missing the required 'name' parameter
/// - [Exception] if file size exceeds limits or MIME type is not allowed
Future<MultipartFormData> parseMultipart({
  required Stream<List<int>> body,
  required String boundary,
  required int? maxFileSize,
  required int? maxTotalSize,
  required List<String>? allowedMimeTypes,
}) async {
  final transformer = MimeMultipartTransformer(boundary);

  final parts = await transformer.bind(body).toList();
  final files = <String, List<UploadedFile>>{};
  final fields = <String, List<String>>{};
  var totalSize = 0;
  for (final part in parts) {
    final contentDisposition = part.headers['content-disposition'] ?? '';
    final hasFilename = RegExp(
      r'filename="?[^";\r\n]+"?',
    ).hasMatch(contentDisposition);
    final fieldName = RegExp(
      r'\bname="?([^";\r\n]+)"?',
    ).firstMatch(contentDisposition)?.group(1);

    if (fieldName == null || fieldName.isEmpty) {
      throw FormatException(
        'Missing required "name" parameter in Content-Disposition',
      );
    }

    if (hasFilename) {
      final (file: uploadedFile, :size) = await _parseUploadedFile(
        part: part,
        totalSize: totalSize,
        maxFileSize: maxFileSize,
        maxTotalSize: maxTotalSize,
        allowedMimeTypes: allowedMimeTypes,
      );
      files.putIfAbsent(fieldName, () => []).add(uploadedFile);
      totalSize += size;
    } else {
      final (:field, :size) = await _parseField(
        part: part,
        totalSize: totalSize,
        maxFileSize: maxFileSize,
        maxTotalSize: maxTotalSize,
      );
      fields.putIfAbsent(fieldName, () => []).add(field);
      totalSize += size;
    }
  }

  return MultipartFormData(fields: fields, files: files);
}

/// Parses an uploaded file from a multipart part.
///
/// Returns a record containing the [UploadedFile] and its size.
/// Validates file size and MIME type if constraints are provided.
Future<({UploadedFile file, int size})> _parseUploadedFile({
  required MimeMultipart part,
  required int totalSize,
  required int? maxFileSize,
  required int? maxTotalSize,
  required List<String>? allowedMimeTypes,
}) async {
  final contentDisposition = part.headers['content-disposition'] ?? '';
  final filenameMatch = RegExp(
    r'filename="?([^";\r\n]+)"?',
  ).firstMatch(contentDisposition);
  final rawFilename = filenameMatch?.group(1);
  final filename = rawFilename != null
      ? _sanitizeFilename(rawFilename)
      : 'unnamed_${DateTime.now().millisecondsSinceEpoch}';

  final contentType =
      part.headers['content-type'] ?? 'application/octet-stream';

  // Validate MIME type
  if (allowedMimeTypes != null && allowedMimeTypes.isNotEmpty) {
    final isAllowed = allowedMimeTypes.any((allowedType) {
      if (allowedType.endsWith('/*')) {
        final prefix = allowedType.substring(0, allowedType.length - 2);
        return contentType.startsWith(prefix);
      } else {
        return contentType == allowedType;
      }
    });
    if (!isAllowed) {
      throw Exception(
        'MIME type "$contentType" is not allowed for uploaded files',
      );
    }
  }

  // Read file data with size validation
  final bytesBuilder = await part.fold(BytesBuilder(), (builder, element) {
    builder.add(element);

    if (maxFileSize != null && builder.length > maxFileSize) {
      throw Exception(
        'Uploaded file size exceeds the maximum allowed size of $maxFileSize bytes',
      );
    }

    final size = builder.length + totalSize;
    if (maxTotalSize != null && size > maxTotalSize) {
      throw Exception(
        'Total upload size exceeds the maximum allowed size of $maxTotalSize bytes',
      );
    }

    return builder;
  });
  final bytes = bytesBuilder.takeBytes();

  return (
    file: UploadedFile(
      filename: filename,
      originalFilename: rawFilename,
      contentType: contentType,
      bytes: bytes,
    ),
    size: bytes.length,
  );
}

/// Sanitizes a filename to prevent security issues.
///
/// Generates a safe, random filename while preserving the file extension.
/// Prevents path traversal attacks and ensures unique filenames.
String _sanitizeFilename(String filename) {
  // Extract extension from original filename
  final ext = _extractExtension(filename);

  // Generate random safe filename
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  final random = _generateRandomString(8); // 8-character random string

  return 'file_${timestamp}_$random$ext';
}

/// Extracts the file extension from a filename.
///
/// Returns an empty string if:
/// - The filename contains path separators (security)
/// - The filename starts with a dot (hidden file)
/// - No extension is present
/// - The extension is too long (>10 characters)
String _extractExtension(String filename) {
  // Don't extract extension if path separators are present (security)
  if (filename.contains('/') || filename.contains('\\')) {
    return '';
  }

  final lastDot = filename.lastIndexOf('.');

  // Return empty if starts with dot (hidden file) or no extension
  if (lastDot <= 0 || lastDot >= filename.length - 1) {
    return '';
  }

  var ext = filename.substring(lastDot);
  // Keep only safe characters in extension
  ext = ext.replaceAll(RegExp(r'[^\w.]'), '');
  if (ext.length <= 10) {
    // Extension must be 10 characters or less
    return ext;
  }

  return '';
}

/// Generates a cryptographically secure random string.
///
/// Uses [Random.secure] to generate a random string of the specified length
/// containing only lowercase letters and digits.
String _generateRandomString(int length) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final random = Random.secure();
  return List.generate(
    length,
    (_) => chars[random.nextInt(chars.length)],
  ).join();
}

/// Parses a text field from a multipart part.
///
/// Returns a record containing the field value and its size.
/// Validates field size if constraints are provided.
Future<({String field, int size})> _parseField({
  required MimeMultipart part,
  required int totalSize,
  required int? maxFileSize,
  required int? maxTotalSize,
}) async {
  final bytesBuilder = await part.fold(BytesBuilder(), (builder, element) {
    builder.add(element);

    if (maxFileSize != null && builder.length > maxFileSize) {
      throw Exception(
        'Uploaded file size exceeds the maximum allowed size of $maxFileSize bytes',
      );
    }

    final size = builder.length + totalSize;
    if (maxTotalSize != null && size > maxTotalSize) {
      throw Exception(
        'Total upload size exceeds the maximum allowed size of $maxTotalSize bytes',
      );
    }

    return builder;
  });
  final bytes = bytesBuilder.takeBytes();

  try {
    return (field: utf8.decode(bytes), size: bytes.length);
  } on FormatException catch (e) {
    throw FormatException('Invalid UTF-8 encoding in field: $e');
  }
}
