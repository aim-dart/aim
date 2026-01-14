import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/src/pg_column.dart';

abstract class PgTable extends AimTable {
  SerialColumn serial() => const SerialColumn();
  UuidColumn uuid() => const UuidColumn();
  JsonbColumn<T> jsonb<T>() => JsonbColumn<T>();
}