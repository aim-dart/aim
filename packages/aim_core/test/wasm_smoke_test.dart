import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('aim_core compiles to wasm (no dart:io dependency)', () async {
    final outDir = await Directory.systemTemp.createTemp('aim_core_wasm_');
    addTearDown(() => outDir.delete(recursive: true));

    final result = await Process.run(
      'dart',
      [
        'compile',
        'wasm',
        'test/wasm_smoke/app.dart',
        '-o',
        '${outDir.path}/app.wasm',
      ],
    );

    expect(
      result.exitCode,
      equals(0),
      reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
    );
    expect(File('${outDir.path}/app.wasm').existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
