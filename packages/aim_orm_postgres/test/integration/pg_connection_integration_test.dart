import 'package:aim_orm_postgres/src/pg_connection.dart';
import 'package:test/test.dart';

void main() {
  late PostgresConnection conn;

  setUp(() async {
    // 各テストの前にテーブルをクリーンアップして初期データを投入
    await conn.sendSimpleQuery('TRUNCATE TABLE test_users RESTART IDENTITY');
    await conn.sendSimpleQuery('''
      INSERT INTO test_users (name, age, active) VALUES
        ('Alice', 30, true),
        ('Bob', 25, false),
        ('Charlie', NULL, true)
    ''');
  });

  setUpAll(() async {
    // Docker Composeでテスト用PostgreSQLが起動していることを前提
    // docker-compose -f test/integration/docker-compose.yml up -d
    conn = await PostgresConnection.connect(
      'postgresql://test:test@localhost:5433/test_db',
    );

    // テスト用テーブル作成
    await conn.sendSimpleQuery('''
      CREATE TABLE IF NOT EXISTS test_users (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL,
        age INT,
        active BOOLEAN DEFAULT true,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  });

  tearDownAll(() async {
    // テーブル削除
    await conn.sendSimpleQuery('DROP TABLE IF EXISTS test_users');
    await conn.close();
  });

  group('Simple Query Protocol', () {
    test('SELECT returns correct results', () async {
      final result =
          await conn.sendSimpleQuery('SELECT * FROM test_users ORDER BY id');
      final rows = result.toMaps();

      expect(rows.length, 3);
      expect(rows[0]['name'], 'Alice');
      expect(rows[0]['age'], '30');
      expect(rows[0]['active'], 't');
      expect(rows[1]['name'], 'Bob');
      expect(rows[1]['age'], '25');
      expect(rows[1]['active'], 'f');
      expect(rows[2]['name'], 'Charlie');
      expect(rows[2]['age'], null); // NULL値
      expect(rows[2]['active'], 't');
    });

    test('SELECT with columns metadata', () async {
      final result =
          await conn.sendSimpleQuery('SELECT id, name FROM test_users LIMIT 1');

      expect(result.columns.length, 2);
      expect(result.columns[0]['name'], 'id');
      expect(result.columns[1]['name'], 'name');
    });

    test('INSERT works correctly', () async {
      await conn.sendSimpleQuery(
        "INSERT INTO test_users (name, age) VALUES ('Dave', 40)",
      );

      final selectResult = await conn.sendSimpleQuery(
        "SELECT * FROM test_users WHERE name = 'Dave'",
      );
      final rows = selectResult.toMaps();

      expect(rows.length, 1);
      expect(rows[0]['name'], 'Dave');
      expect(rows[0]['age'], '40');
    });

    test('UPDATE works correctly', () async {
      await conn.sendSimpleQuery(
        "UPDATE test_users SET age = 99 WHERE name = 'Alice'",
      );

      final selectResult = await conn.sendSimpleQuery(
        "SELECT age FROM test_users WHERE name = 'Alice'",
      );
      expect(selectResult.toMaps()[0]['age'], '99');

      // 元に戻す
      await conn.sendSimpleQuery(
        "UPDATE test_users SET age = 30 WHERE name = 'Alice'",
      );
    });

    test('DELETE works correctly', () async {
      await conn.sendSimpleQuery(
        "INSERT INTO test_users (name, age) VALUES ('ToDelete', 1)",
      );

      await conn.sendSimpleQuery(
        "DELETE FROM test_users WHERE name = 'ToDelete'",
      );

      final selectResult = await conn.sendSimpleQuery(
        "SELECT * FROM test_users WHERE name = 'ToDelete'",
      );
      expect(selectResult.toMaps(), isEmpty);
    });

    test('Empty result set', () async {
      final result = await conn.sendSimpleQuery(
        "SELECT * FROM test_users WHERE name = 'NonExistent'",
      );
      expect(result.toMaps(), isEmpty);
    });
  });

  group('Extended Query Protocol', () {
    test('SELECT with single parameter', () async {
      final result = await conn.sendExtendedQuery(
        'SELECT * FROM test_users WHERE name = \$1',
        ['Alice'],
      );
      final rows = result.toMaps();

      expect(rows.length, 1);
      expect(rows[0]['name'], 'Alice');
      expect(rows[0]['age'], '30');
    });

    test('SELECT with multiple parameters', () async {
      final result = await conn.sendExtendedQuery(
        'SELECT * FROM test_users WHERE age > \$1 AND active = \$2',
        [25, true],
      );
      final rows = result.toMaps();

      expect(rows.length, 1);
      expect(rows[0]['name'], 'Alice');
    });

    test('INSERT with parameters', () async {
      await conn.sendExtendedQuery(
        'INSERT INTO test_users (name, age, active) VALUES (\$1, \$2, \$3)',
        ['Extended', 50, true],
      );

      final selectResult = await conn.sendExtendedQuery(
        'SELECT * FROM test_users WHERE name = \$1',
        ['Extended'],
      );
      final rows = selectResult.toMaps();

      expect(rows.length, 1);
      expect(rows[0]['name'], 'Extended');
      expect(rows[0]['age'], '50');
      expect(rows[0]['active'], 't');
    });

    test('handles NULL parameters', () async {
      await conn.sendExtendedQuery(
        'INSERT INTO test_users (name, age) VALUES (\$1, \$2)',
        ['NullAge', null],
      );

      final selectResult = await conn.sendExtendedQuery(
        'SELECT * FROM test_users WHERE name = \$1',
        ['NullAge'],
      );
      expect(selectResult.toMaps()[0]['age'], null);
    });

    test('handles different data types', () async {
      await conn.sendExtendedQuery(
        'INSERT INTO test_users (name, age, active) VALUES (\$1, \$2, \$3)',
        ['TypeTest', 35, false],
      );

      final result = await conn.sendExtendedQuery(
        'SELECT * FROM test_users WHERE name = \$1',
        ['TypeTest'],
      );
      final row = result.toMaps()[0];
      expect(row['name'], 'TypeTest');
      expect(row['age'], '35');
      expect(row['active'], 'f');
    });

    test('handles empty result with parameters', () async {
      final result = await conn.sendExtendedQuery(
        'SELECT * FROM test_users WHERE name = \$1',
        ['DoesNotExist'],
      );
      expect(result.toMaps(), isEmpty);
    });

    test('UPDATE with parameters', () async {
      await conn.sendExtendedQuery(
        'UPDATE test_users SET age = \$1 WHERE name = \$2',
        [88, 'Bob'],
      );

      final selectResult = await conn.sendExtendedQuery(
        'SELECT age FROM test_users WHERE name = \$1',
        ['Bob'],
      );
      expect(selectResult.toMaps()[0]['age'], '88');

      // 元に戻す
      await conn.sendExtendedQuery(
        'UPDATE test_users SET age = \$1 WHERE name = \$2',
        [25, 'Bob'],
      );
    });

    test('DELETE with parameters', () async {
      await conn.sendExtendedQuery(
        'INSERT INTO test_users (name, age) VALUES (\$1, \$2)',
        ['ToDeleteExt', 1],
      );

      await conn.sendExtendedQuery(
        'DELETE FROM test_users WHERE name = \$1',
        ['ToDeleteExt'],
      );

      final selectResult = await conn.sendExtendedQuery(
        'SELECT * FROM test_users WHERE name = \$1',
        ['ToDeleteExt'],
      );
      expect(selectResult.toMaps(), isEmpty);
    });
  });

  group('Error Handling', () {
    test('throws QueryException on syntax error (Simple Query)', () async {
      expect(
        () => conn.sendSimpleQuery('SELCT * FROM test_users'), // typo
        throwsA(isA<QueryException>()),
      );
    });

    test('throws QueryException on non-existent table (Simple Query)',
        () async {
      expect(
        () => conn.sendSimpleQuery('SELECT * FROM non_existent_table'),
        throwsA(isA<QueryException>()),
      );
    });

    test('throws QueryException on syntax error (Extended Query)', () async {
      expect(
        () => conn.sendExtendedQuery('SELCT * FROM test_users WHERE id = \$1', [1]),
        throwsA(isA<QueryException>()),
      );
    });

    test('throws QueryException on wrong parameter count', () async {
      // PostgreSQLは必要なパラメータ数と実際の数が合わないとエラーを返す
      expect(
        () => conn.sendExtendedQuery(
          'SELECT * FROM test_users WHERE id = \$1 AND name = \$2',
          [1], // 2つ必要なのに1つしか提供していない
        ),
        throwsA(isA<QueryException>()),
      );
    });
  });

  group('Column metadata', () {
    test('RowDescription contains correct column information', () async {
      final result = await conn.sendSimpleQuery(
        'SELECT id, name, age FROM test_users LIMIT 1',
      );

      expect(result.columns.length, 3);

      // カラム名の確認
      expect(result.columns[0]['name'], 'id');
      expect(result.columns[1]['name'], 'name');
      expect(result.columns[2]['name'], 'age');

      // 型OIDの確認（PostgreSQL type OIDs）
      expect(result.columns[0]['typeOid'], 23); // int4
      expect(result.columns[1]['typeOid'], 1043); // varchar
      expect(result.columns[2]['typeOid'], 23); // int4
    });
  });
}
