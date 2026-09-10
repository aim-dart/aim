# aim_core 切り出し 実装計画

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** `aim_server` から `dart:io` 非依存のリクエスト処理パイプラインを新パッケージ `aim_core` に切り出し、`aim_server` を `dart:io` アダプタに縮める。公開 API は互換を保つ。

**Architecture:** `aim_core` に `Aim<E>` / `Route` / `Context` / `Request` / `Response` / `Body` を置き、`Aim.handle(Request)` を唯一のリクエスト処理経路にする。`aim_server` は `aim_core` を re-export し、`serve()` を extension として提供、`HttpRequest` ⇄ `Request`/`Response` の変換だけを担う。ミドルウェアは `aim_core` 依存に切り替え、`dart:io` を使う `multipart` の `saveTo` は別ライブラリに隔離する。

**Tech Stack:** Dart 3.13.3（pub workspace）、`package:test`、`dart compile wasm`（dart:io 混入検出用）

**Spec:** `specs/2026-09-10-aim-core-extraction-design.md`

## Global Constraints

- Dart SDK: `mise.toml` は `3.13.3`、全 `pubspec.yaml` の `environment.sdk` は `^3.13.0`
- `aim_core` は `dart:io` を import しない（Task 5 の wasm smoke test で機械的に検証）
- 既存の公開 API（`Aim`、`Context`、`Request`、`Response`、`app.serve(host:, port:)`）は互換維持。既存ユーザーの `import 'package:aim_server/aim_server.dart';` は変更不要
- ミドルウェアパッケージ名 `aim_server_*` はリネームしない
- 全パッケージのバージョンは lockstep。`aim_core` は既存と同じ `0.1.1` で作る
- Lint: `analysis_options.yaml` の `always_use_package_imports: true`。相対 import は使わない
- コミットメッセージ末尾に `Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>` を付ける
- 各タスクの最後に `dart analyze --fatal-warnings` をリポジトリルートで実行し、warning ゼロを確認する
- 作業ブランチ: `main` から `feat/aim-core` を切って作業する（Task 1 の冒頭で作成）

---

## ファイル構成

作成:

- `packages/aim_core/pubspec.yaml`
- `packages/aim_core/analysis_options.yaml`（他パッケージと同じ `include: ../../analysis_options.yaml` 形式はない。ルートの `analysis_options.yaml` が workspace 全体に効くため作らない）
- `packages/aim_core/CHANGELOG.md`
- `packages/aim_core/README.md`
- `packages/aim_core/lib/aim_core.dart` — 公開 export
- `packages/aim_core/lib/src/app.dart` — `Aim<E>`、`Handler`/`Middleware`/`ErrorHandler`/`Next`/`UnhandledErrorHandler` typedef（旧 `server.dart` から移動）
- `packages/aim_core/lib/src/route.dart` — `Route<E>`（旧 `server.dart` から移動）
- `packages/aim_core/lib/src/{body,context,env,message,request,response}.dart` — `aim_server/lib/src/` から移動
- `packages/aim_core/test/unit/*.dart` — `aim_server/test/unit/` から移動
- `packages/aim_core/test/wasm_smoke/app.dart` — wasm コンパイル対象のダミーエントリ
- `packages/aim_core/test/wasm_smoke_test.dart` — `dart compile wasm` を実行するテスト
- `packages/aim_server/test/integration/io_adapter_test.dart` — アダプタ固有の変換テスト
- `packages/aim_server_multipart/lib/aim_server_multipart_io.dart` — `saveTo` extension
- `packages/aim_server_multipart/test/uploaded_file_io_test.dart`

変更:

- `mise.toml`、全 `pubspec.yaml`（SDK 制約）
- `pubspec.yaml`（ルート、workspace に `packages/aim_core` 追加）
- `packages/aim_server/pubspec.yaml`、`lib/aim_server.dart`、`lib/src/server.dart`（アダプタ化）
- `packages/aim_server_{cors,cookie,form,logger,sse,jwt,basic_auth,testing,multipart}/pubspec.yaml` と `lib/**`、`test/**` の import
- `packages/aim_server_multipart/lib/aim_server_multipart.dart`、`lib/src/multipart_form_data.dart`
- `.github/workflows/test.yml`、`README.md`、各 `CHANGELOG.md`

削除:

- `packages/aim_server/lib/src/{body,context,env,message,request,response}.dart`（移動）
- `packages/aim_server/test/unit/`（移動）
- `packages/aim_server_multipart/lib/src/aim_server_multipart.dart`（`Awesome` スタブ。公開 API が壊れていた原因）

---

### Task 1: SDK 3.13.3 化

**Files:**
- Modify: `mise.toml`
- Modify: 全 `pubspec.yaml` の `environment.sdk`（`packages/*/pubspec.yaml`、`examples/*/pubspec.yaml`、`tools/release/pubspec.yaml`、ルート `pubspec.yaml`、`packages/aim_orm_codegen/test/golden/fixtures/*/pubspec.yaml`。現状 26 ファイル、値は `^3.10.0` が 24、`^3.10.4` と `^3.10.7` が各 1）

**Interfaces:**
- Produces: 以降のタスクは Dart 3.13.3 で `dart pub get` が通っている状態を前提にする

- [ ] **Step 1: ブランチ作成**

```bash
cd /Users/naoki.hidaka/my-project/aim
git checkout -b feat/aim-core
```

- [ ] **Step 2: mise.toml の Dart バージョンを 3.13.3 に変更**

`mise.toml` の `version = "3.10.7"` を `version = "3.13.3"` に変える（他のキーは変更しない）。

```bash
sed -i '' 's/version = "3.10.7"/version = "3.13.3"/' mise.toml
dart --version
```

Expected: `Dart SDK version: 3.13.3 (stable)`。3.10.7 のままなら `mise install` を実行してから再確認。

- [ ] **Step 3: 全 pubspec.yaml の SDK 制約を ^3.13.0 に変更**

```bash
grep -rl --include=pubspec.yaml "sdk: \^3\.10\." . | grep -v .dart_tool | xargs sed -i '' -E 's/sdk: \^3\.10\.[0-9]+/sdk: ^3.13.0/'
grep -rh --include=pubspec.yaml "sdk:" . | grep -v .dart_tool | sort | uniq -c
```

