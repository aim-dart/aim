import 'package:aim_cli/src/config/aim_config.dart';
import 'package:test/test.dart';

void main() {
  group('AimConfig.parse', () {
    test('defaults to the server target when aim: is absent', () {
      final config = AimConfig.parse('name: app\n');
      expect(config.target, AimTarget.server);
      expect(config.configuredEntry, isNull);
      expect(config.defaultEntry, 'bin/server.dart');
      expect(config.env, isEmpty);
    });

    test('reads target: edge and switches the default entry', () {
      final config = AimConfig.parse('aim:\n  target: edge\n');
      expect(config.target, AimTarget.edge);
      expect(config.defaultEntry, 'lib/main.dart');
    });

    test('rejects an unknown target', () {
      expect(
        () => AimConfig.parse('aim:\n  target: deno\n'),
        throwsA(isA<FormatException>()),
      );
    });

    test('resolveEntry prefers the CLI override, then aim.entry, then default',
        () {
      final withEntry = AimConfig.parse('aim:\n  entry: bin/api.dart\n');
      expect(withEntry.resolveEntry('bin/cli.dart'), 'bin/cli.dart');
      expect(withEntry.resolveEntry(null), 'bin/api.dart');

      final withoutEntry = AimConfig.parse('aim:\n  target: edge\n');
      expect(withoutEntry.resolveEntry(null), 'lib/main.dart');
    });

    test('expands env values', () {
      final config = AimConfig.parse(
        'aim:\n  env:\n    PORT: "8080"\n    HOST: \${AIM_TEST_UNSET_HOST:0.0.0.0}\n',
      );
      expect(config.env, {'PORT': '8080', 'HOST': '0.0.0.0'});
    });

    test('ignores a non-map aim: section', () {
      final config = AimConfig.parse('aim: true\n');
      expect(config.target, AimTarget.server);
      expect(config.env, isEmpty);
    });
  });
}
