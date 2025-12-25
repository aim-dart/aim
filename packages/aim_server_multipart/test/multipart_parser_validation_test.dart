import 'dart:convert';
import 'package:test/test.dart';
import 'package:aim_server_multipart/src/multipart_parser.dart';

void main() {
  group('maxFileSize Validation', () {
    test('accepts file within size limit', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: 'test.txt',
        content: 'Small file content',
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: 1000,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      final file = result.file('file');
      expect(file, isNotNull);
      expect(file!.bytes.length, lessThan(1000));
    });

    test('rejects file exceeding size limit', () async {
      final largeContent = 'x' * 2000;
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: 'large.txt',
        content: largeContent,
      );

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: 1000,
          maxTotalSize: null,
          allowedMimeTypes: null,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('exceeds the maximum allowed size'),
          ),
        ),
      );
    });

    test('accepts field within size limit', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        fieldName: 'description',
        content: 'Short description',
        isFile: false,
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: 1000,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      final field = result.field('description');
      expect(field, isNotNull);
      expect(field!.length, lessThan(1000));
    });

    test('rejects field exceeding size limit', () async {
      final largeContent = 'x' * 2000;
      final body = _createMultipartBody(
        boundary: 'boundary',
        fieldName: 'description',
        content: largeContent,
        isFile: false,
      );

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: 1000,
          maxTotalSize: null,
          allowedMimeTypes: null,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('maxTotalSize Validation', () {
    test('accepts multiple files within total size limit', () async {
      final body = _createMultipartBodyWithMultipleFiles(
        boundary: 'boundary',
        files: [
          ('file1', 'test1.txt', 'Content 1'),
          ('file2', 'test2.txt', 'Content 2'),
        ],
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: 1000,
        allowedMimeTypes: null,
      );

      expect(result.files('file1'), hasLength(1));
      expect(result.files('file2'), hasLength(1));
    });

    test('rejects when total size exceeds limit', () async {
      final body = _createMultipartBodyWithMultipleFiles(
        boundary: 'boundary',
        files: [
          ('file1', 'test1.txt', 'x' * 600),
          ('file2', 'test2.txt', 'x' * 600),
        ],
      );

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: null,
          maxTotalSize: 1000,
          allowedMimeTypes: null,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Total upload size exceeds'),
          ),
        ),
      );
    });

    test('counts both files and fields in total size', () async {
      final body = _createMultipartBodyMixed(
        boundary: 'boundary',
        items: [
          (name: 'file', filename: 'test.txt', content: 'x' * 400, isFile: true),
          (name: 'description', filename: null, content: 'x' * 400, isFile: false),
          (name: 'file2', filename: 'test2.txt', content: 'x' * 300, isFile: true),
        ],
      );

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: null,
          maxTotalSize: 1000,
          allowedMimeTypes: null,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Total upload size exceeds'),
          ),
        ),
      );
    });
  });

  group('allowedMimeTypes Validation', () {
    test('accepts file with allowed MIME type', () async {
      final body = _createMultipartBodyWithContentType(
        boundary: 'boundary',
        filename: 'image.png',
        content: 'fake image data',
        contentType: 'image/png',
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: ['image/png', 'image/jpeg'],
      );

      final file = result.file('file');
      expect(file, isNotNull);
      expect(file!.contentType, 'image/png');
    });

    test('rejects file with disallowed MIME type', () async {
      final body = _createMultipartBodyWithContentType(
        boundary: 'boundary',
        filename: 'script.sh',
        content: 'malicious script',
        contentType: 'application/x-sh',
      );

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: null,
          maxTotalSize: null,
          allowedMimeTypes: ['image/png', 'image/jpeg'],
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('is not allowed'),
          ),
        ),
      );
    });

    test('supports wildcard MIME types (image/*)', () async {
      final body = _createMultipartBodyWithContentType(
        boundary: 'boundary',
        filename: 'photo.webp',
        content: 'webp image data',
        contentType: 'image/webp',
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: ['image/*'],
      );

      final file = result.file('file');
      expect(file, isNotNull);
      expect(file!.contentType, 'image/webp');
    });

    test('wildcard does not match different type', () async {
      final body = _createMultipartBodyWithContentType(
        boundary: 'boundary',
        filename: 'video.mp4',
        content: 'video data',
        contentType: 'video/mp4',
      );

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: null,
          maxTotalSize: null,
          allowedMimeTypes: ['image/*'],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('allows file when allowedMimeTypes is null', () async {
      final body = _createMultipartBodyWithContentType(
        boundary: 'boundary',
        filename: 'any.file',
        content: 'any content',
        contentType: 'application/octet-stream',
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      final file = result.file('file');
      expect(file, isNotNull);
    });

    test('allows file when allowedMimeTypes is empty list', () async {
      final body = _createMultipartBodyWithContentType(
        boundary: 'boundary',
        filename: 'any.file',
        content: 'any content',
        contentType: 'application/octet-stream',
      );

      final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: [],
      );

      final file = result.file('file');
      expect(file, isNotNull);
    });
  });

  group('Error Handling', () {
    test('throws FormatException for missing name parameter', () async {
      // Create multipart body without name parameter (only filename)
      final buffer = StringBuffer();
      buffer.write('--boundary\r\n');
      buffer.write('Content-Disposition: form-data; filename="test.txt"\r\n');
      buffer.write('\r\n');
      buffer.write('content\r\n');
      buffer.write('--boundary--\r\n');

      final body = Stream.value(utf8.encode(buffer.toString()));

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: null,
          maxTotalSize: null,
          allowedMimeTypes: null,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('Missing required "name" parameter'),
          ),
        ),
      );
    });

    test('throws FormatException for invalid UTF-8 in field', () async {
      final invalidUtf8 = [0xFF, 0xFE, 0xFD]; // Invalid UTF-8 bytes
      final bodyParts = [
        utf8.encode('--boundary\r\n'),
        utf8.encode('Content-Disposition: form-data; name="field"\r\n'),
        utf8.encode('\r\n'),
        invalidUtf8,
        utf8.encode('\r\n--boundary--\r\n'),
      ];

      final body = Stream.value(
        bodyParts.expand((x) => x).toList(),
      );

      expect(
        () => parseMultipart(
          body: body,
          boundary: 'boundary',
          maxFileSize: null,
          maxTotalSize: null,
          allowedMimeTypes: null,
        ),
        throwsA(
          isA<FormatException>().having(
            (e) => e.toString(),
            'message',
            contains('Invalid UTF-8'),
          ),
        ),
      );
    });
  });
}

