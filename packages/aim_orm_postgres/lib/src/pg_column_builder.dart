import 'package:aim_orm_postgres/aim_orm_postgres.dart';

/// Creates a [SerialColumn] with the given [name].
///
/// This is a convenience function for creating auto-incrementing integer
/// columns in PostgreSQL table definitions.
///
/// ## Example
///
/// ```dart
/// final id = serial('id').primaryKey();
/// ```
SerialColumn serial(String name) => SerialColumn(name: name);

/// Creates a [UuidColumn] with the given [name].
///
/// This is a convenience function for creating UUID columns in PostgreSQL
/// table definitions.
///
/// ## Example
///
/// ```dart
/// final id = uuid('id').primaryKey();
/// final externalId = uuid('external_id').unique();
/// ```
UuidColumn uuid(String name) => UuidColumn(name: name);

/// Creates a [JsonbColumn] with the given [name].
///
/// This is a convenience function for creating JSONB columns in PostgreSQL
/// table definitions. The type parameter [T] specifies the Dart type that
/// the JSON data maps to.
///
/// ## Example
///
/// ```dart
/// final metadata = jsonb<Map<String, dynamic>>('metadata');
/// final tags = jsonb<List<String>>('tags').nullable();
/// ```
JsonbColumn<T> jsonb<T>(String name) => JsonbColumn<T>(name: name);
