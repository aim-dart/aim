import 'dart:async';

/// Abstract base class for query objects that can be awaited directly.
///
/// This interface allows query builder methods to return objects that
/// implement [Future], enabling direct `await` syntax on queries.
///
/// ## Example
///
/// ```dart
/// // Direct await - no need to call .execute()
/// final users = await db.users.select().where(...);
///
/// // Also works with async patterns
/// db.users.select().then((users) => print(users));
/// ```
abstract class QueryFuture<T> implements Future<T> {
  /// Executes the query and returns the result.
  ///
  /// This method is called automatically when the query is awaited.
  Future<T> execute();
}

/// A mixin that implements [Future] interface by delegating to [execute].
///
/// This mixin provides the boilerplate implementation for making query
/// builders awaitable. It delegates all [Future] methods to the result
/// of [execute].
///
/// ## Usage
///
/// ```dart
/// class SelectQuery<T> extends Future<List<T>> with FutureMixin<List<T>> {
///   @override
///   Future<List<T>> execute() async {
///     // Execute the query and return results
///   }
/// }
/// ```
mixin FutureMixin<T> on Future<T> {
  /// Executes the query and returns the result.
  ///
  /// Subclasses must implement this to perform the actual query execution.
  Future<T> execute();

  @override
  Future<T> timeout(Duration timeLimit, {FutureOr<T> Function()? onTimeout}) {
    return execute().timeout(timeLimit, onTimeout: onTimeout);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    return execute().whenComplete(action);
  }

  @override
  Stream<T> asStream() {
    return execute().asStream();
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object error)? test}) {
    return execute().catchError(onError, test: test);
  }

  @override
  Future<R> then<R>(
      FutureOr<R> Function(T value) onValue, {
        Function? onError,
      }) {
    return execute().then(onValue, onError: onError);
  }
}
