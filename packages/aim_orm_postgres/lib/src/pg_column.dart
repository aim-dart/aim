import 'package:aim_orm/aim_orm.dart';

/// A column that stores auto-incrementing integer values.
///
/// Maps to SERIAL in PostgreSQL, which is an auto-incrementing 4-byte integer.
/// SERIAL columns automatically generate unique values and are typically used
/// for primary keys.
///
/// ## Example
///
/// ```dart
/// final id = serial('id').primaryKey();
/// ```
///
/// Note: SERIAL columns should not have a default value set manually as
/// PostgreSQL handles the auto-increment automatically.
class SerialColumn extends Column<String, SerialColumn> {
  /// Creates a new serial column with the given [name].
  const SerialColumn({
    required super.name,
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
  }) : super(defaultValue: null);

  @override
  SerialColumn copyWith({
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    String? defaultValue,
  }) => SerialColumn(
    name: name,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
  );

  @override
  String toSql() => 'SERIAL';
}

/// A column that stores JSON binary data.
///
/// Maps to JSONB in PostgreSQL, which stores JSON data in a decomposed binary
/// format. JSONB is more efficient for querying and indexing compared to
/// plain JSON.
///
/// The type parameter [T] specifies the Dart type that the JSON data maps to,
/// typically `Map<String, dynamic>` or `List<dynamic>`.
///
/// ## Example
///
/// ```dart
/// final metadata = jsonb<Map<String, dynamic>>('metadata');
/// final tags = jsonb<List<String>>('tags').nullable();
/// ```
class JsonbColumn<T> extends Column<T, JsonbColumn<T>> {
  /// Creates a new JSONB column with the given [name].
  const JsonbColumn({
    required super.name,
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  @override
  JsonbColumn<T> copyWith({
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    T? defaultValue,
  }) =>
      JsonbColumn<T>(
        name: name,
        isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
        isNullable: isNullable ?? this.isNullable,
        isUnique: isUnique ?? this.isUnique,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  @override
  String toSql() => 'JSONB';
}

/// A column that stores universally unique identifiers (UUIDs).
///
/// Maps to UUID in PostgreSQL. UUIDs are 128-bit identifiers that are
/// guaranteed to be unique across space and time.
///
/// ## Example
///
/// ```dart
/// final id = uuid('id').primaryKey();
/// final externalId = uuid('external_id').unique();
/// final correlationId = uuid('correlation_id').nullable();
/// ```
///
/// Note: You need to generate UUID values in your application code or use
/// PostgreSQL's `gen_random_uuid()` function.
class UuidColumn extends Column<String, UuidColumn> {
  /// Creates a new UUID column with the given [name].
  const UuidColumn({
    required super.name,
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  @override
  UuidColumn copyWith({
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    String? defaultValue,
  }) =>
      UuidColumn(
        name: name,
        isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
        isNullable: isNullable ?? this.isNullable,
        isUnique: isUnique ?? this.isUnique,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  @override
  String toSql() => 'UUID';
}
