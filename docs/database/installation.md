---
title: Database Installation - Aim
description: Install Aim database packages. PostgreSQL driver, database abstraction layer, and ORM setup guide.
head:
  - - meta
    - name: keywords
      content: Dart database install, aim_postgres setup, PostgreSQL Dart
---

# Installation

## Packages

Aim's database packages can be used independently:

| Package | Use Case |
|---------|----------|
| `aim_database` | Abstraction layer only (for custom driver implementations) |
| `aim_postgres` | PostgreSQL connection (includes `aim_database`) |
| `aim_orm` | ORM abstraction layer (Coming Soon) |
| `aim_orm_postgres` | PostgreSQL ORM (includes `aim_orm` + `aim_postgres`) |

## PostgreSQL

In most cases, add the PostgreSQL driver directly:

```bash
dart pub add aim_postgres
```

This also adds `aim_database` as a dependency.

## pubspec.yaml

```yaml
dependencies:
  aim_postgres: ^0.0.1
```

## Verify Installation

```dart
import 'package:aim_postgres/aim_postgres.dart';

void main() async {
  final db = await PostgresDatabase.connect(
    'postgresql://user:pass@localhost:5432/mydb',
  );

  print('Connected to PostgreSQL');

  final result = await db.query('SELECT version()');
  print('Version: ${result.first['version']}');

  await db.close();
}
```

## Connection String Format

```
postgresql://user:password@host:port/database?sslmode=require
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `user` | Username | required |
| `password` | Password | required |
| `host` | Server hostname | `localhost` |
| `port` | Server port | `5432` |
| `database` | Database name | required |
| `sslmode` | SSL mode | `prefer` |

### SSL Modes

| Mode | Description |
|------|-------------|
| `disable` | No SSL |
| `allow` | Try non-SSL first, then SSL |
| `prefer` | Try SSL first, then non-SSL |
| `require` | SSL required |
| `verify-ca` | SSL + verify CA |
| `verify-full` | SSL + verify CA + hostname |

## Next Steps

- [PostgreSQL Driver](/database/drivers/postgres) - Detailed usage guide
- [ORM](/database/orm/) - Coming Soon