Expected: 出力が `26   sdk: ^3.13.0` の 1 行だけ。

- [ ] **Step 4: 依存解決と静的解析**

```bash
dart pub get
dart analyze --fatal-warnings
```

Expected: `dart pub get` が成功。`analyzer: ^10.0.1` や `build_runner` が 3.13 と非互換で解決に失敗した場合は、該当パッケージの制約を pub.dev の最新に上げてから再実行し、変更内容をコミットメッセージに記す。`dart analyze` は `No issues found!`。

- [ ] **Step 5: CI 対象パッケージのテストを実行**

```bash
for p in aim_server aim_server_form aim_server_multipart aim_server_testing aim_server_static aim_server_logger aim_server_sse aim_server_jwt aim_server_basic_auth; do (cd packages/$p && dart test) || echo "FAILED: $p"; done
```

Expected: `FAILED:` の出力なし。

- [ ] **Step 6: codegen golden テストを実行（build_runner の互換確認）**

```bash
cd packages/aim_orm_codegen && dart test test/golden/run_golden_test.dart; cd ../..
```

Expected: 5 fixture すべて PASS。失敗した場合、差分が空白のみでないなら generator 側の 3.13 起因の変化なので、`expected.g.dart` を更新せず原因を報告して止まる。

- [ ] **Step 7: コミット**

```bash
git add mise.toml $(git ls-files '*pubspec.yaml')
git commit -m "chore: bump Dart SDK to 3.13.3

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 2: aim_core パッケージ作成と純粋な型の移動

`Aim` はまだ `aim_server` に残す。`aim_server` は `aim_core` に依存して re-export し、既存テストが緑のまま通ることを確認する。

**Files:**
- Create: `packages/aim_core/pubspec.yaml`、`packages/aim_core/lib/aim_core.dart`、`packages/aim_core/CHANGELOG.md`、`packages/aim_core/README.md`
- Move: `packages/aim_server/lib/src/{body,context,env,message,request,response}.dart` → `packages/aim_core/lib/src/`
- Move: `packages/aim_server/test/unit/{body_handling,context,request,response,status_codes}_test.dart` → `packages/aim_core/test/unit/`（`Aim` を参照しない 5 ファイル）
- Modify: ルート `pubspec.yaml`、`packages/aim_server/pubspec.yaml`、`packages/aim_server/lib/aim_server.dart`、`packages/aim_server/lib/src/server.dart`（import 先のみ）

**Interfaces:**
- Produces: `package:aim_core/aim_core.dart` が `Context`、`Env`、`EmptyEnv`、`Request`、`Response`、`Body`、`MessageMixin` を export する。`Request.raw` の型は `Object?`

- [ ] **Step 1: aim_core の pubspec と export ファイルを作成**

`packages/aim_core/pubspec.yaml`:

```yaml
name: aim_core
description: Platform-independent core of the Aim web framework. Routing, middleware, request and response types with no dart:io dependency.
version: 0.1.1
repository: https://github.com/aim-dart/aim
resolution: workspace

environment:
  sdk: ^3.13.0

dependencies:

dev_dependencies:
  lints: ^6.0.0
  test: ^1.25.6
```

`packages/aim_core/lib/aim_core.dart`:

```dart
/// Platform-independent core of the Aim web framework.
///
/// This library contains routing, middleware chaining, and the request and
/// response types. It does not depend on `dart:io`, so it can be compiled to
/// WebAssembly. Use `aim_server` to run on the Dart VM with `HttpServer`.
library;

export 'src/body.dart';
export 'src/context.dart';
export 'src/env.dart';
export 'src/message.dart';
export 'src/request.dart';
export 'src/response.dart';
```

`packages/aim_core/CHANGELOG.md`:

```markdown
## 0.1.1

Initial release. Extracted from `aim_server` with no public API changes.
```

`packages/aim_core/README.md`:

```markdown
# aim_core

Platform-independent core of the Aim framework: routing, middleware, `Request`, `Response`, and `Context`. No `dart:io` dependency.

