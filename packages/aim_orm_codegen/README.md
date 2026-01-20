# aim_orm_codegen

Code generation for aim_orm using build_runner. Generates type-safe query builders from table definitions.

## Overview

`aim_orm_codegen` is the code generation package for the aim ORM ecosystem. It analyzes your table definitions and generates type-safe query builders, row types, and database extension methods.

## Features

- 🔄 **Automatic Code Generation** - Generate code with `build_runner`
- 📝 **Query Builders** - SELECT, INSERT, UPDATE, DELETE builders
- 🏷️ **Type-safe Rows** - Generated Row typedefs for query results
- 🔌 **Database Extensions** - Extension methods on PostgresDatabase and PostgresTransaction
- 🎯 **Record Syntax Support** - Works with Dart's modern Record syntax

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  aim_orm: ^0.0.1
  aim_orm_postgres: ^0.0.1
  aim_postgres: ^0.0.1

dev_dependencies:
  aim_orm_codegen: ^0.0.1
  build_runner: ^2.4.0
```

Create a `build.yaml` in your project root:

```yaml
targets:
  $default:
    builders:
      aim_orm_codegen|record_pg_table:
        enabled: true
```

## Usage

### 1. Define Tables

```dart
import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';

part 'schema.g.dart';

@PgTable('users')
final users = (
  id: uuid('id').primaryKey(),
  name: varchar('name', length: 100),
  email: varchar('email', length: 255).unique(),
);
```

### 2. Run Code Generation

```bash
dart run build_runner build
```

Or watch for changes:

```bash
dart run build_runner watch
```

### 3. Generated Code

The generator creates:

- **Row typedef**: `UsersRow` - Type-safe record for query results
- **QueryBuilder**: `UsersQueryBuilder` - Entry point for queries
- **SelectBuilder**: `UsersSelectBuilder` - SELECT with WHERE, LIMIT, OFFSET
- **InsertBuilder**: `UsersInsertBuilder` - Type-safe INSERT
- **UpdateBuilder**: `UsersUpdateBuilder` - UPDATE with SET and WHERE
- **DeleteBuilder**: `UsersDeleteBuilder` - DELETE with WHERE
- **Database extension**: `db.users` accessor
- **Transaction extension**: `tx.users` accessor

### 4. Use Generated Code

```dart
void main() async {
  final db = await PostgresDatabase.connect('...');

  // All operations are type-safe
  final rows = await db.users.select();

  for (final row in rows) {
    print(row.name);  // Type-safe access
    print(row.email);
  }

  await db.close();
}
```

## Builders

| Builder | Description |
|---------|-------------|
| `record_pg_table` | Generates code for `@PgTable` annotated Record definitions |
| `table` | Generates code for class-based table definitions (legacy) |

## Related Packages

- [aim_orm](https://pub.dev/packages/aim_orm) - ORM abstraction layer
- [aim_orm_postgres](https://pub.dev/packages/aim_orm_postgres) - PostgreSQL ORM implementation
- [aim_postgres](https://pub.dev/packages/aim_postgres) - PostgreSQL driver

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
