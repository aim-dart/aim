import 'package:aim_orm/aim_orm.dart';

/// Annotation for marking a class as a PostgreSQL database table.
///
/// This is a PostgreSQL-specific extension of [Table] that should be used
/// when defining tables for PostgreSQL databases.
///
/// ## Example
///
/// ```dart
/// @PgTable('users')
/// class UsersTable {
///   Column<int> get id => serial('id').primaryKey();
///   Column<String> get name => varchar('name', length: 100);
///   Column<String> get email => varchar('email', length: 255).unique();
///   Column<DateTime> get createdAt => timestamp('created_at').withDefaultNow();
/// }
/// ```
///
/// Use with [aim_orm_codegen](https://pub.dev/packages/aim_orm_codegen) to
/// generate type-safe query builders.
class PgTable extends Table {
  /// Creates a new [PgTable] annotation with the given table [name].
  const PgTable(super.name);
}
