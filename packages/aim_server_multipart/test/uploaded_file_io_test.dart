import 'dart:io';

import 'package:aim_server_multipart/aim_server_multipart.dart';
import 'package:aim_server_multipart/aim_server_multipart_io.dart';
import 'package:test/test.dart';

void main() {
  test('saveTo writes the uploaded bytes to disk', () async {
    final dir = await Directory.systemTemp.createTemp('aim_multipart_');
    addTearDown(() => dir.delete(recursive: true));
    const file = UploadedFile(
      filename: 'file_1_abc.txt',
      originalFilename: 'hello.txt',
      contentType: 'text/plain',
      bytes: [104, 105],
    );

    await file.saveTo('${dir.path}/out.txt');

    expect(await File('${dir.path}/out.txt').readAsString(), equals('hi'));
  });
}
