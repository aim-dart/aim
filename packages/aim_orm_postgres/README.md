# aim_orm_postgres

PostgreSQL ORM implementation for Dart with Record syntax table definitions and type-safe query builders.

## Overview

`aim_orm_postgres` provides a complete ORM solution for PostgreSQL databases. Define your tables using Dart's Record syntax and get type-safe query builders generated automatically.

## Features

- 🗄️ **Record Syntax Tables** - Define tables using Dart's modern Record syntax
- 🔄 **Code Generation** - Automatic query builder generation with `build_runner`
- 📝 **CRUD Operations** - Type-safe SELECT, INSERT, UPDATE, DELETE
- 🔍 **Query Builder** - Fluent API with WHERE, LIMIT, OFFSET support
- 💾 **Transactions** - Full transaction support
- 🔒 **Type-safe** - Compile-time type checking for all operations
- 🐘 **PostgreSQL Types** - UUID, SERIAL, JSONB support

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  aim_orm_postgres: ^0.0.1
  aim_postgres: ^0.0.1

dev_dependencies:
  aim_orm_codegen: ^0.0.1
  build_runner: ^2.4.0
```

Then run:

```bash
dart pub get
```

## Usage

### 1. Define Tables

Create a file (e.g., `lib/schema.dart`) with your table definitions:

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
  age: integer('age').nullable(),
  createdAt: timestamp('created_at').withDefault(DateTime.now()),
);

@PgTable('posts')
final posts = (
  id: serial('id').primaryKey(),
  userId: uuid('user_id').references(() => users.id),
  title: varchar('title', length: 255),
  content: text('content'),
  metadata: jsonb<Map<String, dynamic>>('metadata').nullable(),
);
```

### 2. Generate Code

Run the code generator:

```bash
dart run build_runner build
```

This generates `schema.g.dart` with type-safe query builders.

### 3. Connect and Query

```dart
import 'package:aim_postgres/aim_postgres.dart';
import 'schema.dart';

void main() async {
  final db = await PostgresDatabase.connect(
    'postgres://user:pass@localhost:5432/mydb',
  );

  // SELECT
  final allUsers = await db.users.select();

  // SELECT with WHERE
  final user = await db.users.select()
      .where(id: users.id.eq('some-uuid'))
      .limit(1);

  // INSERT
  await db.users.insert().values((
    id: 'generated-uuid',
    name: 'Alice',
    email: 'alice@example.com',
    createdAt: DateTime.now(),
  ));

  // UPDATE
  await db.users.update()
      .set((name: 'Bob'))
      .where(id: users.id.eq('some-uuid'));

  // DELETE
  await db.users.delete()
      .where(id: users.id.eq('some-uuid'));

  await db.close();
}
```

### Transactions

```dart
await db.transaction((tx) async {
  await tx.users.insert().values((
    id: 'uuid-1',
    name: 'User 1',
    email: 'user1@example.com',
    createdAt: DateTime.now(),
  ));

  await tx.users.insert().values((
    id: 'uuid-2',
    name: 'User 2',
    email: 'user2@example.com',
    createdAt: DateTime.now(),
  ));
});
```

### PostgreSQL Column Types

```dart
// UUID
uuid('id').primaryKey()

// Auto-increment
serial('id').primaryKey()

// JSONB
jsonb<Map<String, dynamic>>('metadata')

// Foreign Key
uuid('user_id').references(() => users.id)

// With onDelete action
uuid('user_id').references(() => users.id, onDelete: OnDeleteAction.cascade)
```

## Related Packages

- [aim_orm](https://pub.dev/packages/aim_orm) - ORM abstraction layer
- [aim_postgres](https://pub.dev/packages/aim_postgres) - PostgreSQL driver
- [aim_orm_codegen](https://pub.dev/packages/aim_orm_codegen) - Code generation

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
