## Unreleased

### Features

- Connection pooling: `PostgresDatabase.connect()` now manages a pool of connections.
  New named parameters `maxConnections` (default 10), `acquireTimeout` (30s),
  `idleTimeout` (10min), `maxLifetime` (30min) and `validationInterval` (30s).
  `PostgresDatabase.poolStats` exposes a `PoolStats` snapshot.
  `PoolTimeoutException` is thrown when no connection becomes available in time.
- Queries on a single connection are now serialized, so concurrent queries inside
  one transaction no longer corrupt the protocol stream.
- `PostgresConnection.isBroken`, `isClosed` and `ping()`.

### Fixes

- Concurrent `query()` / `execute()` calls on one `PostgresDatabase` previously
  interleaved on a single socket. They now run on separate pooled connections.


## 0.1.1

See [Release Notes](https://github.com/aim-dart/aim/releases/tag/0.1.1)


## 0.1.0

See [Release Notes](https://github.com/aim-dart/aim/releases/tag/v0.1.0)


## 0.0.1

Initial release of aim_postgres - A native PostgreSQL driver for Dart.

### Features

- PostgreSQL Wire Protocol:
  - Full implementation of PostgreSQL protocol version 3.0
  - Simple Query Protocol for static SQL
  - Extended Query Protocol for parameterized queries
  - Message parsing for all common message types

- SSL/TLS Support:
  - Multiple SSL modes: disable, allow, prefer, require, verify-ca, verify-full
  - CA certificate verification
  - Hostname verification (verify-full mode)

- Authentication:
  - Cleartext password authentication
  - MD5 password authentication
  - SCRAM-SHA-256 authentication (PostgreSQL 10+)

- Query Execution:
  - `query()` method for SELECT statements
  - `execute()` method for INSERT/UPDATE/DELETE
  - Positional parameters (`$1`, `$2`, ...)
  - Named parameters (`:name`, `:id`, ...)
  - Automatic parameter conversion (int, double, String, bool, DateTime)

- Transactions:
  - `transaction()` method with callback
  - Automatic COMMIT on success
  - Automatic ROLLBACK on error

- Notice Messages:
  - Stream-based notice/warning message handling
  - Access via `connection.noticeMessage` stream

### Supported

- Dart SDK: `^3.10.0`
- PostgreSQL: 9.5+ (SCRAM-SHA-256 requires PostgreSQL 10+)

### What's Included

- `PostgresDatabase` - High-level database API
- `PostgresConnection` - Low-level connection handling
- `PostgresTransaction` - Transaction context
- `QueryResult` - Query result container
- `QueryException` - Query error handling
- SSL mode enums and authentication type enums
