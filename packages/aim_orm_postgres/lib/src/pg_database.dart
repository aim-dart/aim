import 'package:aim_orm_core/aim_orm_core.dart';
import 'package:aim_orm_postgres/src/pg_connection.dart';

/// PostgreSQL database implementation.
///
/// This class provides a high-level API for interacting with PostgreSQL
/// databases. It wraps a [PostgresConnection] and implements the [Database]
/// interface from aim_orm_core.
class PostgresDatabase extends Database {
  final PostgresConnection _connection;

  PostgresDatabase._(this._connection);

  /// Connects to a PostgreSQL database.
  ///
  /// The [connectionString] should be in the format:
  /// `postgresql://username:password@host:port/database?sslmode=mode&sslrootcert=/path/to/ca.crt`
  ///
  /// Supported SSL modes: disable, allow, prefer, require, verify-ca, verify-full
  ///
  /// Example:
  /// ```dart
  /// final db = await PostgresDatabase.connect(
  ///   'postgresql://user:pass@localhost:5432/mydb?sslmode=require',
  /// );
  /// ```
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
    // Error if both parameter types are specified
    if (params != null &&
        params.isNotEmpty &&
        args != null &&
        args.isNotEmpty) {
      throw ArgumentError(
        'Cannot specify both named parameters (params) and positional parameters (args)',
      );
    }

    // Convert named parameters to positional parameters if present
    if (params != null && params.isNotEmpty) {
      final (convertedSql, positionalParams) = _convertNamedParams(sql, params);
      final result = await _connection.sendExtendedQuery(
        convertedSql,
        positionalParams,
      );
      return result.toMaps();
    }

    // Use Extended Query Protocol if positional parameters are present
    if (args != null && args.isNotEmpty) {
      final result = await _connection.sendExtendedQuery(sql, args);
      return result.toMaps();
    }

    // Use Simple Query Protocol if no parameters
    final result = await _connection.sendSimpleQuery(sql);
    return result.toMaps();
  }

  /// Converts named parameters (:id) to positional parameters ($1).
  ///
  /// Returns a tuple containing the converted SQL string and the list of
  /// positional parameter values.
  (String, List<dynamic>) _convertNamedParams(
    String sql,
    Map<String, dynamic> params,
  ) {
    var convertedSql = sql;
    final positionalParams = <dynamic>[];
    var paramIndex = 1;

    // Convert parameters in order
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
