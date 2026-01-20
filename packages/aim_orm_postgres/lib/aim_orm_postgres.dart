/// PostgreSQL ORM implementation for Dart.
///
/// This library provides PostgreSQL-specific ORM features built on top of
/// [aim_orm]. It includes PostgreSQL-specific column types and table
/// definitions.
///
/// ## Features
///
/// - PostgreSQL-specific column types: SERIAL, UUID, JSONB
/// - Type-safe table definitions using Dart Record syntax
/// - Code generation for query builders
///
/// ## Usage
///
/// ```dart
/// import 'package:aim_orm_postgres/aim_orm_postgres.dart';
///
/// // Define PostgreSQL-specific columns
/// final id = serial('id').primaryKey();
/// final userId = uuid('user_id').unique();
/// final metadata = jsonb<Map<String, dynamic>>('metadata');
/// ```
///
/// For table definitions and code generation, use this with
/// [aim_orm_codegen](https://pub.dev/packages/aim_orm_codegen).
library;

export 'src/pg_table.dart';
export 'src/pg_column.dart';
export 'src/pg_column_builder.dart';
