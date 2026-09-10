---
title: Migration Guide - Aim Framework
description: Upgrade Aim applications between releases. Breaking changes, renamed APIs, and step-by-step migration instructions.
head:
  - - meta
    - name: keywords
      content: Aim migration, upgrade guide, breaking changes, Env to Variables, aim_core, aim_edge, Dart 3.13
---

# Migration Guide

This page lists the breaking changes in each release and how to update your application.

## 0.1.x → 0.2.0

0.2.0 splits the framework core out of `aim_server`, adds the Cloudflare workerd adapter `aim_edge`, and renames the per-request variable type to match Hono's terminology. Most applications need three edits: bump dependencies, rename `Env` to `Variables`, and rename `envFactory` to `variablesFactory`.

### 1. Update the Dart SDK and dependencies

0.2.0 requires Dart 3.13 or later.

```yaml
environment:
  sdk: ^3.13.0

dependencies:
  aim_server: ^0.2.0
  aim_server_cors: ^0.2.0   # every aim_* package moves to 0.2.0 together
```

`import 'package:aim_server/aim_server.dart';` still exports everything it did in 0.1.x. The routing, middleware, `Context`, `Request`, and `Response` types now live in a new package, `aim_core`, which `aim_server` re-exports. You do not need to depend on `aim_core` directly unless you are writing a middleware package that should work on every runtime.

### 2. Rename `Env` to `Variables`

The class you extended for type-safe context variables is now called `Variables`. `Env` remains as a deprecated typedef for this release and will be removed in the next one.

| 0.1.x | 0.2.0 |
|---|---|
| `class AppEnv extends Env {}` | `class AppVariables extends Variables {}` |
| `EmptyEnv` | `EmptyVariables` |
| `Aim<AppEnv>(envFactory: () => AppEnv())` | `Aim<AppVariables>(variablesFactory: () => AppVariables())` |
| `Middleware<E extends Env>` | `Middleware<E extends Variables>` |
| `JwtEnv`, `JwtEnv.create(...)` | `JwtVariables`, `JwtVariables.create(...)` |
| `BasicAuthEnv` | `BasicAuthVariables` |

`c.variables` is unchanged. The constructor parameter `envFactory` has no deprecated alias, so it must be renamed.

```dart
// 0.1.x
class AppEnv extends Env {
  String? requestId;
}
final app = Aim<AppEnv>(envFactory: () => AppEnv());

// 0.2.0
class AppVariables extends Variables {
  String? requestId;
}
final app = Aim<AppVariables>(variablesFactory: () => AppVariables());
```

Why the rename: in Hono, `Variables` are per-request values set by middleware, while `env` holds runtime bindings such as Cloudflare Workers' KV or secrets. Aim's `Env` was the former, so it now carries the same name, and `c.env` is free to mean bindings in `aim_edge`.

### 3. `Request.raw` is no longer typed

`Request.raw` was `HttpRequest?`. It is now `Object?`, because the raw request depends on the runtime. On the Dart VM, use the extension getter from `aim_server`:

```dart
// 0.1.x
final HttpRequest? http = c.req.raw;

// 0.2.0
final HttpRequest? http = c.req.httpRequest;
```

### 4. `aim_server_multipart`: `saveTo` moved

`UploadedFile.saveTo()` uses `dart:io`, which is unavailable on workerd, so it moved to a separate library. Add one import:

```dart
import 'package:aim_server_multipart/aim_server_multipart.dart';
import 'package:aim_server_multipart/aim_server_multipart_io.dart'; // for saveTo()

await file.saveTo('uploads/${file.filename}');
```

The main library now exports `MultipartFormData`, `UploadedFile`, `parseMultipart`, and the `MultipartRequest` extension. In 0.1.x these were only reachable through `src/` imports; replace any `package:aim_server_multipart/src/...` import with the public library.

### 5. `aim_cli` configuration

`aim_cli` reads the `aim:` section of `pubspec.yaml` with a real YAML parser now, and gains an optional `target` key.

```yaml
aim:
  target: server        # optional. server (default) or edge
  entry: bin/server.dart
  env:
    PORT: "8080"
```

- `target` defaults to `server`, so existing projects keep working without adding it. Set `target: edge` to build for Cloudflare workerd (see below).
- `--entry` now overrides `aim.entry` for both `aim dev` and `aim build`. In 0.1.x `aim dev` ignored `--entry` when `aim.entry` was set.
- `aim.env` values are parsed as YAML. Quote values that contain `:` or start with special characters, for example `DATABASE_URL: "postgres://user:pass@host/db"`.
- CLI errors now exit with a non-zero status (`1`, or `64` for usage errors). Scripts that relied on `aim build` always returning `0` should check the output instead.

Reinstall the CLI to pick up the new version:

```bash
dart install aim_cli
```

### 6. Unhandled errors when calling `handle()` directly

`Aim.handle(Request)` no longer prints unhandled errors. Applications started with `app.serve(...)` are unaffected: the `dart:io` adapter still logs the error and stack trace and answers 500. If you call `handle()` yourself (for example in tests through `TestClient`) and relied on the console output, register an `onError` handler or pass `onUnhandledError`.

### New in 0.2.0: `aim_edge`

`aim_edge` runs the same `Aim` application on Cloudflare workerd, compiled with `dart compile wasm`. Nothing changes for server applications, but the adapter shapes a few APIs:

- `c.env` returns the worker's bindings (vars, secrets, KV, D1) as a `JSObject?`; `c.executionContext` returns the `ExecutionContext` for `waitUntil`.
- Middleware packages (`aim_server_cors`, `aim_server_jwt`, and the others) depend on `aim_core` and work unchanged on both runtimes, except `aim_server_static`, which needs the file system.

To try it: `aim create my_worker --target edge`, then `aim dev`. See the [CLI configuration](/cli/configuration#target) for the `target` key.

### Checklist

- [ ] `sdk: ^3.13.0` and every `aim_*` dependency at `^0.2.0`
- [ ] `Env` → `Variables`, `EmptyEnv` → `EmptyVariables`, `JwtEnv` → `JwtVariables`, `BasicAuthEnv` → `BasicAuthVariables`
- [ ] `envFactory:` → `variablesFactory:`
- [ ] `c.req.raw` → `c.req.httpRequest`
- [ ] `aim_server_multipart_io.dart` imported where `saveTo()` is used; no `src/` imports
- [ ] `aim.env` values with `:` quoted
- [ ] `dart install aim_cli`, then `aim build` to confirm the project compiles
