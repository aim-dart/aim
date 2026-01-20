import 'package:aim_orm/src/query_builder/condition.dart';

abstract class Column<T, Self> {
  final String name;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool isUnique;
  final T? defaultValue;

  const Column({
    required this.name,
    this.isNullable = false,
    this.isPrimaryKey = false,
    this.isUnique = false,
    this.defaultValue,
  });

  Self copyWith({
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

  Condition eq(int value) => Condition(name, ConditionOperator.equal, value);

  Condition gt(int value) =>
      Condition(name, ConditionOperator.greaterThan, value);

  Condition lt(int value) => Condition(name, ConditionOperator.lessThan, value);

  Condition gte(int value) =>
      Condition(name, ConditionOperator.greaterThanOrEqual, value);

  Condition lte(int value) =>
      Condition(name, ConditionOperator.lessThanOrEqual, value);

  Condition inList(List<int> values) =>
      Condition(name, ConditionOperator.inList, values);

  Self indexed() => copyWith();

  Self references<R>(
    Column<T, R> Function() target, {
    OnDeleteAction? onDelete,
    OnUpdateAction? onUpdate,
  }) => copyWith();
}

enum OnDeleteAction { cascade, setNull, restrict, setDefault }

enum OnUpdateAction { cascade, setNull, restrict, setDefault }

class IntegerColumn extends Column<int, IntegerColumn> {
  const IntegerColumn({
    required super.name,
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  @override
  IntegerColumn copyWith({
    bool? isPrimaryKey,
    bool? isNullable,
    bool? isUnique,
    int? defaultValue,
  }) => IntegerColumn(
    name: name,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
    defaultValue: defaultValue ?? this.defaultValue,
  );

  @override
  String toSql() => 'INTEGER';
}

class VarcharColumn extends Column<String, VarcharColumn> {
  final int? length;

  const VarcharColumn({
    required super.name,
    this.length,
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
    name: name,
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
    required super.name,
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
    name: name,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
    defaultValue: defaultValue ?? this.defaultValue,
  );

  @override
  String toSql() => 'TEXT';
}

class TimestampColumn extends Column<DateTime, TimestampColumn> {
  final bool defaultNow;

  const TimestampColumn({
    required super.name,
    this.defaultNow = false,
    super.isPrimaryKey,
    super.isNullable,
    super.isUnique,
    super.defaultValue,
  });

  TimestampColumn withDefaultNow() => TimestampColumn(
    name: name,
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
  }) => TimestampColumn(
    name: name,
    defaultNow: defaultNow,
    isPrimaryKey: isPrimaryKey ?? this.isPrimaryKey,
    isNullable: isNullable ?? this.isNullable,
    isUnique: isUnique ?? this.isUnique,
    defaultValue: defaultValue ?? this.defaultValue,
  );

  @override
  String toSql() => 'TIMESTAMP';
}
