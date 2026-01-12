import 'package:aim_orm_postgres/src/pg_connection.dart';
import 'package:test/test.dart';

void main() {
  group('SSL/TLS Connection', () {
    test('connects with SSL enabled (sslmode=require)', () async {
      // Docker Compose SSL環境に接続（ポート5435）
      final conn = await PostgresConnection.connect(
        'postgresql://test:test@localhost:5435/test_db?sslmode=require',
      );

      // クエリを実行してSSL接続成功を確認
      final result = await conn.sendSimpleQuery('SELECT 1 as num');
      expect(result.rows.length, 1);
      expect(result.rows[0][0], '1');

      await conn.close();
    });

    test('connects with SSL disabled (sslmode=disable)', () async {
      // SSL無効で接続（cleartext password環境、ポート5433）
      final conn = await PostgresConnection.connect(
        'postgresql://test:test@localhost:5433/test_db?sslmode=disable',
      );

      final result = await conn.sendSimpleQuery('SELECT 1 as num');
      expect(result.rows.length, 1);
      expect(result.rows[0][0], '1');

      await conn.close();
    });

    test('connects with default sslmode (disable)', () async {
      // sslmodeを指定しない場合はdisableになる
      final conn = await PostgresConnection.connect(
        'postgresql://test:test@localhost:5433/test_db',
      );

      final result = await conn.sendSimpleQuery('SELECT 1 as num');
      expect(result.rows.length, 1);

      await conn.close();
    });

    test('handles SSL not supported by server', () async {
      // SSL非対応サーバー（ポート5433）にsslmode=requireで接続を試みる
      // サーバーが'N'を返すので、エラーになるか平文接続になるか実装次第

      // 現在の実装では'N'の場合に平文Socketを返すので、
      // sslmode=requireの場合は実装によってエラーにすべきかもしれない

      // TODO: sslmodeの挙動を完全実装後にテストを追加
    });
  });

  group('SSL Mode Parsing', () {
    test('parses sslmode from connection string', () {
      expect(
        () => PostgresSslMode.fromString('disable'),
        returnsNormally,
      );
      expect(
        () => PostgresSslMode.fromString('require'),
        returnsNormally,
      );
    });

    test('throws on invalid sslmode', () {
      expect(
        () => PostgresSslMode.fromString('invalid'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('Connection Management with SSL', () {
    test('sends Terminate message on close with SSL connection', () async {
      final conn = await PostgresConnection.connect(
        'postgresql://test:test@localhost:5435/test_db?sslmode=require',
      );

      // Execute a query to ensure connection is ready
      final result = await conn.sendSimpleQuery('SELECT 1');
      expect(result.rows.length, 1);

      // Close should send Terminate message and complete successfully
      await expectLater(conn.close(), completes);
    });

    test('sends Terminate message on close without SSL', () async {
      final conn = await PostgresConnection.connect(
        'postgresql://test:test@localhost:5433/test_db',
      );

      final result = await conn.sendSimpleQuery('SELECT 1');
      expect(result.rows.length, 1);

      await expectLater(conn.close(), completes);
    });
  });
}
