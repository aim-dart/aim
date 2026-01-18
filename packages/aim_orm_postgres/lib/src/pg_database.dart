import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/src/pg_insert_builder.dart';
import 'package:aim_orm_postgres/src/pg_select_builder.dart';
import 'package:aim_postgres/aim_postgres.dart';

extension PostgresQueryBuilder on PostgresDatabase {
  SelectBuilder select() {
    return PgSelectBuilder(this);
  }

  InsertBuilder<T> insert<T>(T table) {
    return PgInsertBuilder<T>(this, table);
  }
}