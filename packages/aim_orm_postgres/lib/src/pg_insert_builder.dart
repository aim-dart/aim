import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/src/pg_table_registry.dart';
import 'package:aim_postgres/aim_postgres.dart';

class PgInsertBuilder<T> implements InsertBuilder<T> {
  final PostgresDatabase _db;
  final T _table;

  const PgInsertBuilder(this._db, this._table);

  @override
  ValuesBuilder<T, R> values<R extends Record>(R values) {
    return PgValuesBuilder<T, R>(_db, _table, values);
  }
}

class PgValuesBuilder<T, R extends Record> implements ValuesBuilder<T, R> {
  final PostgresDatabase _db;
  final T _table;
  final R _values;

  const PgValuesBuilder(this._db, this._table, this._values);

  @override
  Future<void> execute() {
    final tableName = tableRegistry[_table];
    return _db.query("INSERT INTO $tableName VALUES (:id, :name, :email)", params: {
      'id': 3,
      'name': 'test',
      'email': 'email',
    });
  }
}
