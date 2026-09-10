import 'package:aim_core/aim_core.dart';
import 'package:test/test.dart';

class CounterVariables extends Variables {
  int hits = 0;
}

void main() {
  group('Variables', () {
    test('variablesFactory creates fresh variables per request', () async {
      final app = Aim<CounterVariables>(
        variablesFactory: () => CounterVariables(),
      );
      app.use((c, next) async {
        c.variables.hits++;
        await next();
      });
      app.get('/', (c) async => c.text('${c.variables.hits}'));

      final first = await app.handle(Request('GET', Uri.parse('http://x/')));
      final second = await app.handle(Request('GET', Uri.parse('http://x/')));

      expect(await first.readAsString(), '1');
      expect(await second.readAsString(), '1');
    });

    test('default variables are EmptyVariables', () async {
      final app = Aim();
      late Variables seen;
      app.get('/', (c) async {
        seen = c.variables;
        return c.text('ok');
      });

      await app.handle(Request('GET', Uri.parse('http://x/')));

      expect(seen, isA<EmptyVariables>());
    });

    test('deprecated Env and EmptyEnv aliases still resolve', () {
      // ignore: deprecated_member_use_from_same_package
      final Env legacy = EmptyEnv();
      expect(legacy, isA<Variables>());
    });
  });
}
