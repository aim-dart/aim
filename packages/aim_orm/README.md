# aim_orm

A type-safe ORM abstraction layer for Dart with query builders and column definitions.

## Overview

`aim_orm` provides the core abstractions for building type-safe ORMs in Dart. This package defines column types, query builders, and condition operators that database-specific implementations use.

This package is the foundation layer. For a complete ORM solution, use it with a database-specific implementation like [aim_orm_postgres](https://pub.dev/packages/aim_orm_postgres).

## Features

- 📊 **Column Types** - Type-safe column definitions (integer, varchar, text, timestamp)
- 🔧 **Column Modifiers** - Primary key, unique, nullable, default values, indexes
- 🔍 **Condition Operators** - Type-safe WHERE clause conditions
- 🏗️ **Query Builder Foundation** - Base classes for building SQL queries
- 🔒 **Type-safe** - Full Dart type safety throughout the API

## Installation

Add `aim_orm` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_orm: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Column Types

```dart
import 'package:aim_orm/aim_orm.dart';

// Basic column types
final id = integer('id');
final name = varchar('name', length: 100);
final bio = text('bio');
final createdAt = timestamp('created_at');
```

### Column Modifiers

```dart
// Primary key
final id = integer('id').primaryKey();

// Unique constraint
final email = varchar('email', length: 255).unique();

// Nullable column
final age = integer('age').nullable();

// Default value
final createdAt = timestamp('created_at').withDefault(DateTime.now());

// Indexed column
final name = varchar('name', length: 100).indexed();

// Chaining modifiers
final email = varchar('email', length: 255).unique().indexed();
```

### Condition Operators

```dart
// Equality
column.eq(value)       // column = value

// Comparison
column.gt(value)       // column > value
column.lt(value)       // column < value
column.gte(value)      // column >= value
column.lte(value)      // column <= value

// IN clause
column.inList([...])   // column IN (...)
```

## Database Implementations

- [aim_orm_postgres](https://pub.dev/packages/aim_orm_postgres) - PostgreSQL implementation with code generation

## Related Packages

- [aim_database](https://pub.dev/packages/aim_database) - Database abstraction layer
- [aim_postgres](https://pub.dev/packages/aim_postgres) - PostgreSQL driver
- [aim_orm_codegen](https://pub.dev/packages/aim_orm_codegen) - Code generation for ORM

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
