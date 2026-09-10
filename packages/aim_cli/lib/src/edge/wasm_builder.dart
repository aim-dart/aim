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
/// Compiler output is inherited so the user sees errors directly.
Future<void> buildWasm({
  required String entry,
  required String outputDir,
}) async {
  await Directory(outputDir).create(recursive: true);
  final wasmPath = p.join(outputDir, 'main.wasm');

  final process = await Process.start(
    Platform.resolvedExecutable,
    ['compile', 'wasm', entry, '-o', wasmPath],
    mode: ProcessStartMode.inheritStdio,
  );
  final exitCode = await process.exitCode;
  if (exitCode != 0) throw WasmBuildException(exitCode);

  final loader = File(p.join(outputDir, 'main.mjs'));
  loader.writeAsStringSync(exportCompiledApp(loader.readAsStringSync()));
}