You usually do not depend on this package directly. Use [aim_server](https://pub.dev/packages/aim_server) to run on the Dart VM. Middleware packages depend on `aim_core` so they work on every runtime adapter.
```

- [ ] **Step 2: ルート pubspec.yaml の workspace に追加**

ルート `pubspec.yaml` の `workspace:` リスト先頭に追加:

```yaml
workspace:
  - packages/aim_core
  - packages/aim_server
```

- [ ] **Step 3: 純粋な型のファイルを移動**

```bash
cd /Users/naoki.hidaka/my-project/aim
mkdir -p packages/aim_core/lib/src packages/aim_core/test/unit
for f in body context env message request response; do git mv packages/aim_server/lib/src/$f.dart packages/aim_core/lib/src/$f.dart; done
sed -i '' 's#package:aim_server/src/#package:aim_core/src/#g' packages/aim_core/lib/src/*.dart
grep -rn "package:aim_server" packages/aim_core/lib
```

Expected: 最後の grep は出力なし。

- [ ] **Step 4: Request.raw の型を Object? に変更し dart:io import を削除**

`packages/aim_core/lib/src/request.dart` を編集:

```dart
// 削除
import 'dart:io';
```

```dart
  /// The raw platform-specific request object, if available.
  ///
  /// On the Dart VM (`aim_server`) this is an `HttpRequest`. On other
  /// runtimes it is whatever the adapter received. Adapters provide typed
  /// accessors; core code must not depend on its concrete type.
  final Object? raw;
```

（フィールド宣言の `final HttpRequest? raw;` を上記に置き換える。コンストラクタの `this.raw` はそのまま。）

- [ ] **Step 5: aim_server を aim_core 依存にして re-export**

`packages/aim_server/pubspec.yaml` の `dependencies:` を:

```yaml
dependencies:
  aim_core: ^0.1.1
```

`packages/aim_server/lib/aim_server.dart` を:

```dart
library;

export 'package:aim_core/aim_core.dart';
export 'src/server.dart';
```

`packages/aim_server/lib/src/server.dart` の import を書き換え:

```bash
sed -i '' -E 's#package:aim_server/src/(context|env|request|response)\.dart#package:aim_core/aim_core.dart#' packages/aim_server/lib/src/server.dart
```

その結果 `import 'package:aim_core/aim_core.dart';` が 4 行重複するので 1 行に統合する。最終的な import 部は:

```dart
import 'dart:io';

import 'package:aim_core/aim_core.dart';
```

- [ ] **Step 6: Aim を参照しないテストを aim_core に移動**

```bash
for f in body_handling context request response status_codes; do git mv packages/aim_server/test/unit/${f}_test.dart packages/aim_core/test/unit/${f}_test.dart; done
sed -i '' 's#package:aim_server/aim_server.dart#package:aim_core/aim_core.dart#' packages/aim_core/test/unit/*.dart
```

- [ ] **Step 7: 依存解決と両パッケージのテスト**

```bash
dart pub get
(cd packages/aim_core && dart test)
(cd packages/aim_server && dart test)
dart analyze --fatal-warnings
```

Expected: 両方 PASS、analyze は `No issues found!`。`request_test.dart` の `raw: null` を渡すテストはそのまま通る。

- [ ] **Step 8: コミット**

```bash
git add -A packages/aim_core packages/aim_server pubspec.yaml
git commit -m "refactor: extract request/response types into aim_core

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 3: Aim と Route を aim_core に移動し handle() に一本化

**Files:**
- Create: `packages/aim_core/lib/src/app.dart`、`packages/aim_core/lib/src/route.dart`
- Move: `packages/aim_server/test/unit/{error_handling,handle,headers,http_methods,middleware,routing}_test.dart` → `packages/aim_core/test/unit/`
- Create: `packages/aim_core/test/unit/unhandled_error_test.dart`
- Modify: `packages/aim_core/lib/aim_core.dart`、`packages/aim_server/lib/src/server.dart`（全面書き換え）

**Interfaces:**
- Produces:
  - `typedef UnhandledErrorHandler<E extends Env> = Future<Response> Function(Object error, StackTrace stackTrace, Context<E> c);`
  - `Future<Response> Aim.handle(Request request, {UnhandledErrorHandler<E>? onUnhandledError})` — `onError` 未登録時に `onUnhandledError` を使い、両方 null なら `Response.internalServerError(body: 'Internal Server Error: $e')` を返す。コアは `print` しない
  - `aim_server`: `extension AimServe<E extends Env> on Aim<E> { Future<AimHttpServer> serve({required Object host, required int port, SecurityContext? securityContext, int? backlog, bool shared = false}) }`
  - `aim_server`: `extension HttpRequestAccess on Request { HttpRequest? get httpRequest; }`

- [ ] **Step 1: 失敗するテストを書く（コアは print せず 500 を返す）**

`packages/aim_core/test/unit/unhandled_error_test.dart`:

```dart
import 'dart:async';

import 'package:aim_core/aim_core.dart';
import 'package:test/test.dart';

/// Runs [body] and returns everything printed inside it.
Future<(T, List<String>)> capturePrint<T>(Future<T> Function() body) async {
  final lines = <String>[];
  final result = await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return (result, lines);
}

void main() {
  group('Aim.handle() unhandled errors', () {
    test('returns 500 without printing when no handler is registered',
        () async {
      final app = Aim();
      app.get('/boom', (c) async => throw Exception('boom'));

      final (response, printed) = await capturePrint(
        () => app.handle(Request('GET', Uri.parse('http://localhost/boom'))),
      );

      expect(response.statusCode, equals(500));
      expect(await response.readAsString(), contains('boom'));
      expect(printed, isEmpty);
    });

    test('uses onUnhandledError when onError is not registered', () async {
      final app = Aim();
      app.get('/boom', (c) async => throw StateError('bad state'));
      Object? seenError;
      StackTrace? seenStack;

      final response = await app.handle(
        Request('GET', Uri.parse('http://localhost/boom')),
        onUnhandledError: (error, stackTrace, c) async {
          seenError = error;
          seenStack = stackTrace;
          return c.text('fallback', statusCode: 503);
        },
      );

      expect(response.statusCode, equals(503));
      expect(await response.readAsString(), equals('fallback'));
      expect(seenError, isA<StateError>());
      expect(seenStack, isNotNull);
    });

    test('registered onError takes precedence over onUnhandledError',
        () async {
      final app = Aim();
      app.get('/boom', (c) async => throw Exception('boom'));
      app.onError((error, c) async => c.text('registered', statusCode: 502));

      final response = await app.handle(
        Request('GET', Uri.parse('http://localhost/boom')),
        onUnhandledError: (_, _, c) async => c.text('fallback'),
      );

      expect(response.statusCode, equals(502));
      expect(await response.readAsString(), equals('registered'));
    });
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
cd packages/aim_core && dart test test/unit/unhandled_error_test.dart; cd ../..
```

Expected: コンパイルエラー（`Aim` が `aim_core` に存在しない）。

- [ ] **Step 3: Route を aim_core に移動**

`packages/aim_server/lib/src/server.dart` の `class Route<E extends Env> {` から末尾までの `Route` クラス全体（doc コメント `/// Internal class representing a route with path pattern matching.` を含む）を切り取り、`packages/aim_core/lib/src/route.dart` に以下の import を付けて保存する:

```dart
import 'package:aim_core/src/app.dart';
import 'package:aim_core/src/env.dart';
```

（`Handler<E>` は `app.dart` で定義するため `app.dart` を import する。中身は変更しない。）

- [ ] **Step 4: Aim を aim_core に移動し handle() に一本化**

`packages/aim_server/lib/src/server.dart` から以下を `packages/aim_core/lib/src/app.dart` に移す: 先頭の typedef 4 つ（`Handler`、`Middleware`、`ErrorHandler`、`Next`）と `class Aim<E extends Env>` 全体。`AimHttpServer` クラスと `serve()`、`_handleRequest()` は移さない。

`app.dart` の import 部:

```dart
import 'package:aim_core/src/context.dart';
import 'package:aim_core/src/env.dart';
import 'package:aim_core/src/request.dart';
import 'package:aim_core/src/response.dart';
import 'package:aim_core/src/route.dart';
```

typedef に追加:

```dart
/// A function that handles an error when no [Aim.onError] handler is
/// registered. Receives the stack trace so adapters can log it.
typedef UnhandledErrorHandler<E extends Env> =
    Future<Response> Function(Object error, StackTrace stackTrace, Context<E> c);
```

`Aim` クラス内の変更:

1. `serve()` メソッドと `_handleRequest()` メソッドを削除する。
2. `handle()` を以下に置き換える:

```dart
  /// Handles a request and returns a response without any HTTP layer.
  ///
  /// This is the single request-processing path. Runtime adapters
  /// (`aim_server`, `aim_edge`) build a [Request], call this method, and
  /// write the returned [Response] back to their platform.
  ///
  /// This method:
  /// 1. Creates a Context with the provided request
  /// 2. Finds a matching route based on request method and path
  /// 3. Executes the middleware chain
  /// 4. Calls the appropriate handler (route handler or 404 handler)
  /// 5. Handles errors using the registered error handler, then
  ///    [onUnhandledError], then a plain 500 response
  ///
  /// The core never prints. Adapters that want to log unhandled errors pass
  /// [onUnhandledError].
  Future<Response> handle(
    Request request, {
    UnhandledErrorHandler<E>? onUnhandledError,
  }) async {
    final env = _envFactory();
    final context = Context<E>(request, env);

    try {
      Route<E>? matchingRoute;
      Map<String, String>? pathParams;

      for (final route in _routes) {
        if (route.method == request.method) {
          final params = route.match(request.path);
          if (params != null) {
            matchingRoute = route;
            pathParams = params;
            break;
          }
        }
      }

      Handler<E> finalHandler;
      if (matchingRoute == null) {
        finalHandler =
            _notFoundHandler ??
            (c) async => Response.notFound(body: 'Not Found');
      } else {
        finalHandler = (c) async {
          pathParams!.forEach((key, value) {
            c.set('param:$key', value);
          });
          return await matchingRoute!.handler(c);
        };
      }

      return await _executeMiddlewareChain(context, finalHandler);
    } catch (e, st) {
      if (_errorHandler != null) {
        try {
          return await _errorHandler!(e, context);
        } catch (_) {
          return Response.internalServerError(body: 'Internal Server Error');
        }
      }
      if (onUnhandledError != null) {
        try {
          return await onUnhandledError(e, st, context);
        } catch (_) {
          return Response.internalServerError(body: 'Internal Server Error');
        }
      }
      return Response.internalServerError(body: 'Internal Server Error: $e');
    }
  }
```

3. クラス doc コメント内の `await app.serve(host: InternetAddress.anyIPv4, port: 8080);` は `aim_server` 側の機能なので、`/// See `aim_server` for `serve()`.` に置き換える。

`packages/aim_core/lib/aim_core.dart` に export を追加:

```dart
export 'src/app.dart';
export 'src/route.dart';
```

- [ ] **Step 5: aim_server/lib/src/server.dart をアダプタに書き換え**

ファイル全体を以下に置き換える:

```dart
import 'dart:io';

import 'package:aim_core/aim_core.dart';

/// Typed access to the underlying `dart:io` request.
extension HttpRequestAccess on Request {
  /// The [HttpRequest] this request was created from, or `null` when the
  /// request was not produced by [AimServe.serve] (for example in tests).
  HttpRequest? get httpRequest => raw as HttpRequest?;
}

/// Runs an [Aim] application on `dart:io`'s [HttpServer].
extension AimServe<E extends Env> on Aim<E> {
  /// Starts the HTTP server and begins listening for requests.
  ///
  /// Returns an [AimHttpServer] instance that can be used to stop the server.
  ///
  /// Parameters:
  /// - [host]: The host address to bind to (e.g., InternetAddress.anyIPv4)
  /// - [port]: The port to listen on
  /// - [securityContext]: Optional SSL/TLS security context for HTTPS
  /// - [backlog]: The maximum number of pending connections (defaults to 0)
  /// - [shared]: Whether to allow multiple isolates to bind to the same port
  ///
  /// Unhandled errors without an [Aim.onError] handler are printed with
  /// their stack trace and answered with a 500 response.
  ///
  /// Example:
  /// ```dart
  /// final server = await app.serve(
  ///   host: InternetAddress.anyIPv4,
  ///   port: 8080,
  /// );
  /// print('Server running on http://${server.host}:${server.port}');
  /// ```
  Future<AimHttpServer> serve({
    required Object host,
    required int port,
    SecurityContext? securityContext,
    int? backlog,
    bool shared = false,
  }) async {
    backlog ??= 0;
    final server = await (securityContext == null
        ? HttpServer.bind(host, port, backlog: backlog, shared: shared)
        : HttpServer.bindSecure(
            host,
            port,
            securityContext,
            backlog: backlog,
            shared: shared,
          ));
    server.listen(_handleHttpRequest);
    return AimHttpServer._(server, server.address.host, server.port);
  }

  Future<void> _handleHttpRequest(HttpRequest httpRequest) async {
    final response = await handle(
      _toRequest(httpRequest),
      onUnhandledError: _printAndRespond,
    );
    await _writeResponse(httpRequest.response, response);
  }
}

/// Default error handler for the VM adapter: logs and returns 500.
Future<Response> _printAndRespond<E extends Env>(
  Object error,
  StackTrace stackTrace,
  Context<E> c,
) async {
  print('Error: $error');
  print(stackTrace.toString());
  return Response.internalServerError(body: 'Internal Server Error: $error');
}

/// Converts a `dart:io` [HttpRequest] into an Aim [Request].
///
/// Multi-value headers are joined with `,`. The URI is made absolute using
/// the `host` header (falling back to `localhost`).
Request _toRequest(HttpRequest httpRequest) {
  final headers = <String, String>{};
  httpRequest.headers.forEach((key, values) {
    headers[key] = values.join(',');
  });

  final scheme = httpRequest.connectionInfo?.localPort == 443 ? 'https' : 'http';
  final host = httpRequest.headers.value('host') ?? 'localhost';
  final absoluteUri = Uri.parse('$scheme://$host${httpRequest.uri}');

  return Request(
    httpRequest.method,
    absoluteUri,
    bodyContent: httpRequest,
    headers: headers,
    raw: httpRequest,
  );
}

/// Writes an Aim [Response] to a `dart:io` [HttpResponse].
///
/// `Set-Cookie` values joined with `\n` are split into separate headers.
/// `text/event-stream` responses disable output buffering and every chunk
/// is flushed so SSE clients receive events in real time.
Future<void> _writeResponse(HttpResponse out, Response response) async {
  try {
    out.statusCode = response.statusCode;
    response.headers.forEach((key, value) {
      if (key.toLowerCase() == 'set-cookie') {
        for (final cookie in value.split('\n')) {
          if (cookie.isNotEmpty) out.headers.add(key, cookie);
        }
      } else {
        out.headers.set(key, value);
      }
    });

    final contentType = response.headers['content-type'];
    if (contentType != null && contentType.contains('text/event-stream')) {
      out.bufferOutput = false;
    }

    await for (final chunk in response.read()) {
      out.add(chunk);
      await out.flush();
    }
    await out.close();
  } catch (e) {
    print('Failed to send response: $e');
    try {
      await out.close();
    } catch (_) {
      // Ignore
    }
  }
}

/// Represents a running HTTP server.
///
/// Returned by [AimServe.serve] and can be used to stop the server.
class AimHttpServer {
  /// The host address the server is bound to.
  final String host;

  /// The port the server is listening on.
  final int port;

  final HttpServer _server;

  AimHttpServer._(this._server, this.host, this.port);

  /// Closes the HTTP server.
  ///
  /// If [force] is true, active connections will be closed immediately.
  /// Otherwise, the server will wait for active connections to close.
  Future<void> close({bool force = false}) async {
    await _server.close(force: force);
  }
}
```

- [ ] **Step 6: 残りのユニットテストを aim_core に移動**

```bash
for f in error_handling handle headers http_methods middleware routing; do git mv packages/aim_server/test/unit/${f}_test.dart packages/aim_core/test/unit/${f}_test.dart; done
sed -i '' 's#package:aim_server/aim_server.dart#package:aim_core/aim_core.dart#' packages/aim_core/test/unit/*.dart
rmdir packages/aim_server/test/unit
```

- [ ] **Step 7: テスト実行**

```bash
dart pub get
(cd packages/aim_core && dart test)
(cd packages/aim_server && dart test)
dart analyze --fatal-warnings
```

Expected: `aim_core` の 12 ファイルすべて PASS（新規 `unhandled_error_test.dart` を含む）。`aim_server` は `integration/sse_streaming_test.dart` が PASS。analyze は `No issues found!`。

`error_handling_test.dart` に「onError 未登録時に `Internal Server Error: ` で始まる body を期待する」テストがあれば、新しい `handle()` も同じ文字列を返すので通る。

- [ ] **Step 8: コミット**

```bash
git add -A packages/aim_core packages/aim_server
git commit -m "refactor: move Aim and Route into aim_core, make aim_server a dart:io adapter

handle() is now the single request path. The core no longer prints;
the VM adapter logs unhandled errors via onUnhandledError.

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 4: aim_server アダプタの変換テスト

**Files:**
- Create: `packages/aim_server/test/integration/io_adapter_test.dart`

**Interfaces:**
- Consumes: Task 3 の `AimServe.serve()`、`HttpRequestAccess.httpRequest`

- [ ] **Step 1: テストを書く**

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:test/test.dart';

Future<(T, List<String>)> capturePrint<T>(Future<T> Function() body) async {
  final lines = <String>[];
  final result = await runZoned(
    body,
    zoneSpecification: ZoneSpecification(
      print: (_, _, _, line) => lines.add(line),
    ),
  );
  return (result, lines);
}

void main() {
  late HttpClient client;

  setUp(() => client = HttpClient());
  tearDown(() => client.close(force: true));

  Future<HttpClientResponse> send(
    int port,
    String method,
    String path, {
    Map<String, List<String>> headers = const {},
  }) async {
    final req = await client.openUrl(
      method,
      Uri.parse('http://localhost:$port$path'),
    );
    headers.forEach((k, values) {
      for (final v in values) {
        req.headers.add(k, v);
      }
    });
    return req.close();
  }

  group('dart:io adapter', () {
    test('joins multi-value request headers with a comma', () async {
      final app = Aim();
      app.get('/h', (c) async => c.text(c.headers['x-multi'] ?? ''));
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final res = await send(
        server.port,
        'GET',
        '/h',
        headers: {'x-multi': ['a', 'b']},
      );

      expect(await utf8.decodeStream(res), equals('a,b'));
    });

    test('builds an absolute request URI from the host header', () async {
      final app = Aim();
      app.get('/u', (c) async => c.text(c.req.uri.toString()));
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final res = await send(server.port, 'GET', '/u?q=1');

      expect(
        await utf8.decodeStream(res),
        equals('http://localhost:${server.port}/u?q=1'),
      );
    });

    test('exposes the HttpRequest through Request.httpRequest', () async {
      final app = Aim();
      app.get('/raw', (c) async {
        final raw = c.req.httpRequest;
        return c.text(raw == null ? 'null' : raw.method);
      });
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final res = await send(server.port, 'GET', '/raw');

      expect(await utf8.decodeStream(res), equals('GET'));
    });

    test('splits newline-joined Set-Cookie into separate headers', () async {
      final app = Aim();
      app.get(
        '/c',
        (c) async => Response.text(
          'ok',
          headers: {'set-cookie': 'a=1; Path=/\nb=2; Path=/'},
        ),
      );
      final server = await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
      addTearDown(() => server.close(force: true));

      final res = await send(server.port, 'GET', '/c');
      await res.drain<void>();

      expect(res.headers['set-cookie'], hasLength(2));
      expect(res.headers['set-cookie'], contains('a=1; Path=/'));
      expect(res.headers['set-cookie'], contains('b=2; Path=/'));
    });

    test('prints unhandled errors and answers 500 when onError is unset',
        () async {
      final app = Aim();
      app.get('/boom', (c) async => throw Exception('boom'));

      final (res, printed) = await capturePrint(() async {
        final server =
            await app.serve(host: InternetAddress.loopbackIPv4, port: 0);
        addTearDown(() => server.close(force: true));
        return send(server.port, 'GET', '/boom');
      });

      expect(res.statusCode, equals(500));
      expect(await utf8.decodeStream(res), contains('boom'));
      expect(printed.first, equals('Error: Exception: boom'));
      expect(printed.length, greaterThanOrEqualTo(2));
    });
  });
}
```

- [ ] **Step 2: テスト実行**

```bash
cd packages/aim_server && dart test test/integration/io_adapter_test.dart; cd ../..
```

Expected: 5 テストすべて PASS。`prints unhandled errors` が失敗して `printed` が空の場合、`serve()` を `runZoned` の中で呼んでいるか確認する（`HttpServer.listen` は呼び出し時の zone でコールバックを実行する）。

- [ ] **Step 3: コミット**

```bash
git add packages/aim_server/test/integration/io_adapter_test.dart
git commit -m "test: cover dart:io adapter conversions

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 5: aim_core の wasm smoke test（dart:io 混入検出）

**Files:**
- Create: `packages/aim_core/test/wasm_smoke/app.dart`、`packages/aim_core/test/wasm_smoke_test.dart`

- [ ] **Step 1: wasm コンパイル対象のエントリを書く**

`packages/aim_core/test/wasm_smoke/app.dart`:

```dart
// Compiled with `dart compile wasm` by wasm_smoke_test.dart.
// If aim_core ever imports dart:io, this compilation fails.
import 'package:aim_core/aim_core.dart';

void main() {
  final app = Aim();
  app.use((c, next) async {
    c.header('x-smoke', '1');
    await next();
  });
  app.get('/users/:id', (c) async => c.json({'id': c.param('id')}));
  app.handle(Request('GET', Uri.parse('http://localhost/users/1')));
}
```

- [ ] **Step 2: 失敗するテストを書く**

`packages/aim_core/test/wasm_smoke_test.dart`:

```dart
import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('aim_core compiles to wasm (no dart:io dependency)', () async {
    final outDir = await Directory.systemTemp.createTemp('aim_core_wasm_');
    addTearDown(() => outDir.delete(recursive: true));

    final result = await Process.run(
      'dart',
      [
        'compile',
        'wasm',
        'test/wasm_smoke/app.dart',
        '-o',
        '${outDir.path}/app.wasm',
      ],
    );

    expect(
      result.exitCode,
      equals(0),
      reason: 'stdout:\n${result.stdout}\nstderr:\n${result.stderr}',
    );
    expect(File('${outDir.path}/app.wasm').existsSync(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
```

- [ ] **Step 3: 一時的に dart:io を混入させて失敗を確認**

`packages/aim_core/lib/src/env.dart` の先頭に `import 'dart:io';` を一時的に追加してテストを実行:

```bash
cd packages/aim_core && dart test test/wasm_smoke_test.dart; cd ../..
```

Expected: FAIL。`reason` に `dart:io` 関連のコンパイルエラーが出る。確認後、追加した import を削除する（`git diff packages/aim_core/lib/src/env.dart` が空であること）。

- [ ] **Step 4: テストが通ることを確認**

```bash
cd packages/aim_core && dart test; cd ../..
```

Expected: 全 PASS（wasm smoke を含む）。

- [ ] **Step 5: コミット**

```bash
git add packages/aim_core/test
git commit -m "test: verify aim_core compiles to wasm

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 6: ミドルウェア 7 パッケージと aim_server_testing を aim_core 依存に切り替え

対象: `aim_server_cors`、`aim_server_cookie`、`aim_server_form`、`aim_server_logger`、`aim_server_sse`、`aim_server_jwt`、`aim_server_basic_auth`、`aim_server_testing`。`aim_server_static` は対象外（`dart:io` が本質）。`aim_server_multipart` は Task 7。

方針: `lib/` は `aim_core` を import。`example/` と `serve()` を使う統合テスト（`aim_server_form/test/integration_test.dart`）は `aim_server` を import し続けるため、`aim_server` を `dev_dependencies` に残す。

**Files:**
- Modify: 上記 8 パッケージの `pubspec.yaml`
- Modify: 以下の `lib/` ファイルの import
  - `aim_server_cors/lib/src/aim_server_cors.dart`
  - `aim_server_cookie/lib/aim_server_cookie.dart`、`lib/src/aim_server_cookie.dart`
  - `aim_server_form/lib/aim_server_form.dart`、`lib/src/form_request.dart`
  - `aim_server_logger/lib/src/logger_middleware.dart`
  - `aim_server_sse/lib/src/sse_context.dart`
  - `aim_server_jwt/lib/src/jwt_middleware.dart`、`lib/src/jwt_env.dart`
  - `aim_server_basic_auth/lib/src/basic_auth_middleware.dart`、`lib/src/basic_auth_env.dart`
  - `aim_server_testing/lib/aim_server_testing.dart`、`lib/src/request_builder.dart`、`lib/src/matchers.dart`、`lib/src/test_client.dart`
- Modify: `serve()` を使わないテストの import
  - `aim_server_form/test/form_request_test.dart`
  - `aim_server_logger/test/logger_middleware_test.dart`
  - `aim_server_sse/test/sse_test.dart`
  - `aim_server_jwt/test/jwt_middleware_test.dart`
  - `aim_server_basic_auth/test/basic_auth_middleware_test.dart`
  - `aim_server_testing/test/test_client_test.dart`
- Keep: `*/example/main.dart` と `aim_server_form/test/integration_test.dart` は `aim_server` import のまま

- [ ] **Step 1: pubspec の依存を書き換え**

各パッケージの `dependencies:` の `aim_server: ^0.1.1` を `aim_core: ^0.1.1` に変え、`dev_dependencies:` に `aim_server: ^0.1.1` を追加する。

```bash
cd /Users/naoki.hidaka/my-project/aim/packages
for p in aim_server_cors aim_server_cookie aim_server_form aim_server_logger aim_server_sse aim_server_jwt aim_server_basic_auth aim_server_testing; do
  sed -i '' 's/^  aim_server: \^0\.1\.1$/  aim_core: ^0.1.1/' $p/pubspec.yaml
  perl -0pi -e 's/^dev_dependencies:\n/dev_dependencies:\n  aim_server: ^0.1.1\n/m' $p/pubspec.yaml
done
grep -n "aim_core\|aim_server:" aim_server_cors/pubspec.yaml
```

Expected: `dependencies` 側に `aim_core: ^0.1.1`、`dev_dependencies` 側に `aim_server: ^0.1.1`。

- [ ] **Step 2: lib/ の import を書き換え**

```bash
for p in aim_server_cors aim_server_cookie aim_server_form aim_server_logger aim_server_sse aim_server_jwt aim_server_basic_auth aim_server_testing; do
  grep -rl "package:aim_server/aim_server.dart" $p/lib | xargs sed -i '' 's#package:aim_server/aim_server.dart#package:aim_core/aim_core.dart#'
done
grep -rn "package:aim_server/" aim_server_{cors,cookie,form,logger,sse,jwt,basic_auth,testing}/lib
```

Expected: 最後の grep は出力なし。

- [ ] **Step 3: serve() を使わないテストの import を書き換え**

```bash
for f in aim_server_form/test/form_request_test.dart aim_server_logger/test/logger_middleware_test.dart aim_server_sse/test/sse_test.dart aim_server_jwt/test/jwt_middleware_test.dart aim_server_basic_auth/test/basic_auth_middleware_test.dart aim_server_testing/test/test_client_test.dart; do
  sed -i '' 's#package:aim_server/aim_server.dart#package:aim_core/aim_core.dart#' $f
done
```

- [ ] **Step 4: aim_server_form の doc コメントの import 例を直す**

`aim_server_form/lib/aim_server_form.dart` の doc コメントに `import 'package:aim_form/aim_server_form.dart';` という誤記がある。`import 'package:aim_server_form/aim_server_form.dart';` に直す。

- [ ] **Step 5: 依存解決、テスト、解析**

```bash
cd /Users/naoki.hidaka/my-project/aim
dart pub get
for p in aim_server_cors aim_server_cookie aim_server_form aim_server_logger aim_server_sse aim_server_jwt aim_server_basic_auth aim_server_testing; do (cd packages/$p && dart test) || echo "FAILED: $p"; done
dart analyze --fatal-warnings
```

Expected: `FAILED:` なし。`cors` と `cookie` はテストが無いので `No tests were found` でも可。analyze は `No issues found!`。

- [ ] **Step 6: コミット**

```bash
git add packages/aim_server_{cors,cookie,form,logger,sse,jwt,basic_auth,testing}
git commit -m "refactor: depend on aim_core in middleware and testing packages

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 7: aim_server_multipart の dart:io 分離と公開 export の修正

現状 `lib/aim_server_multipart.dart` は `Awesome` スタブしか export しておらず、利用側は `src/` を直接 import している。この機会に export を正す。

**Files:**
- Delete: `packages/aim_server_multipart/lib/src/aim_server_multipart.dart`
- Modify: `packages/aim_server_multipart/lib/aim_server_multipart.dart`、`lib/src/multipart_form_data.dart`、`lib/src/multipart_request.dart`、`pubspec.yaml`
- Create: `packages/aim_server_multipart/lib/aim_server_multipart_io.dart`、`test/uploaded_file_io_test.dart`

**Interfaces:**
- Produces: `package:aim_server_multipart/aim_server_multipart.dart` が `MultipartFormData`、`UploadedFile`、`parseMultipart`、`MultipartRequest` extension を export。`package:aim_server_multipart/aim_server_multipart_io.dart` が `extension UploadedFileIO on UploadedFile { Future<void> saveTo(String path) }` を提供

- [ ] **Step 1: 失敗するテストを書く**

`packages/aim_server_multipart/test/uploaded_file_io_test.dart`:

```dart
import 'dart:io';

import 'package:aim_server_multipart/aim_server_multipart.dart';
import 'package:aim_server_multipart/aim_server_multipart_io.dart';
import 'package:test/test.dart';

void main() {
  test('saveTo writes the uploaded bytes to disk', () async {
    final dir = await Directory.systemTemp.createTemp('aim_multipart_');
    addTearDown(() => dir.delete(recursive: true));
    const file = UploadedFile(
      filename: 'file_1_abc.txt',
      originalFilename: 'hello.txt',
      contentType: 'text/plain',
      bytes: [104, 105],
    );

    await file.saveTo('${dir.path}/out.txt');

    expect(await File('${dir.path}/out.txt').readAsString(), equals('hi'));
  });
}
```

- [ ] **Step 2: テストが失敗することを確認**

```bash
cd packages/aim_server_multipart && dart test test/uploaded_file_io_test.dart; cd ../..
```

Expected: コンパイルエラー（`aim_server_multipart_io.dart` が存在しない、`UploadedFile` が公開 export に無い）。

- [ ] **Step 3: 公開 export を修正しスタブを削除**

```bash
git rm packages/aim_server_multipart/lib/src/aim_server_multipart.dart
```

`packages/aim_server_multipart/lib/aim_server_multipart.dart`:

```dart
/// Multipart form data parsing for the Aim framework.
///
/// Works on every Aim runtime adapter. To save uploaded files to disk on the
/// Dart VM, also import `package:aim_server_multipart/aim_server_multipart_io.dart`.
library;

export 'src/multipart_form_data.dart';
export 'src/multipart_parser.dart';
export 'src/multipart_request.dart';
```

- [ ] **Step 4: saveTo を dart:io ライブラリに移す**

`packages/aim_server_multipart/lib/src/multipart_form_data.dart` から `import 'dart:io';` と `saveTo` メソッド（doc コメント含む）を削除する。

`packages/aim_server_multipart/lib/aim_server_multipart_io.dart`:

```dart
/// `dart:io` helpers for `aim_server_multipart`.
///
/// Import this in addition to `aim_server_multipart.dart` when running on the
/// Dart VM. It is not available when compiling to WebAssembly.
library;

import 'dart:io';

import 'package:aim_server_multipart/src/multipart_form_data.dart';

/// File-system operations for [UploadedFile].
extension UploadedFileIO on UploadedFile {
  /// Saves the uploaded file to the specified [path].
  ///
  /// Creates or overwrites the file at the given path with the uploaded content.
  ///
  /// Example:
  /// ```dart
  /// await file.saveTo('uploads/${file.filename}');
  /// ```
  ///
  /// Throws [FileSystemException] if the file cannot be written.
  Future<void> saveTo(String path) async {
    await File(path).writeAsBytes(bytes);
  }
}
```

- [ ] **Step 5: 依存と import を aim_core に切り替え**

`packages/aim_server_multipart/pubspec.yaml`:

```yaml
dependencies:
  aim_core: ^0.1.1
  mime: ^2.0.0

