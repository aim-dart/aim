import 'dart:async';
import 'dart:collection';

/// Tuning knobs for [Pool].
class PoolOptions {
  PoolOptions({
    this.maxConnections = 10,
    this.acquireTimeout = const Duration(seconds: 30),
    this.idleTimeout = const Duration(minutes: 10),
    this.maxLifetime = const Duration(minutes: 30),
    this.validationInterval = const Duration(seconds: 30),
  }) {
    if (maxConnections < 1) {
      throw ArgumentError.value(
        maxConnections,
        'maxConnections',
        'must be at least 1',
      );
    }
    _requireNonNegative(acquireTimeout, 'acquireTimeout');
    _requireNonNegative(idleTimeout, 'idleTimeout');
    _requireNonNegative(maxLifetime, 'maxLifetime');
    _requireNonNegative(validationInterval, 'validationInterval');
  }

  /// Upper bound on connections (idle + in use + being created).
  final int maxConnections;

  /// How long [Pool.acquire] waits for a free connection before throwing
  /// [PoolTimeoutException].
  final Duration acquireTimeout;

  /// Idle connections unused for longer than this are closed.
  /// [Duration.zero] disables idle eviction.
  final Duration idleTimeout;

  /// Connections older than this are closed once they become idle.
  /// [Duration.zero] disables lifetime eviction.
  final Duration maxLifetime;

  /// An idle connection unused for at least this long is validated before
  /// being handed out. [Duration.zero] validates on every acquire.
  final Duration validationInterval;

  static void _requireNonNegative(Duration d, String name) {
    if (d.isNegative) {
      throw ArgumentError.value(d, name, 'must not be negative');
    }
  }
}

/// Immutable snapshot of a [Pool]'s state.
class PoolStats {
  const PoolStats({
    required this.total,
    required this.idle,
    required this.inUse,
    required this.waiting,
    required this.created,
    required this.destroyed,
    required this.timeouts,
    required this.validationFailures,
  });

  /// Connections that exist right now, including ones still being created.
  final int total;

  /// Connections sitting idle in the pool.
  final int idle;

  /// Connections currently checked out.
  final int inUse;

  /// Callers blocked in [Pool.acquire].
  final int waiting;

  /// Total connections ever created.
  final int created;

  /// Total connections ever destroyed.
  final int destroyed;

  /// Total [PoolTimeoutException]s thrown.
  final int timeouts;

  /// Total idle connections discarded because validation failed.
  final int validationFailures;

  @override
  String toString() =>
      'PoolStats(total: $total, idle: $idle, inUse: $inUse, waiting: $waiting, '
      'created: $created, destroyed: $destroyed, timeouts: $timeouts, '
      'validationFailures: $validationFailures)';
}

/// Thrown by [Pool.acquire] when no connection became available within
/// [PoolOptions.acquireTimeout].
class PoolTimeoutException implements Exception {
  PoolTimeoutException(this.waited, this.stats);

  /// How long the caller waited.
  final Duration waited;

  /// Pool state at the moment of the timeout.
  final PoolStats stats;

  @override
  String toString() =>
      'PoolTimeoutException: no connection available after '
      '${waited.inMilliseconds}ms ($stats)';
}

class _PooledEntry<C> {
  _PooledEntry(this.conn, this.createdAt) : lastUsedAt = createdAt;

  final C conn;
  final DateTime createdAt;
  DateTime lastUsedAt;
}

