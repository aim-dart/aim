import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';

class PgOrm {
  static Future<PgOrm> connect() async {
    await PostgresDatabase.connect('');
    return PgOrm();
  }

  PgOrm select() {
    return this;
  }

  PgOrm from(PgTable table) {
    return this;
  }

  Future<String> execute() async {
    return 'Executed';
  }
}

Future<PgOrm> aimDb() => PgOrm.connect();