abstract interface class InsertBuilder<T> {
  ValuesBuilder<T, R> values<R extends Record>(R values);
}

abstract interface class ValuesBuilder<T, R extends Record> {
  Future<void> execute();
}