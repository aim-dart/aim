import 'dart:io';

import 'package:path/path.dart' as p;

/// Thrown when `dart compile wasm` fails.
class WasmBuildException implements Exception {
  final int exitCode;
  WasmBuildException(this.exitCode);

  @override
  String toString() => 'dart compile wasm failed with exit code $exitCode';
}

/// Makes `CompiledApp` importable from the JS entry module.
///
/// Dart 3.13's `dart compile wasm` emits `class CompiledApp` without `export`.
String exportCompiledApp(String mjs) => mjs.replaceFirst(
      RegExp(r'^class CompiledApp\b', multiLine: true),
      'export class CompiledApp',
    );

/// Compiles [entry] to `<outputDir>/main.wasm` and patches
/// `<outputDir>/main.mjs` so `index.mjs` can import `CompiledApp`.
///
/// Compiles into a temporary staging directory inside [outputDir] first,
/// patches the loader there, and only then renames the finished files into
/// [outputDir]. This keeps a file watcher on [outputDir] (e.g. wrangler's)
/// from ever observing a half-written `main.mjs` that dart compile wasm has
/// written but this function has not patched yet. The staging directory is
/// removed afterwards, including when the compile fails.
///
/// Compiler output is inherited so the user sees errors directly.
Future<void> buildWasm({
  required String entry,
  required String outputDir,
}) async {
  await Directory(outputDir).create(recursive: true);

  // Sweep stale staging dirs left over from an interrupted build.
  for (final entity in Directory(outputDir).listSync()) {
    if (entity is Directory && p.basename(entity.path).startsWith('.staging-')) {
      try {
        await entity.delete(recursive: true);
      } catch (_) {
        // Ignore: best-effort cleanup.
      }
    }
  }

  final staging = await Directory(outputDir).createTemp('.staging-');
  try {
    final wasmPath = p.join(staging.path, 'main.wasm');

    final process = await Process.start(
      Platform.resolvedExecutable,
      ['compile', 'wasm', entry, '-o', wasmPath],
      mode: ProcessStartMode.inheritStdio,
    );
    final exitCode = await process.exitCode;
    if (exitCode != 0) throw WasmBuildException(exitCode);

    final loader = File(p.join(staging.path, 'main.mjs'));
    loader.writeAsStringSync(exportCompiledApp(loader.readAsStringSync()));

    for (final entity in staging.listSync()) {
      if (entity is! File) continue;
      await entity.rename(p.join(outputDir, p.basename(entity.path)));
    }
  } finally {
    if (await staging.exists()) {
      await staging.delete(recursive: true);
    }
  }
}
