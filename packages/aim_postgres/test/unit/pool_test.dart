import 'package:aim_postgres/src/pool/pool.dart';
import 'package:test/test.dart';

void main() {
  group('PoolOptions', () {
    test('has documented defaults', () {
      final o = PoolOptions();
      expect(o.maxConnections, 10);
      expect(o.acquireTimeout, const Duration(seconds: 30));
      expect(o.idleTimeout, const Duration(minutes: 10));
      expect(o.maxLifetime, const Duration(minutes: 30));
      expect(o.validationInterval, const Duration(seconds: 30));
    });

    test('rejects maxConnections < 1', () {
      expect(() => PoolOptions(maxConnections: 0), throwsArgumentError);
    });

    test('rejects negative durations', () {
      expect(
        () => PoolOptions(acquireTimeout: const Duration(seconds: -1)),
        throwsArgumentError,
      );
      expect(
        () => PoolOptions(idleTimeout: const Duration(seconds: -1)),
        throwsArgumentError,
      );
      expect(
        () => PoolOptions(maxLifetime: const Duration(seconds: -1)),
        throwsArgumentError,
      );
      expect(
        () => PoolOptions(validationInterval: const Duration(seconds: -1)),
        throwsArgumentError,
      );
    });

    test('accepts Duration.zero', () {
      expect(
        () => PoolOptions(idleTimeout: Duration.zero, maxLifetime: Duration.zero),
        returnsNormally,
      );
    });
  });

  group('PoolTimeoutException', () {
    test('toString mentions waited time', () {
      const stats = PoolStats(
        total: 2,
        idle: 0,
        inUse: 2,
        waiting: 1,
        created: 2,
        destroyed: 0,
        timeouts: 1,
        validationFailures: 0,
      );
      final e = PoolTimeoutException(const Duration(milliseconds: 1500), stats);
      expect(e.toString(), contains('1500ms'));
      expect(e.toString(), contains('inUse: 2'));
    });
  });
}
