import 'dart:io';

import 'package:aim_cli/aim_cli.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory tmp;
  late String previousCwd;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('aim_create_');
    previousCwd = Directory.current.path;
    Directory.current = tmp;
  });

  tearDown(() async {
    Directory.current = previousCwd;
    await tmp.delete(recursive: true);
  });

  Future<void> create(List<String> args) {
    final runner = CommandRunner<void>('aim', 'test')
      ..addCommand(CreateCommand());
    return runner.run(['create', ...args]);
  }

  String read(String relative) =>
      File(p.join(tmp.path, relative)).readAsStringSync();

  test('scaffolds an edge project', () async {
    await create(['my_edge', '--target', 'edge']);

    final files = Directory(p.join(tmp.path, 'my_edge'))
        .listSync(recursive: true)
        .whereType<File>()
        .map((f) => p.relative(f.path, from: p.join(tmp.path, 'my_edge')))
        .toSet();
    expect(files, {
      'pubspec.yaml',
      'README.md',
      'lib/main.dart',
      'src/index.mjs',
      'wrangler.jsonc',
      '.gitignore',
    });

    expect(read('my_edge/pubspec.yaml'), contains('target: edge'));
    expect(read('my_edge/pubspec.yaml'), contains('aim_edge:'));
    expect(read('my_edge/lib/main.dart'), contains('app.serveEdge();'));
    expect(read('my_edge/wrangler.jsonc'), contains('"name": "my_edge"'));
    expect(read('my_edge/wrangler.jsonc'), contains('"main": "src/index.mjs"'));
    expect(read('my_edge/src/index.mjs'), contains('build/edge/main.wasm'));
  });

  test('scaffolds a server project by default', () async {
    await create(['my_server']);

    expect(File(p.join(tmp.path, 'my_server/bin/server.dart')).existsSync(), isTrue);
    expect(File(p.join(tmp.path, 'my_server/Dockerfile')).existsSync(), isTrue);
    expect(read('my_server/pubspec.yaml'), contains('aim_server: ^0.1.1'));
    expect(read('my_server/pubspec.yaml'), isNot(contains('target: edge')));
  });

  test('rejects an unknown target', () async {
    expect(create(['x', '--target', 'deno']), throwsA(isA<UsageException>()));
  });
}
