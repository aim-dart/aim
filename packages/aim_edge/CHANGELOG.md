## Unreleased

- **Breaking:** `c.req.workerEnv` / `c.req.workerContext` are replaced by `c.env` / `c.executionContext` (extension on `Context`).

## 0.1.1

Initial release. Runs `aim_core` applications on Cloudflare workerd via `dart compile wasm`.
