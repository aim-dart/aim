# aim_server_multipart

Multipart form data parser for the Aim framework. Handles file uploads and form data with security in mind.

## Overview

`aim_server_multipart` provides secure and efficient parsing of `multipart/form-data` requests for the Aim framework. It's designed as a separate package to keep applications that don't need file uploads lightweight.

## Features

- 📤 **File Upload Support** - Handle single and multiple file uploads
- 🔒 **Security First** - Automatic filename sanitization prevents path traversal attacks
- 📏 **Size Limits** - Configure per-file and total upload size limits
- 🎯 **MIME Type Filtering** - Allow only specific file types with wildcard support
- ⚡ **Stream Processing** - Efficient memory usage with streaming
- 🧪 **Well Tested** - Comprehensive test suite with 39 tests
- 📋 **RFC 7578 Compliant** - Follows the multipart/form-data standard

## Installation

Add `aim_server_multipart` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6
  aim_server_multipart: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Basic File Upload

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_multipart/aim_server_multipart.dart';

void main() async {
  final app = Aim();

  app.post('/upload', (c) async {
    final form = await c.req.multipart();

    final avatar = form.file('avatar');
    if (avatar != null) {
      // Save the file
      await avatar.saveTo('uploads/${avatar.filename}');

      return c.json({
        'uploaded': true,
        'filename': avatar.filename,
        'size': avatar.size,
      });
    }

    return c.json({'error': 'No file uploaded'}, 400);
  });

  await app.serve(port: 8080);
}
```

### Multiple Files and Fields

```dart
app.post('/upload', (c) async {
  final form = await c.req.multipart();

  // Get text fields
  final title = form.field('title');           // String?
  final tags = form.fields('tags');            // List<String>

  // Get multiple files
  final images = form.files('images');         // List<UploadedFile>
  for (final image in images) {
    await image.saveTo('uploads/${image.filename}');
  }

  return c.json({
    'title': title,
    'tags': tags,
    'uploaded': images.length,
  });
});
```

### With Validation

```dart
app.post('/upload', (c) async {
  try {
    final form = await c.req.multipart(
      maxFileSize: 10 * 1024 * 1024,      // 10MB per file
      maxTotalSize: 50 * 1024 * 1024,     // 50MB total
      allowedMimeTypes: ['image/*'],       // Only images
    );

    final avatar = form.file('avatar');
    if (avatar != null) {
      await avatar.saveTo('uploads/${avatar.filename}');
      return c.json({'success': true});
    }

    return c.json({'error': 'No file uploaded'}, 400);
  } on Exception catch (e) {
    // File too large, wrong type, etc.
    return c.json({'error': e.toString()}, 400);
  }
});
```

### Text File Processing

```dart
app.post('/upload-csv', (c) async {
  final form = await c.req.multipart(
    allowedMimeTypes: ['text/csv', 'text/plain'],
  );

  final csvFile = form.file('data');
  if (csvFile != null) {
    // Read as string
    final csvContent = csvFile.asString();
    final rows = csvContent.split('\n');

    return c.json({
      'rows': rows.length,
      'preview': rows.take(5).toList(),
    });
  }

  return c.json({'error': 'No file uploaded'}, 400);
});
```

## API Reference

### MultipartFormData

Represents parsed multipart form data.

**Methods:**
- `field(String name)` - Get single text field → `String?`
- `fields(String name)` - Get multiple fields with same name → `List<String>`
- `file(String name)` - Get single file → `UploadedFile?`
- `files(String name)` - Get multiple files with same name → `List<UploadedFile>`
- `has(String name)` - Check if field/file exists → `bool`

### UploadedFile

Represents an uploaded file.

**Properties:**
- `filename` - Sanitized safe filename (`String`)
- `originalFilename` - Original filename from client (`String?`)
- `contentType` - MIME type (`String`)
- `bytes` - File contents (`List<int>`)
- `size` - File size in bytes (`int`)

**Methods:**
- `saveTo(String path)` - Save file to disk
- `asString([Encoding encoding])` - Read file as string

### Request Extension

```dart
extension MultipartRequest on Request {
  Future<MultipartFormData> multipart({
    int? maxFileSize,
    int? maxTotalSize,
    List<String>? allowedMimeTypes,
  });
}
```

**Parameters:**
- `maxFileSize` - Maximum size per file in bytes
- `maxTotalSize` - Maximum total size in bytes
- `allowedMimeTypes` - List of allowed MIME types
  - Exact match: `['image/png', 'application/pdf']`
  - Wildcard: `['image/*', 'video/*']`

## Security

### Filename Sanitization

Uploaded filenames are automatically sanitized to prevent security issues:

- ❌ Path traversal attacks (`../../../etc/passwd` → safe filename)
- ❌ Absolute paths (`/tmp/evil.sh` → safe filename)
- ❌ Dangerous characters removed
- ✅ Random unique filenames generated (collision-free)
- ✅ Original filename preserved in `originalFilename` property

Example generated filename:
```
file_1234567890_abc123de.jpg
```

### Size Limits

```dart
final form = await c.req.multipart(
  maxFileSize: 10 * 1024 * 1024,  // 10MB limit
);
```

Throws `Exception` if limit exceeded.

### MIME Type Filtering

```dart
final form = await c.req.multipart(
  allowedMimeTypes: [
    'image/png',
    'image/jpeg',
    'image/*',  // All image types
  ],
);
```

Throws `Exception` for disallowed types.

## Error Handling

```dart
app.post('/upload', (c) async {
  try {
    final form = await c.req.multipart(
      maxFileSize: 10 * 1024 * 1024,
      allowedMimeTypes: ['image/*'],
    );

    // Process files...

  } on FormatException catch (e) {
    // Invalid Content-Type, missing name parameter, etc.
    return c.json({'error': 'Invalid request: ${e.message}'}, 400);
  } on Exception catch (e) {
    // File too large, wrong MIME type, etc.
    return c.json({'error': e.toString()}, 400);
  }
});
```

## Examples

See the [example](example/) directory for complete working examples.

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.

## References

- [RFC 7578 - multipart/form-data](https://datatracker.ietf.org/doc/html/rfc7578)
- [aim_server - Core Framework](https://github.com/aim-dart/aim/tree/main/packages/aim_server)
