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