dev_dependencies:
  aim_server: ^0.1.1
  lints: ^6.0.0
  test: ^1.25.6
```

```bash
sed -i '' 's#package:aim_server/aim_server.dart#package:aim_core/aim_core.dart#' packages/aim_server_multipart/lib/src/multipart_request.dart
grep -rn "dart:io\|package:aim_server/" packages/aim_server_multipart/lib
```

Expected: grep の結果は `lib/aim_server_multipart_io.dart` の `import 'dart:io';` の 1 行だけ。`example/main.dart` は `serve()` を使うので `aim_server` import のまま。

- [ ] **Step 6: テストと解析**

```bash
dart pub get
(cd packages/aim_server_multipart && dart test)
dart analyze --fatal-warnings
```

Expected: 既存 3 ファイルと新規 1 ファイルすべて PASS。analyze は `No issues found!`。

- [ ] **Step 7: CHANGELOG に破壊的変更を記載**

`packages/aim_server_multipart/CHANGELOG.md` の先頭に追加:

```markdown
## Unreleased

- **Breaking:** `UploadedFile.saveTo()` moved to the `UploadedFileIO` extension in `package:aim_server_multipart/aim_server_multipart_io.dart`. Add that import to keep using it.
- `aim_server_multipart.dart` now exports `MultipartFormData`, `UploadedFile`, `parseMultipart`, and the `MultipartRequest` extension (previously only a placeholder was exported).
- Depends on `aim_core` instead of `aim_server`, so it works on every runtime adapter.
```

- [ ] **Step 8: コミット**

```bash
git add -A packages/aim_server_multipart
git commit -m "refactor(multipart): isolate dart:io into aim_server_multipart_io and fix public exports

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

