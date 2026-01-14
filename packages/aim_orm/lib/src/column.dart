abstract class Column<T, Self> {
  final String name;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isUnique;
  final T? defaultValue;

  const Column(
    this.name, {
    this.isNullable = false,
    this.isPrimaryKey = false,
    this.isUnique = false,
    this.defaultValue,
  });

  Self copyWith({
    String? name,
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    T? defaultValue,
  });

  String toSql();

  Self primaryKey() => copyWith(isPrimaryKey: true);

  Self unique() => copyWith(isUnique: true);

  Self nullable() => copyWith(isNullable: true);

  Self withDefault(T value) => copyWith(defaultValue: value);
}

class IntegerColumn extends Column<int, IntegerColumn> {
  const IntegerColumn(
    super.name, {
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  @override
  IntegerColumn copyWith({
    String? name,
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    int? defaultValue,
  }) => IntegerColumn(
    name ?? this.name,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
    defaultValue: defaultValue ?? this.defaultValue,
  );

  @override
  String toSql() => 'INTEGER';
}

class VarcharColumn extends Column<String, VarcharColumn> {
  final int length;

  const VarcharColumn({
    required this.length,
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  @override
  VarcharColumn copyWith({
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    String? defaultValue,
    int? length,
  }) => VarcharColumn(
    length: length ?? this.length,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
    defaultValue: defaultValue ?? this.defaultValue,
  );

  @override
  String toSql() => 'VARCHAR($length)';
}

class TextColumn extends Column<String, TextColumn> {
  const TextColumn({
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  @override
  TextColumn copyWith({
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    String? defaultValue,
  }) => TextColumn(
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
    defaultValue: defaultValue ?? this.defaultValue,
  );

  @override
  String toSql() => 'TEXT';
}

class TimestampColumn extends Column<DateTime, TimestampColumn>  {
  final bool defaultNow;

  const TimestampColumn({
    this.defaultNow = false,
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  TimestampColumn withDefaultNow() => TimestampColumn(
    defaultNow: true,
    isPrimaryKey: isPrimaryKey,
    isNullable: isNullable,
    isUnique: isUnique,
  );

  @override
  TimestampColumn copyWith({
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    DateTime? defaultValue,
  }) =>
      TimestampColumn(
        defaultNow: defaultNow,
        isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
        isNullable: isNullable ?? this.isNullable,
        isUnique: isUnique ?? this.isUnique,
        defaultValue: defaultValue ?? this.defaultValue,
      );

  @override
  String toSql() => 'TIMESTAMP';
}