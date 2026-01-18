import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/src/pg_column.dart';
import 'package:aim_orm_postgres/src/pg_table_registry.dart';

class PgTable extends Table{
  const PgTable(super.name);
}


T pgTable<T extends Record>(String name, T columns) {
  tableRegistry[columns] = name;
  return columns;
}