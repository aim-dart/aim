/// A type-safe ORM abstraction layer for Dart.
///
/// This library provides the core abstractions for building type-safe ORMs:
///
/// - [Column] types for defining table columns
/// - [Condition] operators for building WHERE clauses
/// - [QueryFuture] for async query execution
///
/// ## Usage
///
/// ```dart
/// import 'package:aim_orm/aim_orm.dart';
///
/// // Define columns
/// final id = integer('id').primaryKey();
/// final name = varchar('name', length: 100);
/// final email = varchar('email', length: 255).unique();
/// ```
///
/// For a complete ORM solution, use this with a database-specific implementation
/// like [aim_orm_postgres](https://pub.dev/packages/aim_orm_postgres).
library;

export 'src/table.dart';
export 'src/column.dart';
export 'src/column_builder.dart';
export 'src/query_builder/condition.dart';
export 'src/query_builder/query.dart';
