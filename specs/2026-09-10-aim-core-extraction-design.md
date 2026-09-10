# aim_core 切り出し設計

日付: 2026-09-10
状態: 設計承認済み、実装計画は未作成

## 背景と目的

Aim を workerd（Cloudflare Workers）上で `dart compile wasm` を使って動かしたい。現状の `aim_server` は `HttpServer` 起動と `HttpRequest` 変換で `dart:io` に依存しており、wasm ターゲットではコンパイルできない。

`dart:io` に依存しない部分を新パッケージ `aim_core` に移し、`aim_server` を `dart:io` アダプタに縮める。後続で `aim_edge`（workerd アダプタ）を `aim_core` の上に作る。

この spec はサブプロジェクト全体のうち「aim_core 切り出し」だけを扱う。関連する他のサブプロジェクトは末尾に記す。

## 前提

- ワークスペース全体の Dart SDK を 3.13.3 に上げる作業（サブプロジェクト 1）が先に完了していること。
- `aim_server` の公開 API（`Aim`、`Context`、`Request`、`Response`、`serve()`）は互換を保つ。既存ユーザーは import を変えずに動く。
- ミドルウェアパッケージは `aim_server_*` の名前を維持する（pub.dev 公開済みのためリネームしない）。

## 現状の依存分析

`dart:io` を import しているファイル:

| ファイル | 依存内容 |
|---|---|
| `aim_server/lib/src/server.dart` | `HttpServer` 起動、`HttpRequest` → `Request` 変換、`Response` → `HttpResponse` 書き出し、`AimHttpServer` |
| `aim_server/lib/src/request.dart` | `HttpRequest? raw` フィールドの型のみ |
| `aim_server_multipart/lib/src/multipart_form_data.dart` | `UploadedFile.saveTo()` の `File.writeAsBytes` |
| `aim_server_static/lib/src/*.dart` | `File` 読み込み（本質的な依存） |

`Context` / `Env` / `Response` / `Body` / `MessageMixin` / `Route` および cors / cookie / form / logger / sse / jwt / basic_auth / testing は既に純粋 Dart。

`Aim.handle(Request)` は既にソケット非依存の完全なパイプラインだが、`_handleRequest(HttpRequest)` にルーティングからエラー処理まで同じロジックが重複している。

`Request.raw` はフレームワーク内で `_handleRequest` が設定するだけで、読んでいるのは null チェックのテストのみ。ミドルウェアからの利用はない。

## 設計

### パッケージ構成

採用: `aim_core` にパイプライン全体を置き、`aim_server` は薄いアダプタにする。

```
aim_core     Aim<E>, Route, Context, Env, Request, Response, Body, MessageMixin
             dart:io を import しない。dart compile wasm が通る。
aim_server   export 'package:aim_core/aim_core.dart';
             extension AimServe on Aim { serve() }, AimHttpServer, HttpRequest/HttpResponse 変換
aim_edge     （後続）package:web の Request/Response と aim_core の相互変換、dartHandle の公開
```

同じ `Aim` インスタンスを dart:io でも edge でも使えるため、ミドルウェアは無変更で両方に対応する。

検討して不採用にした案:

- コアは Request/Response/Context だけにし、`Aim` をアダプタごとに持つ: ルーティングとミドルウェアチェーンが二重実装になる。
- アダプタが `Aim` を継承する（`AimServer extends Aim`）: ユーザーが `Aim()` と `AimServer()` を使い分ける必要があり互換が崩れる。

### aim_core の API

- `Aim<E extends Env>`: ルート登録（`get`/`post`/`put`/`delete`/`patch`/...）、`use()`、`onError()`、`notFound()`、`routes`、`middlewares`、`handle(Request)`。
- `handle(Request)` にリクエスト処理を一本化する。アダプタは `Request` を組み立てて `handle()` を呼び、返った `Response` を書き出すだけにする。`_handleRequest` 内の重複ロジックは削除。
- `Request.raw` の型を `HttpRequest?` から `Object?` に変更する。プラットフォーム固有の生オブジェクトを載せる汎用フィールドとし、アダプタ側で型付きアクセサを提供する。
  - `aim_server`: `extension on Request { HttpRequest? get httpRequest => raw as HttpRequest?; }`
  - `aim_edge`（後続）: `package:web` の `Request` を載せる。
- エラー処理: `onError` が未登録のときコアは `print` せず、`Response.internalServerError` を返すだけにする。現在 `_handleRequest` だけが行っている `print` によるスタックトレース出力は、`aim_server` 側の既定 error handler（`serve()` が `onError` 未登録時に設定する）で従来どおり行う。コアが `print` に依存しないことで workerd 側のログ出力手段を自由に選べる。

### aim_server アダプタ

- `lib/aim_server.dart` は `aim_core` を re-export する。既存の import は変更不要。
- `extension AimServe<E extends Env> on Aim<E>` に `Future<AimHttpServer> serve({required Object host, required int port, SecurityContext? securityContext, int? backlog, bool shared = false})` を置く。シグネチャは現行と同じ。
- `HttpRequest` → `Request` 変換: ヘッダの `join(',')` 結合、`host` ヘッダからの絶対 URI 組み立て、`raw` への `HttpRequest` 格納。
- `Response` → `HttpResponse` 書き出し: `Set-Cookie` の改行分割による複数ヘッダ化、`text/event-stream` のときの `bufferOutput = false`、チャンクごとの `flush()`。
- `AimHttpServer`（`host`、`port`、`close({force})`）はそのまま。

