import 'dart:async';

abstract class QueryFuture<T> implements Future<T> {
  Future<T> execute();
}

mixin FutureMixin<T> on Future<T> {
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
