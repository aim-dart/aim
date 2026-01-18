// SELECTクエリビルダー
abstract interface class SelectBuilder {
  // テーブルを指定
  // db.select().from(users)
  // ここで型Tが推論される
  FromBuilder<T> from<T>(T table);
}

// FROM句を持つビルダー
abstract interface class FromBuilder<T> {
  // クエリを実行して全件取得
  // db.select().from(users).execute()
  Future<List<Map<String, dynamic>>> execute();
}