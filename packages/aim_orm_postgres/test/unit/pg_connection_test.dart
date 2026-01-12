import 'package:aim_orm_postgres/src/pg_connection.dart';
import 'package:test/test.dart';

void main() {
  // Note: Low-level byte conversion utilities (_int32Bytes, _bytesToInt32, etc.)
  // are private functions and tested indirectly through integration tests.

  group('PostgresMessageType', () {
    test('fromCode returns correct type for known codes', () {
      expect(
        PostgresMessageType.fromCode('R'),
        PostgresMessageType.authentication,
      );
      expect(PostgresMessageType.fromCode('S'), PostgresMessageType.parameterStatus);
      expect(PostgresMessageType.fromCode('K'), PostgresMessageType.backendKeyData);
      expect(PostgresMessageType.fromCode('Z'), PostgresMessageType.readyForQuery);
      expect(PostgresMessageType.fromCode('E'), PostgresMessageType.errorResponse);
      expect(PostgresMessageType.fromCode('T'), PostgresMessageType.rowDescription);
      expect(PostgresMessageType.fromCode('D'), PostgresMessageType.dataRow);
      expect(PostgresMessageType.fromCode('C'), PostgresMessageType.commandComplete);
      expect(PostgresMessageType.fromCode('1'), PostgresMessageType.parseComplete);
      expect(PostgresMessageType.fromCode('2'), PostgresMessageType.bindComplete);
      expect(PostgresMessageType.fromCode('n'), PostgresMessageType.noData);
    });

    test('fromCode returns unknown for unrecognized codes', () {
      expect(PostgresMessageType.fromCode('X'), PostgresMessageType.unknown);
      expect(PostgresMessageType.fromCode('?'), PostgresMessageType.unknown);
      expect(PostgresMessageType.fromCode('!'), PostgresMessageType.unknown);
    });

    test('code property returns correct value', () {
      expect(PostgresMessageType.authentication.code, 'R');
      expect(PostgresMessageType.readyForQuery.code, 'Z');
      expect(PostgresMessageType.dataRow.code, 'D');
    });
  });

  group('PostgresAuthenticationType', () {
    test('fromCode returns correct type for known codes', () {
      expect(PostgresAuthenticationType.fromCode(0), PostgresAuthenticationType.ok);
      expect(
        PostgresAuthenticationType.fromCode(3),
        PostgresAuthenticationType.cleartextPassword,
      );
      expect(
        PostgresAuthenticationType.fromCode(5),
        PostgresAuthenticationType.md5Password,
      );
      expect(PostgresAuthenticationType.fromCode(10), PostgresAuthenticationType.sasl);
    });

    test('fromCode returns unknown for unrecognized codes', () {
      expect(PostgresAuthenticationType.fromCode(-1), PostgresAuthenticationType.unknown);
      expect(PostgresAuthenticationType.fromCode(99), PostgresAuthenticationType.unknown);
    });

    test('code property returns correct value', () {
      expect(PostgresAuthenticationType.ok.code, 0);
      expect(PostgresAuthenticationType.cleartextPassword.code, 3);
      expect(PostgresAuthenticationType.md5Password.code, 5);
      expect(PostgresAuthenticationType.sasl.code, 10);
    });
  });

  group('QueryResult', () {
    test('toMaps combines columns and rows correctly', () {
      final result = QueryResult(
        columns: [
          {'name': 'id'},
          {'name': 'name'},
        ],
        rows: [
          ['1', 'Alice'],
          ['2', 'Bob'],
        ],
      );

      final maps = result.toMaps();
      expect(maps.length, 2);
      expect(maps[0], {'id': '1', 'name': 'Alice'});
      expect(maps[1], {'id': '2', 'name': 'Bob'});
    });

    test('toMaps handles empty results', () {
      final result = QueryResult(columns: [], rows: []);
      final maps = result.toMaps();
      expect(maps, isEmpty);
    });

    test('toMaps handles null values', () {
      final result = QueryResult(
        columns: [
          {'name': 'id'},
          {'name': 'value'},
        ],
        rows: [
          ['1', null],
          ['2', 'test'],
        ],
      );

      final maps = result.toMaps();
      expect(maps[0], {'id': '1', 'value': null});
      expect(maps[1], {'id': '2', 'value': 'test'});
    });
  });

  group('QueryException', () {
    test('toString returns formatted message', () {
      final exception = QueryException('Syntax error');
      expect(exception.toString(), 'QueryException: Syntax error');
    });

    test('can be caught as Exception', () {
      expect(() => throw QueryException('Test'), throwsA(isA<Exception>()));
    });
  });

  // Note: Parameter encoding (_encodeParameter) is tested in integration tests
}
