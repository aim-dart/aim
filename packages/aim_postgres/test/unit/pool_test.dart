import 'package:aim_postgres/src/pool/pool.dart';
import 'package:test/test.dart';

class FakeConn {
  FakeConn(this.id);
  final int id;

  @override
  String toString() => 'FakeConn($id)';
}

/// Records every callback the pool makes so tests can assert on them.
class Harness {
  int _nextId = 0;
  final created = <FakeConn>[];
  final destroyed = <FakeConn>[];
  int validateCalls = 0;
  bool validateResult = true;
  Object? createError;

  /// Injected clock. Tests advance it with [advance].
  DateTime clock = DateTime(2026, 1, 1);

  void advance(Duration d) => clock = clock.add(d);

  Pool<FakeConn> pool(PoolOptions options) => Pool<FakeConn>(
        create: () async {
          final error = createError;
          if (error != null) throw error;
          final conn = FakeConn(_nextId++);
          created.add(conn);
          return conn;
        },
        validate: (_) async {
          validateCalls++;
          return validateResult;
        },
        destroy: (conn) async => destroyed.add(conn),
        options: options,
        now: () => clock,
      );
}

/// Options that disable every timer-driven feature so tests are deterministic.
PoolOptions quietOptions({int maxConnections = 2}) => PoolOptions(
      maxConnections: maxConnections,
      acquireTimeout: const Duration(milliseconds: 200),
      idleTimeout: Duration.zero,
      maxLifetime: Duration.zero,
      validationInterval: const Duration(seconds: 30),
    );

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

  group('Pool acquire/release', () {
    late Harness h;
    late Pool<FakeConn> pool;

    setUp(() {
      h = Harness();
      pool = h.pool(quietOptions());
    });

    tearDown(() => pool.close());

    test('creates connections lazily up to maxConnections', () async {
      final a = await pool.acquire();
      final b = await pool.acquire();
      expect(a, isNot(same(b)));
      expect(h.created, hasLength(2));
      expect(pool.stats.total, 2);
      expect(pool.stats.inUse, 2);
      expect(pool.stats.idle, 0);
    });

    test('reuses the most recently released idle connection (LIFO)', () async {
      final a = await pool.acquire();
      final b = await pool.acquire();
      await pool.release(a);
      await pool.release(b);
      final next = await pool.acquire();
      expect(next, same(b));
      expect(h.created, hasLength(2));
      expect(pool.stats.idle, 1);
    });

    test('blocks when exhausted and hands the released connection to the waiter',
        () async {
      final a = await pool.acquire();
      await pool.acquire();
      var got = false;
      final waiting = pool.acquire().then((c) {
        got = true;
        return c;
      });
      await Future<void>.delayed(Duration.zero);
      expect(got, isFalse);
      expect(pool.stats.waiting, 1);

      await pool.release(a);
      final c = await waiting;
      expect(c, same(a));
      expect(pool.stats.idle, 0, reason: 'handed off directly, not parked');
      expect(pool.stats.waiting, 0);
      expect(h.created, hasLength(2), reason: 'no third connection created');
    });

    test('discard destroys the connection and replenishes for a waiter',
        () async {
      final a = await pool.acquire();
      await pool.acquire();
      final waiting = pool.acquire();
      await Future<void>.delayed(Duration.zero);

      await pool.release(a, discard: true);
      final c = await waiting;
      expect(h.destroyed, [a]);
      expect(c, isNot(same(a)));
      expect(h.created, hasLength(3));
      expect(pool.stats.destroyed, 1);
      expect(pool.stats.total, 2);
    });

    test('release of a connection not checked out throws', () async {
      expect(() => pool.release(FakeConn(99)), throwsStateError);
    });

    test('stats counts created', () async {
      await pool.acquire();
      expect(pool.stats.created, 1);
      expect(pool.stats.destroyed, 0);
      expect(pool.stats.timeouts, 0);
      expect(pool.stats.validationFailures, 0);
    });
  });

  group('Pool timeout and create failure', () {
    late Harness h;

    setUp(() => h = Harness());

    test('throws PoolTimeoutException when no connection frees up', () async {
      final pool = h.pool(quietOptions(maxConnections: 1));
      final a = await pool.acquire();

      await expectLater(
        pool.acquire(),
        throwsA(isA<PoolTimeoutException>()
            .having((e) => e.waited, 'waited', const Duration(milliseconds: 200))
            .having((e) => e.stats.inUse, 'stats.inUse', 1)),
      );
      expect(pool.stats.timeouts, 1);
      expect(pool.stats.waiting, 0, reason: 'timed-out waiter was removed');

      // A release after the timeout must park the connection, not hand it
      // to the dead waiter.
      await pool.release(a);
      expect(pool.stats.idle, 1);
      await pool.close();
    });

    test('create failure propagates and frees the slot', () async {
      final pool = h.pool(quietOptions(maxConnections: 1));
      h.createError = const FormatException('bad url');

      await expectLater(pool.acquire(), throwsFormatException);
      expect(pool.stats.total, 0);

      h.createError = null;
      final c = await pool.acquire();
      expect(c, isA<FakeConn>());
      expect(pool.stats.total, 1);
      await pool.close();
    });

    test('create failure while replenishing fails the waiter', () async {
      final pool = h.pool(quietOptions(maxConnections: 1));
      final a = await pool.acquire();
      final waiting = pool.acquire();
      await Future<void>.delayed(Duration.zero);

      h.createError = const FormatException('down');
      await pool.release(a, discard: true);

      await expectLater(waiting, throwsFormatException);
      expect(pool.stats.total, 0);
      await pool.close();
    });

    test('replenish opens at most one replacement per waiter', () async {
      final pool = h.pool(quietOptions(maxConnections: 3));
      final a = await pool.acquire();
      final b = await pool.acquire();
      final c = await pool.acquire();
      final waiting = pool.acquire();
      await Future<void>.delayed(Duration.zero);

      await pool.release(a, discard: true);
      await pool.release(b, discard: true);
      await waiting;
      expect(h.created, hasLength(4), reason: 'one replacement for one waiter');
      expect(pool.stats.total, 2);
      await pool.release(c);
      await pool.close();
    });
  });
}
