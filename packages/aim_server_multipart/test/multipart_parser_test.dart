import 'dart:convert';
import 'package:test/test.dart';
import 'package:aim_server_multipart/src/multipart_parser.dart';

void main() {
  group('Filename Sanitization', () {
    test('sanitizes path traversal attack (..)', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: '../../../etc/passwd',
        content: 'malicious content',
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
      expect(file!.originalFilename, '../../../etc/passwd');
      expect(file.filename, isNot(contains('..')));
      expect(file.filename, isNot(contains('/')));
      expect(file.filename, matches(RegExp(r'^file_\d+_[a-z0-9]{8}$')));
    });

    test('sanitizes absolute path (Unix)', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: '/tmp/evil.sh',
        content: 'malicious content',
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
      expect(file!.originalFilename, '/tmp/evil.sh');
      expect(file.filename, isNot(startsWith('/')));
      expect(file.filename, isNot(contains('/')));
      // パス区切りを含むファイル名からは拡張子を抽出しない（セキュリティ）
      expect(file.filename, isNot(contains('.')));
    });

    test('sanitizes Windows path (\\)', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: '..\\..\\Windows\\System32\\evil.dll',
        content: 'malicious content',
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
      expect(file!.originalFilename, '..\\..\\Windows\\System32\\evil.dll');
      expect(file.filename, isNot(contains('\\')));
      expect(file.filename, isNot(contains('..')));
      // パス区切りを含むファイル名からは拡張子を抽出しない（セキュリティ）
      expect(file.filename, isNot(contains('.')));
    });

    test('preserves safe extension', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: 'safe-file.txt',
        content: 'safe content',
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
      expect(file!.filename, endsWith('.txt'));
    });

    test('handles filename without extension', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: 'no-extension',
        content: 'content',
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
      expect(file!.filename, isNot(contains('.')));
      expect(file.filename, matches(RegExp(r'^file_\d+_[a-z0-9]{8}$')));
    });

    test('sanitizes extension with special characters', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: 'test.php<>',
        content: 'content',
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
      // 特殊文字が削除される
      expect(file!.filename, matches(RegExp(r'^file_\d+_[a-z0-9]{8}\.php$')));
    });

    test('handles very long extension', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: 'test.verylongextensionmorethan10chars',
        content: 'content',
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
      // 拡張子が10文字を超える場合は削除される
      expect(file!.filename, isNot(contains('.')));
    });

    test('handles multiple dots in filename', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: 'my.file.name.txt',
        content: 'content',
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
      // 最後のドットから拡張子を取得
      expect(file!.filename, endsWith('.txt'));
    });

    test('handles hidden file (starts with dot)', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: '.bashrc',
        content: 'content',
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
      // 隠しファイル（先頭がドット）は拡張子として扱わない
      expect(file!.filename, matches(RegExp(r'^file_\d+_[a-z0-9]{8}$')));
      expect(file.filename, isNot(contains('.')));
    });

    test('handles filename with only dots', () async {
      final body = _createMultipartBody(
        boundary: 'boundary',
        filename: '...',
        content: 'content',
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
      expect(file!.originalFilename, '...');
      // サニタイズ後は拡張子なし
      expect(file.filename, matches(RegExp(r'^file_\d+_[a-z0-9]{8}$')));
    });

    test('generates unique filenames for same original filename', () async {
      final body1 = _createMultipartBody(
        boundary: 'boundary',
        filename: 'test.txt',
        content: 'content1',
      );
      final body2 = _createMultipartBody(
        boundary: 'boundary',
        filename: 'test.txt',
        content: 'content2',
      );

      final result1 = await parseMultipart(
        body: body1,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );
      final result2 = await parseMultipart(
        body: body2,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );

      final file1 = result1.file('file');
      final file2 = result2.file('file');

      expect(file1, isNotNull);
      expect(file2, isNotNull);
      // 同じオリジナルファイル名でも、サニタイズ後は異なる
      expect(file1!.filename, isNot(equals(file2!.filename)));
    });
  });

  group('Extension Extraction', () {
    test('validates regex in extension extraction', () async {
      // 正規表現 [^\w.] が正しく動作するかテスト
      final testCases = {
        'test.txt': '.txt',
        'test.TXT': '.TXT',
        'test.txt.bak': '.bak',
        'test.php<>': '.php', // 特殊文字は削除される
        'test.t@t': '.tt', // @は削除される
        'test.123': '.123',
        'test._ext': '._ext',
      };

      for (final entry in testCases.entries) {
        final body = _createMultipartBody(
          boundary: 'boundary',
          filename: entry.key,
          content: 'content',
        );

        final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );
        final file = result.file('file');

        expect(
          file!.filename,
          endsWith(entry.value),
          reason: 'Filename "${entry.key}" should have extension "${entry.value}"',
        );
      }
    });

    test('handles edge cases in extension', () async {
      final testCases = {
        'test.': '', // ドットで終わる場合は拡張子なし
        '.ext': '', // ドットで始まる場合（隠しファイル）は拡張子なし
        'test..txt': '.txt', // 連続するドット
      };

      for (final entry in testCases.entries) {
        final body = _createMultipartBody(
          boundary: 'boundary',
          filename: entry.key,
          content: 'content',
        );

        final result = await parseMultipart(
        body: body,
        boundary: 'boundary',
        maxFileSize: null,
        maxTotalSize: null,
        allowedMimeTypes: null,
      );
        final file = result.file('file');

        if (entry.value.isEmpty) {
          expect(file!.filename, isNot(contains('.')));
        } else {
          expect(file!.filename, endsWith(entry.value));
        }
      }
    });
  });
}

/// テスト用のmultipartリクエストボディを生成
Stream<List<int>> _createMultipartBody({
  required String boundary,
  required String filename,
  required String content,
  String fieldName = 'file',
}) {
  final body = '''
--$boundary\r
Content-Disposition: form-data; name="$fieldName"; filename="$filename"\r
Content-Type: application/octet-stream\r
\r
$content\r
--$boundary--\r
''';

  return Stream.value(utf8.encode(body));
}