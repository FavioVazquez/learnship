# Phase 1: Foundation — Research

**Researched:** 2026-05-26
**Phase goal:** Working monorepo — `npm run dev` starts both servers, `/api/health` responds, shared TypeScript types defined, Anthropic SDK installed.

---

## Don't Hand-Roll

| Problem | Recommended solution | Why |
|---------|---------------------|-----|
| Running multiple dev processes | `concurrently` npm package | Cross-platform, colored output per process, clean kill-all on Ctrl+C. Alternative `npm-run-all` works but `concurrently` has better output formatting for live demos. |
| TypeScript execution in development | `tsx` (not `ts-node`) | `tsx` uses esbuild and handles Node 20+ ESM natively. `ts-node` with `--esm` has known loader issues on Node 20+ (`ERR_UNKNOWN_FILE_EXTENSION` on imports). |
| File watching in dev | `nodemon` with `tsx` executor | `nodemon.json` at `server/nodemon.json` configured with `"exec": "tsx src/index.ts"`. Restart on any `.ts` change in `src/`. |
| Tailwind CSS setup with Vite | `tailwindcss` + `postcss` + `autoprefixer` (standard Vite setup) | `tailwind.config.js` + `postcss.config.js` + `@tailwind` directives in `index.css`. Vite's PostCSS integration handles the rest automatically. |
| Environment variable loading | `import 'dotenv/config'` (not `dotenv.config()`) | The ES module import form loads `.env` synchronously as a side effect. Must be the FIRST import in `server/src/index.ts` to ensure variables are available in all subsequent imports. |

---

## Common Pitfalls

### Pitfall 1: NodeNext module resolution requires `.js` extensions on local TypeScript imports

**What goes wrong:** With `"moduleResolution": "NodeNext"` in `tsconfig.json`, TypeScript resolves imports exactly as Node.js 20+ does — including requiring file extensions. Writing `import router from './routes/index'` (no extension) causes `ERR_MODULE_NOT_FOUND` at runtime even though TypeScript compiles it without error.

**Why:** NodeNext resolution does not perform extension probing. Node.js sees `./routes/index` and looks for a file with that exact name — which does not exist. It does not try `./routes/index.js` automatically.

**How to avoid:** All local TypeScript imports on the server must use `.js` extension:
```ts
import router from './routes/index.js'     // ✓
import router from './routes/index'         // ✗ — runtime ERR_MODULE_NOT_FOUND
```
TypeScript knows that `.js` in an import refers to the `.ts` source file during compilation. This is intentional NodeNext behavior.

---

### Pitfall 2: `process.cwd()` depends on where `npm start` is invoked — not where the file lives

**What goes wrong:** `server/src/index.ts` uses `path.join(process.cwd(), '../client/dist')` to locate the built client. If the server is started directly with `node server/dist/index.js` from the project root, `process.cwd()` is the project root and `../client/dist` resolves to the wrong location (one level above the project).

**Why:** `process.cwd()` returns the working directory of the Node.js process — the directory from which `node` was invoked, not the directory where the source file lives. `__dirname` (CommonJS) would give the file's directory, but `__dirname` is not available in ESM — you must use `path.dirname(fileURLToPath(import.meta.url))` instead.

**How to avoid:** The root `package.json` `start` script is `cd server && npm start` — this ensures `process.cwd()` is `server/` when the server runs. Alternatively, use `path.dirname(fileURLToPath(import.meta.url))` to compute paths relative to the source file regardless of CWD.

The implemented solution uses `process.cwd()` with the `cd server` convention. If the server is ever started from a different directory (e.g., CI), this will break. A future hardening would be to switch to `import.meta.url`-based path resolution.

---

### Pitfall 3: Vite proxy default config is NOT safe for SSE — but the fix goes in Express, not Vite

**What goes wrong:** If you set `X-Accel-Buffering: no` in the Vite proxy's `configure` callback (thinking the proxy should opt out of buffering), the header is sent from Vite to the browser — but the issue is actually the proxy buffering the upstream response before forwarding it. The correct fix is to set `X-Accel-Buffering: no` on the Express SSE response, which tells all intermediary proxies (including Vite's http-proxy) not to buffer.

**Why:** `X-Accel-Buffering: no` is a response header that nginx and other proxy layers respect by convention. Vite's underlying `http-proxy` reads this from the upstream (Express) response and disables buffering when it sees it. Setting it only on the proxy-to-browser leg does not affect the Express-to-proxy leg.

**How to avoid:** In the Phase 2 SSE handler, set:
```ts
res.setHeader('X-Accel-Buffering', 'no')
```
This is a Phase 2 task — Phase 1 does not touch SSE. The Phase 1 Vite proxy config uses the minimal configuration and is correct for the health endpoint.

