# aim_orm_postgres テスト

このパッケージには、ユニットテストと統合テストの両方が含まれています。

## テスト構成

### ユニットテスト (`test/unit/`)

PostgreSQLサーバーを必要としない、低レベルのロジックテスト：

- `pg_connection_test.dart`: バイト変換、メッセージタイプ判定、QueryResult処理
- `pg_database_test.dart`: パラメータ変換ロジック（プレースホルダー）

### 統合テスト (`test/integration/`)

実際のPostgreSQLサーバーを使用した統合テスト：

- `pg_connection_integration_test.dart`: Simple QueryとExtended Queryプロトコル
- `pg_database_integration_test.dart`: 名前付き/位置パラメータ、CRUD操作

## テスト実行方法

### すべてのテストを実行（推奨）

統合テスト実行スクリプトを使用：

```bash
cd packages/aim_orm_postgres
./test/integration/run_tests.sh
```

このスクリプトは以下を自動で行います：
1. PostgreSQLコンテナを起動
2. ユニットテストを実行
3. 統合テストを実行
4. PostgreSQLコンテナを停止・削除

### ユニットテストのみ実行

```bash
cd packages/aim_orm_postgres
dart test test/unit/
```

PostgreSQLサーバーは不要で、高速に実行できます。

### 統合テストのみ実行

まずPostgreSQLコンテナを起動：

```bash
cd packages/aim_orm_postgres
docker-compose -f test/integration/docker-compose.yml up -d
```

PostgreSQLが起動するまで待機（3〜5秒）してから、テストを実行：

```bash
dart test test/integration/
```

テスト終了後、コンテナを停止：

```bash
docker-compose -f test/integration/docker-compose.yml down
```

### 特定のテストファイルを実行

```bash
# ユニットテスト
dart test test/unit/pg_connection_test.dart

# 統合テスト（PostgreSQLコンテナが起動している必要があります）
dart test test/integration/pg_connection_integration_test.dart
```

### 特定のテストケースを実行

```bash
dart test --name "SELECT with parameters"
```

## 前提条件

### ユニットテスト
- Dart SDK 3.10.0以上

### 統合テスト
- Dart SDK 3.10.0以上
- Docker & Docker Compose

## テストデータベース情報

統合テストでは以下の設定でPostgreSQLに接続します：

- **ホスト**: localhost
- **ポート**: 5433（ホストの5432と競合しないように）
- **データベース**: test_db
- **ユーザー**: test
- **パスワード**: test

## CI/CD

GitHub Actionsでは、以下のワークフローでテストを実行：

```yaml
- name: Start PostgreSQL
  run: docker-compose -f packages/aim_orm_postgres/test/integration/docker-compose.yml up -d

- name: Wait for PostgreSQL
  run: |
    timeout 30 bash -c 'until docker exec aim_orm_postgres_test pg_isready -U test; do sleep 1; done'

- name: Run tests
  run: |
    cd packages/aim_orm_postgres
    dart test

- name: Stop PostgreSQL
  run: docker-compose -f packages/aim_orm_postgres/test/integration/docker-compose.yml down
```

## トラブルシューティング

### ポート5433が既に使用されている

`docker-compose.yml`の`ports`セクションを編集して、別のポートを使用：

```yaml
ports:
  - "5434:5432"  # 5434に変更
```

テストコード内の接続文字列も更新：

```dart
'postgresql://test:test@localhost:5434/test_db'
```

### PostgreSQLコンテナが起動しない

ログを確認：

```bash
docker logs aim_orm_postgres_test
```

コンテナを強制削除して再起動：

```bash
docker rm -f aim_orm_postgres_test
docker-compose -f test/integration/docker-compose.yml up -d
```

### テストがタイムアウトする

PostgreSQLが完全に起動するまで待機時間を増やす：

```bash
sleep 5  # 起動待機時間を増やす
```

## テスト戦略の参考

このテスト戦略は、Dart `postgres`パッケージの実装を参考にしています：

- [isoos/postgresql-dart](https://github.com/isoos/postgresql-dart)
