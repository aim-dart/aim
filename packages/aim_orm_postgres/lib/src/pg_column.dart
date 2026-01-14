import 'package:aim_orm/aim_orm.dart';

class SerialColumn extends Column<String, SerialColumn> {
  const SerialColumn({
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
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
  );

  @override
  String toSql() => 'SERIAL';
}

class JsonbColumn<T> extends Column<T, JsonbColumn<T>> {
  const JsonbColumn({
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
        isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
        isNullable: isNullable ?? this.isNullable,
        isUnique: isUnique ?? this.isUnique,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  @override
  String toSql() => 'JSONB';
}

class UuidColumn extends Column<String, UuidColumn> {
  const UuidColumn({
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
        isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
        isNullable: isNullable ?? this.isNullable,
        isUnique: isUnique ?? this.isUnique,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  @override
  String toSql() => 'UUID';
}