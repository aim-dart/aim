import 'package:release/template_pins.dart';
import 'package:test/test.dart';

void main() {
  group('bumpTemplatePins', () {
    test('rewrites aim_* pins while leaving other lines untouched', () {
      const source = '''
dependencies:
  aim_server: ^0.1.1

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6

environment:
  sdk: ^3.13.0

# This project depends on aim_server for its web framework.
dependencies:
  aim_edge: ^0.1.1
''';

      final result = bumpTemplatePins(source, '0.2.0');

      expect(result, contains('  aim_server: ^0.2.0'));
      expect(result, contains('  aim_edge: ^0.2.0'));
      expect(result, contains('  lints: ^6.0.0'));
      expect(result, contains('  test: ^1.25.6'));
      expect(result, contains('  sdk: ^3.13.0'));
      expect(
        result,
        contains('# This project depends on aim_server for its web framework.'),
      );
      expect(result, isNot(contains('^0.1.1')));
    });

    test('preserves indentation', () {
      const source = '    aim_core: ^0.1.1\n';

      final result = bumpTemplatePins(source, '0.2.0');

      expect(result, equals('    aim_core: ^0.2.0\n'));
    });

    test('rewrites a pre-release pin', () {
      const source = 'aim_core: ^0.2.0-dev.1\n';

      final result = bumpTemplatePins(source, '0.3.0');

      expect(result, equals('aim_core: ^0.3.0\n'));
    });

    test('is idempotent when already at the target version', () {
      const source = '  aim_edge: ^0.2.0\n';

      final result = bumpTemplatePins(source, '0.2.0');

      expect(result, equals(source));
    });
  });
}
