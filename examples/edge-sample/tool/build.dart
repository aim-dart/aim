// Compiles lib/main.dart to .out/main.wasm and patches the generated loader
// so `CompiledApp` can be imported from src/index.mjs.
import 'dart:io';

Future<void> main() async {
  final result = await Process.run(Platform.resolvedExecutable, [
    'compile',
    'wasm',
    'lib/main.dart',
    '-o',
    '.out/main.wasm',
  ]);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) exit(result.exitCode);

  final loader = File('.out/main.mjs');
  final patched = loader.readAsStringSync().replaceFirst(
    RegExp(r'^class CompiledApp', multiLine: true),
    'export class CompiledApp',
  );
  loader.writeAsStringSync(patched);
  stdout.writeln('Built .out/main.wasm and .out/main.mjs');
}
