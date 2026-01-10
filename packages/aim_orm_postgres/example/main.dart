import 'package:aim_orm_postgres/src/pg_database.dart';

void main() async {
  final db = await PostgresDatabase.connect(
    'postgresql://postgres:postgres@localhost:5432/playground',
  );
  print('Connected to Postgres database successfully.');
  final resultSimpleQuery = await db.query('SELECT * from users;');
  print('Query result: $resultSimpleQuery');

  final resultWithNamedParameter = await db.query(
    'SELECT * from users WHERE id > :id;',
    params: {'id': 2},
  );
  print('Query with named parameter result: $resultWithNamedParameter');

  final resultWithPositionalParameter = await db.query(
    'SELECT * from users WHERE id > \$1;',
    args: [2],
  );
  print('Query with positional parameter result: $resultWithPositionalParameter');

  await db.close();
  print('Closing connection.');
}
