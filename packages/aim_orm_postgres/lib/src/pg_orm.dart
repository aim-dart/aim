import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';

class PgOrm {
  static Future<PgOrm> connect() async {
    await PostgresDatabase.connect('');
    return PgOrm();
  }

}

Future<PgOrm> aimDb() => PgOrm.connect();