---

### Pitfall 4: `"type": "module"` in `package.json` breaks CommonJS assumptions in config files

**What goes wrong:** With `"type": "module"` in `package.json`, Node.js treats all `.js` files in that package as ESM. Config files like `tailwind.config.js` and `postcss.config.js` that use `module.exports = { ... }` (CommonJS syntax) will throw `ReferenceError: module is not defined`.

**Why:** When `"type": "module"` is set, `.js` files use ESM semantics. `module.exports` is CommonJS — it does not exist in ESM context.

**How to avoid:** Two options:
1. Use `.cjs` extension for config files that use `module.exports` (e.g., `tailwind.config.cjs`)
2. Rewrite config files to use `export default { ... }` (ESM syntax)

The implemented solution uses option 2 — `tailwind.config.js` and `postcss.config.js` use `export default`. Vite handles ESM config files natively.

---

### Pitfall 5: Installing `framer-motion ^12` and `recharts ^3` — these are the required versions

**What goes wrong:** Installing `framer-motion` without a version constraint may pull `framer-motion@10` or `framer-motion@11`, which have different APIs. Similarly, `recharts@2` has a different RadarChart API than `recharts@3`.

**Why:** npm resolves `latest` unless a constraint is given. Major version changes in these packages include breaking API changes.

**How to avoid:** Pin to the major versions specified in ROADMAP.md:
- `framer-motion ^12` — uses the `motion` component from `framer-motion/react` (React 18+ export)
- `recharts ^3` — `ResponsiveContainer` + `RadarChart` API is stable in this range

The Anthropic SDK similarly must be `^0.98.0` — older versions do not have the `client.messages.stream()` API used in Phase 2.

---

### Pitfall 6: React 18 StrictMode double-invokes effects — causes visible double-render in development

**What goes wrong:** In development, React 18 StrictMode intentionally mounts components twice (mount → unmount → remount) to detect side effects. If the `useAnalysis` hook in Phase 3 starts a fetch on mount, it fires twice in dev mode, causing two concurrent requests. The second fires before the `AbortController` from the first cleanup has been registered.

**Why:** StrictMode's double-invoke behavior only happens in development. It's designed to surface missing cleanup in `useEffect`. The `useAnalysis` hook's `submit` function is called on user action (not on mount), so this pitfall does not affect Phase 3's SSE consumer. It does affect any `useEffect` that initiates a network request on mount (e.g., the `?r=` URL decoder in Phase 4 App.tsx — the mount effect only reads from the URL, it does not network, so it is safe).

**How to avoid:** Keep `useEffect` hooks pure — no network calls initiated purely on mount. The Phase 3 SSE hook is driven by user submission, which StrictMode does not double-fire. The Phase 4 URL decoder is read-only on mount and is idempotent.

---

## Existing Patterns in This Codebase

At Phase 1 start, this codebase is greenfield. The patterns established here propagate to all subsequent phases:

- **TypeScript strict mode** — `"strict": true` in both `server/tsconfig.json` and `client/tsconfig.json`. This enforces `noImplicitAny`, `strictNullChecks`, `strictFunctionTypes`, etc.
- **No barrel files** — each module exports what it needs; no `index.ts` re-exports pattern (except `server/src/routes/index.ts` which is a router aggregator, not a barrel)
- **Express Router pattern** — each route group is a `Router()` instance exported as default, mounted in `server/src/routes/index.ts` via `router.use()`
- **ESM side-effect imports** — `import 'dotenv/config'` loads env vars as a side effect; same pattern used for CSS in Vite (`import './index.css'`)

---

## Recommended Approach

**For the monorepo:** Create `server/` and `client/` as independent npm packages first, then wire the root `package.json` scripts last. Running `npm install` in each directory independently before touching the root script verifies each package's dependency graph is clean.

**For TypeScript config:** Use `"module": "NodeNext"` and `"moduleResolution": "NodeNext"` in `server/tsconfig.json`. Use `"target": "ES2020"` or higher — this ensures async/await, nullish coalescing, and optional chaining transpile cleanly. Set `"outDir": "dist"` and `"rootDir": "src"`.

**For the health endpoint:** Return `{ status, timestamp, uptime }` only — do not expose model name or Node.js version in v1.0 (security concern noted in Phase 4 SECURITY.md, T-09).

**For verification:** Run `curl http://localhost:3001/api/health` from within the server's `npm run dev` process. Then open `localhost:5173` in a browser and verify the React app loads without a white screen and that the Vite proxy forwards `/api/health` correctly (check the browser Network tab).