### ミドルウェアと周辺パッケージ

依存先を `aim_server` から `aim_core` に変更するだけで、コード変更なし:

- `aim_server_cors`、`aim_server_cookie`、`aim_server_form`、`aim_server_logger`、`aim_server_sse`、`aim_server_jwt`、`aim_server_basic_auth`
- `aim_server_testing`（`TestClient` は `Aim.handle()` を呼ぶだけ。edge アダプタのテストにもそのまま使う）

`aim_server_multipart`:

- パーサ本体は純粋。`dart:io` 依存は `UploadedFile.saveTo(path)` の 1 箇所。
- ライブラリを 2 つに分ける。`aim_server_multipart.dart`（純粋、`aim_core` 依存）と `aim_server_multipart_io.dart`（`saveTo` を extension として提供、`dart:io` 依存）。
- 既存ユーザーは `saveTo` を使う場合に `_io` ライブラリの import を 1 行足す。
- 条件付き import は使わない。wasm ビルド時に `_io` を import していれば明示的にコンパイルエラーになるほうが分かりやすい。

`aim_server_static`:

- `File` 読み込みが本質なので `aim_server` 依存のまま。edge では Cloudflare の静的アセット機能を使うのが筋であり、このラウンドでは対象外。

### バージョンとリリース

- 全パッケージ lockstep のため、`aim_core` は既存と同じ `0.1.1` で作成し、次のリリースで全体を `0.2.0` に上げる。
- `tools/release/bin/publish.dart` の topological sort は `aim_` 接頭辞の依存を自動で辿るので変更不要。`bump.dart` も `packages/` 配下を走査するので変更不要。
- `aim_server` の CHANGELOG に「内部実装を `aim_core` に分離。公開 API は互換」と記載する。`aim_server_multipart` の CHANGELOG に `saveTo` の import 変更を記載する。
- ルート `README.md` のパッケージ表に `aim_core` を追加する。

## テスト戦略

`aim_core/test/`:

- 既存の `aim_server/test/unit/` 11 ファイル（body_handling、context、error_handling、handle、headers、http_methods、middleware、request、response、routing、status_codes）を移動し、import を `aim_core` に変更する。いずれも `dart:io` を使っていない。
- 追加: `onError` 未登録時に `handle()` が 500 を返し、標準出力に何も書かないこと。
- 追加: `dart:io` 混入の機械的検出。`aim_core/test/wasm_smoke/main.dart` に `aim_core` を import して `Aim` を組み立てるだけのエントリを置き、テストから `Process.run('dart', ['compile', 'wasm', ...])` を実行して exit code 0 を確認する。

`aim_server/test/`:

- `integration/sse_streaming_test.dart` は実サーバーを立てるので残す。
- 追加: アダプタ固有の変換テスト。`port: 0` で実サーバーを起動し `HttpClient` で叩く。
  - 複数値ヘッダの結合と絶対 URI の組み立て
  - `Set-Cookie` が複数ヘッダとして送出されること
  - `text/event-stream` レスポンスでバッファリングが無効になること
  - `onError` 未登録時に既定ハンドラがスタックトレースを出力すること

ミドルウェア各パッケージ:

- 既存テストは依存付け替えのみで無変更。
- `aim_server_multipart` は `saveTo` を使うテストに `_io` ライブラリの import を追加。

CI（`.github/workflows/test.yml`）:

- `aim_core` の `dart test` ステップを追加する。wasm smoke テストもここで走る。

## 移行手順

1 PR に収める。大きくなれば手順 2〜3 と 4〜6 の 2 PR に分ける。

1. `packages/aim_core` を作成。`aim_server/lib/src/` の `context.dart`、`env.dart`、`request.dart`、`response.dart`、`body.dart`、`message.dart` を移動。`server.dart` から `Aim` と `Route` を切り出して移動。
2. `Aim.handle()` に処理を一本化。`Request.raw` を `Object?` に変更。コアから `print` を除去。
3. `aim_server` を re-export、`serve()` extension、`AimHttpServer`、変換ロジック、既定 error handler に書き換え。
4. ミドルウェア 7 パッケージと `aim_server_testing` の pubspec を `aim_core` 依存に変更。
5. `aim_server_multipart` のライブラリ分割。
6. ルート `pubspec.yaml` の workspace に `packages/aim_core` を追加。CI に `aim_core` を追加。README のパッケージ表と CHANGELOG を更新。

## スコープ外（別 spec）

- サブプロジェクト 1: SDK 3.13.3 化（`mise.toml`、全 pubspec の制約、analyzer / build_runner 互換確認、golden 再実行）。本 spec の前提。
- サブプロジェクト 3: `aim_edge` パッケージ。`package:web` の `Request`/`Response` と `aim_core` の相互変換、`@JS` セッターによる `dartHandle` の公開、workerd の `env` / `ctx` を生の `JSObject` として `Context` から取れるようにする、JS グルー（`index.mjs`）、`examples/edge-sample` で `wrangler dev` が通るまで。
- サブプロジェクト 4: `aim_cli` 拡張。`pubspec.yaml` の `aim:` 設定（`target: edge` を候補）を見て `aim build` が `dart compile wasm` と `CompiledApp` export パッチと JS グルー配置を行い、`aim dev` が `wrangler dev` を起動する。`aim create` の edge テンプレート。
