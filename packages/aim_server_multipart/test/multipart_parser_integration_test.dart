import 'dart:convert';
import 'package:test/test.dart';
import 'package:aim_server_multipart/src/multipart_parser.dart';

void main() {
  group('Integration Tests', () {
    test('parses single file upload', () async {
      final body = _createMultipartRequest(
        boundary: 'WebKitFormBoundary7MA4YWxkTrZu0gW',
        parts: [
          _FilePart(
            name: 'avatar',
            filename: 'profile.jpg',
            contentType: 'image/jpeg',
            content: 'fake jpeg data',
          ),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'WebKitFormBoundary7MA4YWxkTrZu0gW',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      final file = result.file('avatar');
      expect(file, isNotNull);
      expect(file!.contentType, 'image/jpeg');
      expect(file.originalFilename, 'profile.jpg');
      expect(file.filename, matches(RegExp(r'^file_\d+_[a-z0-9]{8}\.jpg$')));
      expect(file.bytes, isNotEmpty);
    });

    test('parses multiple files with same field name', () async {
      final body = _createMultipartRequest(
        boundary: 'boundary123',
        parts: [
          _FilePart(
            name: 'images',
            filename: 'photo1.png',
            contentType: 'image/png',
            content: 'image 1 data',
          ),
          _FilePart(
            name: 'images',
            filename: 'photo2.png',
            contentType: 'image/png',
            content: 'image 2 data',
          ),
          _FilePart(
            name: 'images',
            filename: 'photo3.png',
            contentType: 'image/png',
            content: 'image 3 data',
          ),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary123',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      final images = result.files('images');
      expect(images, hasLength(3));
      expect(images[0].originalFilename, 'photo1.png');
      expect(images[1].originalFilename, 'photo2.png');
      expect(images[2].originalFilename, 'photo3.png');
    });

    test('parses text fields only', () async {
      final body = _createMultipartRequest(
        boundary: 'boundary456',
        parts: [
          _FieldPart(name: 'username', value: 'john_doe'),
          _FieldPart(name: 'email', value: 'john@example.com'),
          _FieldPart(name: 'age', value: '30'),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary456',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      expect(result.field('username'), 'john_doe');
      expect(result.field('email'), 'john@example.com');
      expect(result.field('age'), '30');
    });

    test('parses mixed files and fields', () async {
      final body = _createMultipartRequest(
        boundary: 'boundaryMixed',
        parts: [
          _FieldPart(name: 'title', value: 'My Upload'),
          _FieldPart(name: 'description', value: 'This is a test upload'),
          _FilePart(
            name: 'document',
            filename: 'report.pdf',
            contentType: 'application/pdf',
            content: 'fake pdf content',
          ),
          _FieldPart(name: 'tags', value: 'important'),
          _FieldPart(name: 'tags', value: 'urgent'),
          _FilePart(
            name: 'attachment',
            filename: 'data.csv',
            contentType: 'text/csv',
            content: 'name,value\ntest,123',
          ),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundaryMixed',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      // Check fields
      expect(result.field('title'), 'My Upload');
      expect(result.field('description'), 'This is a test upload');
      expect(result.fields('tags'), ['important', 'urgent']);

      // Check files
      final document = result.file('document');
      expect(document, isNotNull);
      expect(document!.contentType, 'application/pdf');
      expect(document.originalFilename, 'report.pdf');

      final attachment = result.file('attachment');
      expect(attachment, isNotNull);
      expect(attachment!.contentType, 'text/csv');
      expect(attachment.originalFilename, 'data.csv');
    });

    test('handles empty field values', () async {
      final body = _createMultipartRequest(
        boundary: 'boundary789',
        parts: [
          _FieldPart(name: 'empty', value: ''),
          _FieldPart(name: 'nonempty', value: 'value'),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary789',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      expect(result.field('empty'), '');
      expect(result.field('nonempty'), 'value');
    });

    test('handles special characters in field values', () async {
      final body = _createMultipartRequest(
        boundary: 'boundarySpecial',
        parts: [
          _FieldPart(name: 'text', value: 'Hello\nWorld\r\nWith\tTabs'),
          _FieldPart(name: 'unicode', value: '日本語テスト🎉'),
          _FieldPart(name: 'symbols', value: '!@#\$%^&*()'),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundarySpecial',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      expect(result.field('text'), 'Hello\nWorld\r\nWith\tTabs');
      expect(result.field('unicode'), '日本語テスト🎉');
      expect(result.field('symbols'), '!@#\$%^&*()');
    });

    test('handles file with no Content-Type header', () async {
      final body = _createMultipartRequest(
        boundary: 'boundaryNoType',
        parts: [
          _FilePart(
            name: 'file',
            filename: 'unknown.dat',
            contentType: null, // No Content-Type
            content: 'binary data',
          ),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundaryNoType',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      final file = result.file('file');
      expect(file, isNotNull);
      expect(file!.contentType, 'application/octet-stream'); // Default
    });

    test('handles complex real-world scenario', () async {
      final body = _createMultipartRequest(
        boundary: 'WebKitFormBoundaryRealWorld123',
        parts: [
          _FieldPart(name: 'user_id', value: '12345'),
          _FieldPart(name: 'action', value: 'create_post'),
          _FieldPart(name: 'title', value: 'My Blog Post'),
          _FieldPart(name: 'content', value: 'This is a long blog post content...'),
          _FieldPart(name: 'tags', value: 'tech'),
          _FieldPart(name: 'tags', value: 'programming'),
          _FieldPart(name: 'tags', value: 'dart'),
          _FilePart(
            name: 'featured_image',
            filename: 'header.jpg',
            contentType: 'image/jpeg',
            content: 'jpeg header image data',
          ),
          _FilePart(
            name: 'attachments',
            filename: 'code_sample.dart',
            contentType: 'text/plain',
            content: 'void main() { print("Hello"); }',
          ),
          _FilePart(
            name: 'attachments',
            filename: 'diagram.png',
            contentType: 'image/png',
            content: 'png diagram data',
          ),
          _FieldPart(name: 'published', value: 'true'),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'WebKitFormBoundaryRealWorld123',
        maxFileSize: 10000,
        maxTotalSize: 50000,
        allowedMimeTypes: ['image/*', 'text/plain'],
      );

      // Verify fields
      expect(result.field('user_id'), '12345');
      expect(result.field('action'), 'create_post');
      expect(result.field('title'), 'My Blog Post');
      expect(result.fields('tags'), ['tech', 'programming', 'dart']);
      expect(result.field('published'), 'true');

      // Verify files
      final featuredImage = result.file('featured_image');
      expect(featuredImage, isNotNull);
      expect(featuredImage!.contentType, 'image/jpeg');

      final attachments = result.files('attachments');
      expect(attachments, hasLength(2));
      expect(attachments[0].originalFilename, 'code_sample.dart');
      expect(attachments[1].originalFilename, 'diagram.png');
    });

    test('returns null for non-existent field', () async {
      final body = _createMultipartRequest(
        boundary: 'boundary',
        parts: [
          _FieldPart(name: 'existing', value: 'value'),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      expect(result.field('nonexistent'), isNull);
      expect(result.file('nonexistent'), isNull);
    });

    test('returns empty list for non-existent multi-value field', () async {
      final body = _createMultipartRequest(
        boundary: 'boundary',
        parts: [
          _FieldPart(name: 'existing', value: 'value'),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      expect(result.fields('nonexistent'), isEmpty);
      expect(result.files('nonexistent'), isEmpty);
    });

    test('has() returns correct results', () async {
      final body = _createMultipartRequest(
        boundary: 'boundary',
        parts: [
          _FieldPart(name: 'field1', value: 'value'),
          _FilePart(
            name: 'file1',
            filename: 'test.txt',
            contentType: 'text/plain',
            content: 'content',
          ),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      expect(result.has('field1'), isTrue);
      expect(result.has('file1'), isTrue);
      expect(result.has('nonexistent'), isFalse);
    });
  });
}

/// Represents a file part in multipart request
class _FilePart {
  _FilePart({
    required this.name,
    required this.filename,
    required this.contentType,
    required this.content,
  });

  final String name;
  final String filename;
  final String? contentType;
  final String content;
}

/// Represents a field part in multipart request
class _FieldPart {
  _FieldPart({
    required this.name,
    required this.value,
  });

  final String name;
  final String value;
}

/// Creates a multipart request body from parts
Stream<List<int>> _createMultipartRequest({
  required String boundary,
  required List<Object> parts,
}) {
  final buffer = StringBuffer();

  for (final part in parts) {
    buffer.write('--$boundary\r\n');

    if (part is _FilePart) {
      buffer.write('Content-Disposition: form-data; name="${part.name}"; filename="${part.filename}"\r\n');
      if (part.contentType != null) {
        buffer.write('Content-Type: ${part.contentType}\r\n');
      }
      buffer.write('\r\n');
      buffer.write(part.content);
    } else if (part is _FieldPart) {
      buffer.write('Content-Disposition: form-data; name="${part.name}"\r\n');
      buffer.write('\r\n');
      buffer.write(part.value);
    }

    buffer.write('\r\n');
  }

  buffer.write('--$boundary--\r\n');

  return Stream.value(utf8.encode(buffer.toString()));
}