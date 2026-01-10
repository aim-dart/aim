import 'package:aim_orm_postgres/src/pg_connection.dart';
import 'package:test/test.dart';

void main() {
  group('MD5 Authentication', () {
    test('connects with MD5 auth', () async {
      // Docker Compose MD5環境に接続（ポート5434）
      final conn = await PostgresConnection.connect(
        'postgresql://test:test@localhost:5434/test_db',
      );

      // クエリを実行して認証成功を確認
      final result = await conn.sendSimpleQuery('SELECT 1');
      expect(result.rows.length, 1);

      await conn.close();
    });

    test('fails with wrong password', () async {
      expect(
            () => PostgresConnection.connect(
          'postgresql://test:wrong@localhost:5434/test_db',
        ),
        throwsA(isA<QueryException>()),
      );
    });
  });
}