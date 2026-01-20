# aim_postgres

A native PostgreSQL driver for Dart with full wire protocol implementation.

## Overview

`aim_postgres` is a pure Dart PostgreSQL driver that implements the PostgreSQL wire protocol from scratch. No external dependencies required for database communication - just connect and query.

## Features

- 🔌 **Native Wire Protocol** - Pure Dart implementation of PostgreSQL protocol 3.0
- 🔒 **SSL/TLS Support** - Multiple SSL modes including certificate verification
- 🔑 **Authentication** - Cleartext, MD5, and SCRAM-SHA-256 authentication
- 📝 **Query Protocols** - Both Simple and Extended Query protocols
- 🎯 **Parameter Binding** - Named (`:name`) and positional (`$1`) parameters
- 💾 **Transactions** - Full transaction support with automatic rollback
- 🔔 **Notice Messages** - Stream-based notice/warning message handling

## Installation

Add `aim_postgres` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_postgres: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Connection

```dart
import 'package:aim_postgres/aim_postgres.dart';

void main() async {
  final db = await PostgresDatabase.connect(
    'postgresql://user:password@localhost:5432/mydb',
  );

  final results = await db.query('SELECT * FROM users');
  for (final row in results) {
    print(row['name']);
  }

  await db.close();
}
```

### Parameterized Queries

#### Positional Parameters ($1, $2, ...)

```dart
final results = await db.query(
  'SELECT * FROM users WHERE id = \$1 AND status = \$2',
  args: [123, 'active'],
);
```

#### Named Parameters (:name)

```dart
final results = await db.query(
  'SELECT * FROM users WHERE id = :id AND status = :status',
  params: {'id': 123, 'status': 'active'},
);
```

### Execute (INSERT/UPDATE/DELETE)

```dart
await db.execute(
  'INSERT INTO users (name, email) VALUES (\$1, \$2)',
  args: ['Alice', 'alice@example.com'],
);

await db.execute(
  'UPDATE users SET name = :name WHERE id = :id',
  params: {'name': 'Bob', 'id': 123},
);

await db.execute(
  'DELETE FROM users WHERE id = \$1',
  args: [123],
);
```

### Transactions

```dart
await db.transaction((tx) async {
  await tx.execute(
    'INSERT INTO accounts (user_id, balance) VALUES (\$1, \$2)',
    args: [1, 1000],
  );

  await tx.execute(
    'UPDATE accounts SET balance = balance - \$1 WHERE user_id = \$2',
    args: [100, 1],
  );

  // If any operation fails, all changes are rolled back
});
```

### SSL/TLS Connections

```dart
// Require SSL (skip certificate verification)
final db = await PostgresDatabase.connect(
  'postgresql://user:pass@host:5432/db?sslmode=require',
);

// Verify CA certificate
final db = await PostgresDatabase.connect(
  'postgresql://user:pass@host:5432/db?sslmode=verify-ca&sslrootcert=/path/to/ca.crt',
);

// Verify CA and hostname
final db = await PostgresDatabase.connect(
  'postgresql://user:pass@host:5432/db?sslmode=verify-full&sslrootcert=/path/to/ca.crt',
);
```

#### SSL Modes

| Mode | Description |
|------|-------------|
| `disable` | No SSL (default) |
| `allow` | Prefer SSL, fallback to plaintext |
| `prefer` | Prefer SSL, fallback to plaintext |
| `require` | Require SSL, skip certificate verification |
| `verify-ca` | Require SSL, verify CA certificate |
| `verify-full` | Require SSL, verify CA and hostname |

### Notice Messages

PostgreSQL sends notice and warning messages during query execution. You can listen to these:

```dart
final connection = await PostgresConnection.connect('...');

connection.noticeMessage.listen((notice) {
  print('${notice.severity}: ${notice.message}');
});
```

## API Reference

### PostgresDatabase

- `connect(connectionString)` - Connect to a PostgreSQL database
- `query(sql, {params, args})` - Execute a query and return results
- `execute(sql, {params, args})` - Execute a statement (INSERT/UPDATE/DELETE)
- `transaction(fn)` - Execute operations in a transaction
- `close()` - Close the connection

### Connection String Format

```
postgresql://username:password@host:port/database?param=value
```

Supported parameters:
- `sslmode` - SSL connection mode
- `sslrootcert` - Path to CA certificate file

## Related Packages

- [aim_database](https://pub.dev/packages/aim_database) - Database abstraction layer
- [aim_orm](https://pub.dev/packages/aim_orm) - ORM abstraction layer
- [aim_orm_postgres](https://pub.dev/packages/aim_orm_postgres) - PostgreSQL ORM implementation

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
