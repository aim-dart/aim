## Unreleased

- **Breaking:** `c.req.workerEnv` / `c.req.workerContext` are replaced by `c.env` / `c.executionContext` (extension on `Context`).
- **Breaking:** follows `aim_core`'s rename of `Env` → `Variables` and `envFactory` → `variablesFactory` (re-exported).

## 0.1.1

Initial release. Runs `aim_core` applications on Cloudflare workerd via `dart compile wasm`.
