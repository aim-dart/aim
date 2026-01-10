abstract class Database {
  Future<List<Map<String, dynamic>>> query(
    String sql, {
    Map<String, dynamic>? params,
    List<dynamic>? args,
  });

  Future<int> execute(String sql, [List<dynamic>? parameters]);

  Future<T> transaction<T>(Future<T> Function(Transaction tx) fn);

  Future<void> close();
}

abstract class Transaction {
  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? parameters,
  ]);

  Future<int> execute(String sql, [List<dynamic>? parameters]);
}
