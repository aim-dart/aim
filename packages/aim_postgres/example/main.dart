import 'package:aim_postgres/src/pg_database.dart';

void main() async {
  final db = await PostgresDatabase.connect(
    'postgresql://postgres:postgres@localhost:5432/playground',
  );
  print('Connected to Postgres database successfully.');

  // Simple query
  final resultSimpleQuery = await db.query('SELECT * from users;');
  print('Query result: $resultSimpleQuery');

  // Named parameter query
  final resultWithNamedParameter = await db.query(
    'SELECT * from users WHERE id > :id;',
    params: {'id': 2},
  );
  print('Query with named parameter result: $resultWithNamedParameter');

  // Positional parameter query
  final resultWithPositionalParameter = await db.query(
    'SELECT * from users WHERE id > \$1;',
    args: [2],
  );
  print('Query with positional parameter result: $resultWithPositionalParameter');

  // Transaction example
  print('\n--- Transaction Example ---');
  try {
    await db.transaction((tx) async {
      print('Transaction started (BEGIN)');

      // Insert a new user
      await tx.execute(
        'INSERT INTO users (name, email) VALUES (\$1, \$2)',
        args: ['Transaction User', 'tx@example.com'],
      );
      print('Inserted new user');

      // Query within transaction
      final users = await tx.query('SELECT * FROM users WHERE email = \$1', args: ['tx@example.com']);
      print('Queried user: $users');

      // Update within transaction
      await tx.execute(
        'UPDATE users SET name = \$1 WHERE email = \$2',
        args: ['Updated Transaction User', 'tx@example.com'],
      );
      print('Updated user');

      print('Transaction will commit (COMMIT)');
    });
    print('Transaction completed successfully!');
  } catch (e) {
    print('Transaction failed (ROLLBACK): $e');
  }

  // Transaction rollback example
  print('\n--- Transaction Rollback Example ---');
  try {
    await db.transaction((tx) async {
      print('Transaction started (BEGIN)');

      await tx.execute(
        'INSERT INTO users (name, email) VALUES (\$1, \$2)',
        args: ['Will Rollback', 'rollback@example.com'],
      );
      print('Inserted user that will be rolled back');

      // Simulate error
      throw Exception('Simulated error - transaction will rollback');
    });
  } catch (e) {
    print('Transaction rolled back: $e');
  }

  // Verify rollback worked
  final checkRollback = await db.query(
    'SELECT * FROM users WHERE email = \$1',
    args: ['rollback@example.com'],
  );
  print('Rollback verification (should be empty): $checkRollback');

  await db.close();
  print('\nConnection closed.');
}
