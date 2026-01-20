/// Annotation for marking a class as a database table.
///
/// Use this annotation to define table mappings for code generation.
///
/// ## Example
///
/// ```dart
/// @Table('users')
/// class UsersTable extends PgTable {
///   Column<int> get id => integer('id').primaryKey();
///   Column<String> get name => varchar('name', length: 100);
/// }
/// ```
class Table {
  /// The name of the database table.
  final String name;

  /// Creates a new [Table] annotation with the given [name].
  const Table(this.name);
}
