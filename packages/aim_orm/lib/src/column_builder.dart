import 'package:aim_orm/aim_orm.dart';

/// Creates an [IntegerColumn] with the given [name].
///
/// This is a convenience function for creating integer columns in table
/// definitions.
///
/// ## Example
///
/// ```dart
/// final id = integer('id').primaryKey();
/// final age = integer('age').nullable();
/// final count = integer('count').withDefault(0);
/// ```
IntegerColumn integer(String name) {
  return IntegerColumn(name: name);
}

/// Creates a [VarcharColumn] with the given [name] and optional [length].
///
/// This is a convenience function for creating variable-length character
/// string columns in table definitions.
///
/// ## Example
///
/// ```dart
/// final name = varchar('name', length: 100);
/// final email = varchar('email', length: 255).unique();
/// final code = varchar('code', length: 10).nullable();
/// ```
VarcharColumn varchar(String name, {int? length}) {
  return VarcharColumn(name: name, length: length);
}

/// Creates a [TextColumn] with the given [name].
///
/// This is a convenience function for creating unlimited-length text columns
/// in table definitions.
///
/// ## Example
///
/// ```dart
/// final description = text('description');
/// final content = text('content').nullable();
/// ```
TextColumn text(String name) {
  return TextColumn(name: name);
}

/// Creates a [TimestampColumn] with the given [name].
///
/// This is a convenience function for creating date/time columns in table
/// definitions.
///
/// ## Example
///
/// ```dart
/// final createdAt = timestamp('created_at').withDefaultNow();
/// final updatedAt = timestamp('updated_at').nullable();
/// ```
TimestampColumn timestamp(String name) {
  return TimestampColumn(name: name);
}