/// テスト用のmultipartリクエストボディを生成
Stream<List<int>> _createMultipartBody({
  required String boundary,
  String fieldName = 'file',
  String? filename,
  required String content,
  bool isFile = true,
}) {
  final disposition = isFile
      ? 'Content-Disposition: form-data; name="$fieldName"; filename="$filename"'
      : 'Content-Disposition: form-data; name="$fieldName"';

  final contentTypeHeader = isFile
      ? 'Content-Type: application/octet-stream\r\n'
      : '';

  final body = '''
--$boundary\r
$disposition\r
$contentTypeHeader\r
$content\r
--$boundary--\r
''';

  return Stream.value(utf8.encode(body));
}

/// 複数ファイルのmultipartリクエストボディを生成
Stream<List<int>> _createMultipartBodyWithMultipleFiles({
  required String boundary,
  required List<(String name, String filename, String content)> files,
}) {
  final buffer = StringBuffer();

  for (final (name, filename, content) in files) {
    buffer.write('--$boundary\r\n');
    buffer.write('Content-Disposition: form-data; name="$name"; filename="$filename"\r\n');
    buffer.write('Content-Type: application/octet-stream\r\n');
    buffer.write('\r\n');
    buffer.write(content);
    buffer.write('\r\n');
  }

  buffer.write('--$boundary--\r\n');

  return Stream.value(utf8.encode(buffer.toString()));
}

/// ファイルとフィールドが混在したmultipartリクエストボディを生成
Stream<List<int>> _createMultipartBodyMixed({
  required String boundary,
  required List<({String name, String? filename, String content, bool isFile})> items,
}) {
  final buffer = StringBuffer();

  for (final item in items) {
    buffer.write('--$boundary\r\n');

    if (item.isFile && item.filename != null) {
      buffer.write('Content-Disposition: form-data; name="${item.name}"; filename="${item.filename}"\r\n');
      buffer.write('Content-Type: application/octet-stream\r\n');
    } else {
      buffer.write('Content-Disposition: form-data; name="${item.name}"\r\n');
    }

    buffer.write('\r\n');
    buffer.write(item.content);
    buffer.write('\r\n');
  }

  buffer.write('--$boundary--\r\n');

  return Stream.value(utf8.encode(buffer.toString()));
}

/// Content-Typeを指定したmultipartリクエストボディを生成
Stream<List<int>> _createMultipartBodyWithContentType({
  required String boundary,
  required String filename,
  required String content,
  required String contentType,
  String fieldName = 'file',
}) {
  final body = '''
--$boundary\r
Content-Disposition: form-data; name="$fieldName"; filename="$filename"\r
Content-Type: $contentType\r
\r
$content\r
--$boundary--\r
''';

  return Stream.value(utf8.encode(body));
}