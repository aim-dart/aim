import mod from '../.out/main.wasm';
import { CompiledApp } from '../.out/main.mjs';

let ready;

async function init() {
  const instance = await new CompiledApp(mod, { builtins: ['js-string'] })
    .instantiate({});
  instance.invokeMain(); // runs Dart main(), which calls app.serveEdge()
}

export default {
  async fetch(request, env, ctx) {
    ready ??= init();
    try {
      await ready;
    } catch (e) {
      ready = undefined; // allow the next request to retry initialisation
      throw e;
    }
    return globalThis.__aimFetch(request, env, ctx);
  },
};
