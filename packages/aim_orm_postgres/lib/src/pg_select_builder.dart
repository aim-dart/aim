import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/src/pg_table_registry.dart';
import 'package:aim_postgres/aim_postgres.dart';

class PgSelectBuilder implements SelectBuilder {
  final PostgresDatabase db;

  const PgSelectBuilder(this.db);

  @override
  FromBuilder<T> from<T>(T table) {
    return PgFromBuilder<T>(db, table);
  }
}

class PgFromBuilder<T> implements FromBuilder<T> {
  final PostgresDatabase db;
  final T table;

  const PgFromBuilder(this.db, this.table);

  @override
  Future<List<Map<String, dynamic>>> execute() {
    final tableName = tableRegistry[table];
    final query = 'SELECT * FROM $tableName;';
    return db.query(query);
  }
}