/// A bounded pool of reusable connections of type [C].
///
/// The pool knows nothing about the connection type. Callers supply
/// [create], [validate] and [destroy]. Connections are handed out with
/// [acquire] and must always be returned with [release]; pass
/// `discard: true` when the connection is known to be unusable.
class Pool<C> {
  Pool({
    required this.create,
    required this.validate,
    required this.destroy,
    required this.options,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// Opens a new connection.
  final Future<C> Function() create;

  /// Returns `true` if the idle connection is still usable.
  final Future<bool> Function(C conn) validate;

  /// Closes a connection. Errors thrown here are swallowed.
  final Future<void> Function(C conn) destroy;

  final PoolOptions options;
  final DateTime Function() _now;

  final List<_PooledEntry<C>> _idle = [];
  final Map<C, _PooledEntry<C>> _inUse = {};
  final Queue<Completer<C>> _waiters = Queue();

  /// Connections whose [create] has not completed yet. Counted in [_total]
  /// so concurrent acquires cannot overshoot [PoolOptions.maxConnections].
  int _pending = 0;

  bool _closed = false;
  int _created = 0;
  int _destroyed = 0;
  int _timeouts = 0;
  int _validationFailures = 0;

  int get _total => _idle.length + _inUse.length + _pending;

  /// `true` once [close] has been called.
  bool get isClosed => _closed;

  PoolStats get stats => PoolStats(
        total: _total,
        idle: _idle.length,
        inUse: _inUse.length,
        waiting: _waiters.length,
        created: _created,
        destroyed: _destroyed,
        timeouts: _timeouts,
        validationFailures: _validationFailures,
      );

  /// Checks out a connection.
  ///
  /// Reuses an idle connection when one exists, creates a new one when
  /// under [PoolOptions.maxConnections], otherwise waits for a [release].
  Future<C> acquire() async {
    if (_closed) throw StateError('Pool is closed');

    final idle = await _takeIdle();
    if (idle != null) return idle.conn;

    if (_total < options.maxConnections) {
      final entry = await _createEntry();
      if (_closed) {
        await _destroyEntry(entry);
        throw StateError('Pool is closed');
      }
      _inUse[entry.conn] = entry;
      return entry.conn;
    }

    return _waitForConnection();
  }

  /// Returns a connection obtained from [acquire].
  ///
  /// With `discard: true` the connection is destroyed instead of being
  /// reused. A waiting acquirer, if any, receives the connection directly.
  Future<void> release(C conn, {bool discard = false}) async {
    final entry = _inUse.remove(conn);
    if (entry == null) {
      throw StateError('Connection is not checked out from this pool');
    }
    if (discard || _closed) {
      await _destroyEntry(entry);
      _replenishForWaiters();
      return;
    }
    entry.lastUsedAt = _now();
    _handOff(entry);
  }

  /// Closes the pool: destroys idle connections and fails every waiter.
  /// Connections still checked out are destroyed when released.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    while (_waiters.isNotEmpty) {
      _waiters.removeFirst().completeError(StateError('Pool is closed'));
    }
    final idle = List<_PooledEntry<C>>.of(_idle);
    _idle.clear();
    for (final entry in idle) {
      await _destroyEntry(entry);
    }
  }

  // ---- internals -------------------------------------------------------

  /// Pops idle entries (LIFO) until one is usable. Returns null when none.
  Future<_PooledEntry<C>?> _takeIdle() async {
    while (_idle.isNotEmpty) {
      final entry = _idle.removeLast();
      _inUse[entry.conn] = entry;
      return entry;
    }
    return null;
  }

  Future<_PooledEntry<C>> _createEntry() async {
    _pending++;
    try {
      final conn = await create();
      _created++;
      return _PooledEntry(conn, _now());
    } finally {
      _pending--;
    }
  }

  Future<void> _destroyEntry(_PooledEntry<C> entry) async {
    _destroyed++;
    try {
      await destroy(entry.conn);
    } catch (_) {
      // A connection we are throwing away anyway; nothing useful to do.
    }
  }

  /// Gives [entry] to the first waiter, or parks it as idle.
  void _handOff(_PooledEntry<C> entry) {
    if (_waiters.isNotEmpty) {
      _inUse[entry.conn] = entry;
      _waiters.removeFirst().complete(entry.conn);
      return;
    }
    _idle.add(entry);
  }

  /// After a connection was destroyed, opens replacements for waiters
  /// (bounded by maxConnections). Runs in the background.
  void _replenishForWaiters() {
    while (!_closed &&
        _waiters.isNotEmpty &&
        _total < options.maxConnections) {
      // _createEntry increments _pending synchronously, so the loop
      // terminates.
      _createEntry().then(
        (entry) {
          if (_closed) {
            unawaited(_destroyEntry(entry));
            return;
          }
          _handOff(entry);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_waiters.isNotEmpty) {
            _waiters.removeFirst().completeError(error, stackTrace);
          }
        },
      );
    }
  }

  Future<C> _waitForConnection() {
    final completer = Completer<C>();
    _waiters.add(completer);
    return completer.future;
  }
}