### Task 8: CI、README、CHANGELOG

**Files:**
- Modify: `.github/workflows/test.yml`、`README.md`、`packages/aim_server/CHANGELOG.md`、`packages/aim_server/pubspec.yaml`（description）

- [ ] **Step 1: CI に aim_core を追加**

`.github/workflows/test.yml` の `- name: Run tests for aim_server` ステップの直前に追加:

```yaml
      - name: Run tests for aim_core
        working-directory: packages/aim_core
        run: dart test
```

- [ ] **Step 2: README のパッケージ表に aim_core を追加**

`README.md` の Server 表で `[aim_server](./packages/aim_server)` の行の直前に追加:

```markdown
| [aim_core](./packages/aim_core) | [![Pub Version](https://img.shields.io/pub/v/aim_core)](https://pub.dev/packages/aim_core) | Platform-independent core (routing, middleware, request/response) |
```

`aim_server` 行の説明を `Core web server framework` から `dart:io adapter: runs an Aim app on HttpServer` に変える。

- [ ] **Step 3: aim_server の description と CHANGELOG**

`packages/aim_server/pubspec.yaml` の `description:` を:

```yaml
description: Run Aim web applications on the Dart VM with dart:io HttpServer. Re-exports aim_core.
```

`packages/aim_server/CHANGELOG.md` の先頭に追加:

```markdown
## Unreleased

- Internals moved to the new `aim_core` package. `aim_server` re-exports it, so existing imports keep working.
- `serve()` is now an extension on `Aim` provided by `aim_server`.
- `Request.raw` is typed `Object?`. Use the `Request.httpRequest` extension getter from `aim_server` to get the `HttpRequest`.
- Unhandled errors without `onError` are still printed with their stack trace when running via `serve()`. `Aim.handle()` itself no longer prints.
```

- [ ] **Step 4: 全体確認**

```bash
dart pub get
dart analyze --fatal-warnings
for p in aim_core aim_server aim_server_form aim_server_multipart aim_server_testing aim_server_static aim_server_logger aim_server_sse aim_server_jwt aim_server_basic_auth; do (cd packages/$p && dart test) || echo "FAILED: $p"; done
(cd examples/basic-sample && dart analyze)
```

Expected: `FAILED:` なし、analyze は `No issues found!`。`examples/basic-sample` は `aim_server` を使い続けるので無変更で解析が通る。

- [ ] **Step 5: コミット**

```bash
git add .github/workflows/test.yml README.md packages/aim_server/CHANGELOG.md packages/aim_server/pubspec.yaml
git commit -m "docs: add aim_core to CI, README and changelogs

Co-Authored-By: Claude Fable 5.1 <noreply@anthropic.com>"
```

