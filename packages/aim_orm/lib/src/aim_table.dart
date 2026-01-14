import 'package:aim_orm/src/column.dart';

abstract class AimTable {
  String get tableName;

  IntegerColumn integer() => const IntegerColumn();
  VarcharColumn varchar(int length) => VarcharColumn(length: length);
  TextColumn text() => const TextColumn();
  TimestampColumn timestamp() => const TimestampColumn();

  List<Column> get columns;
}