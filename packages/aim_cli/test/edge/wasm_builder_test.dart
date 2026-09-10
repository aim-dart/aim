import 'package:aim_cli/src/edge/wasm_builder.dart';
import 'package:test/test.dart';

void main() {
  group('exportCompiledApp', () {
    test('exports the CompiledApp class emitted by dart compile wasm', () {
      const input = 'export async function compile(bytes) {}\n'
          'class CompiledApp {\n  constructor() {}\n}\n';
      expect(
        exportCompiledApp(input),
        'export async function compile(bytes) {}\n'
        'export class CompiledApp {\n  constructor() {}\n}\n',
      );
    });

    test('leaves an already exported class untouched', () {
      const input = 'export class CompiledApp {}\n';
      expect(exportCompiledApp(input), input);
    });

    test('does not touch other classes', () {
      const input = 'class Other {}\nclass CompiledApp {}\n';
      expect(exportCompiledApp(input), 'class Other {}\nexport class CompiledApp {}\n');
    });
  });
}