---

## セルフレビュー結果

Spec との対応:

| Spec の要件 | タスク |
|---|---|
| SDK 3.13.3 前提 | Task 1 |
| `aim_core` に `Aim`/`Route`/`Context`/`Request`/`Response`/`Body`/`MessageMixin` | Task 2, 3 |
| `handle()` に一本化、`_handleRequest` の重複削除 | Task 3 |
| `Request.raw` を `Object?`、アダプタで型付きアクセサ | Task 2 (型), Task 3 (`httpRequest`) |
| コアは `print` しない、アダプタの既定ハンドラで出力 | Task 3 (`onUnhandledError`), Task 4 (検証) |
| `aim_server` は re-export + `serve()` extension + 変換 | Task 2, 3 |
| Set-Cookie 分割、SSE `bufferOutput=false` | Task 3 (実装), Task 4 (Set-Cookie 検証), 既存 `sse_streaming_test` (SSE) |
| ミドルウェア 7 つと testing を `aim_core` 依存 | Task 6 |
| multipart のライブラリ分割 | Task 7 |
| static は対象外 | 変更なし |
| 既存 unit テスト 11 ファイルの移動 | Task 2 (5), Task 3 (6) |
| wasm smoke test | Task 5 |
| CI、README、CHANGELOG、workspace 追加 | Task 2 (workspace), Task 8 |

Spec からの意図的な差分:

- Spec では「onError 未登録時にコアは 500 を返すだけ」としていたが、アダプタがスタックトレースを出力するには `handle()` に注入口が必要なため、`onUnhandledError` 引数を追加した。Spec の「コアは `print` しない」「アダプタ側で従来どおり出力」は満たす。
- Spec で「ミドルウェアはコード変更なし」としたが、`lib/` の import 行の書き換えは必要（依存先が変わるため）。ロジックの変更はない。
- `aim_server_multipart` の公開 export が壊れていた（スタブのみ export）ため、Task 7 で修正を含めた。
