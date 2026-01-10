import 'package:aim_orm_core/aim_orm_core.dart';
import 'package:aim_orm_postgres/src/pg_connection.dart';

class PostgresDatabase extends Database {
  final PostgresConnection _connection;

  PostgresDatabase._(this._connection);

  static Future<PostgresDatabase> connect(String connectionString) async {
    final connection = await PostgresConnection.connect(connectionString);
    return PostgresDatabase._(connection);
  }

  @override
  Future<void> close() {
    return _connection.close();
  }

  @override
  Future<int> execute(String sql, [List<dynamic>? parameters]) {
    // TODO: implement execute
    throw UnimplementedError();
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? params,
    List<dynamic>? args,
  }) async {
    // 両方指定された場合はエラー
    if (params != null &&
        params.isNotEmpty &&
        args != null &&
        args.isNotEmpty) {
      throw ArgumentError(
        'Cannot specify both named parameters (params) and positional parameters (args)',
      );
    }

    // 名前付きパラメータがある場合は位置パラメータに変換
    if (params != null && params.isNotEmpty) {
      final (convertedSql, positionalParams) = _convertNamedParams(sql, params);
      final result = await _connection.sendExtendedQuery(
        convertedSql,
        positionalParams,
      );
      return result.toMaps();
    }

    // 位置パラメータがある場合はExtended Queryを使用
    if (args != null && args.isNotEmpty) {
      final result = await _connection.sendExtendedQuery(sql, args);
      return result.toMaps();
    }

    // パラメータなしの場合はSimple Queryを使用
    final result = await _connection.sendSimpleQuery(sql);
    return result.toMaps();
  }

  /// 名前付きパラメータ (:id) を位置パラメータ ($1) に変換
  (String, List<dynamic>) _convertNamedParams(
    String sql,
    Map<String, dynamic> params,
  ) {
    var convertedSql = sql;
    final positionalParams = <dynamic>[];
    var paramIndex = 1;

    // パラメータを順番に変換
    for (final entry in params.entries) {
      final placeholder = ':${entry.key}';
      if (convertedSql.contains(placeholder)) {
        convertedSql = convertedSql.replaceAll(placeholder, '\$$paramIndex');
        positionalParams.add(entry.value);
        paramIndex++;
      }
    }

    return (convertedSql, positionalParams);
  }

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction tx) fn) {
    // TODO: implement transaction
    throw UnimplementedError();
  }
}
