# Phase 1: Foundation — Discussion Log

**Date:** 2026-05-26
**Mode:** autonomous (all decisions pre-answered by user)
**Facilitator:** Claude (learnship discuss-phase workflow)

---

## Areas Covered

### 1. Monorepo Structure

**Options considered:**
- Yarn/npm workspaces with hoisted dependencies (rejected — adds complexity for a two-package project)
- Turborepo (rejected — overkill for a demo; adds a dependency that would confuse workshop attendees)
- Single flat package with both server and client src (rejected — mixes concerns, complicates build)
- Simple nested packages with root orchestration scripts (selected)

**Decision:** Two independent packages (`server/`, `client/`) orchestrated from a root `package.json` via `concurrently`. Each has its own `npm install`.

**Rationale:** Maximum clarity for a live workshop demo. Anyone cloning the repo can understand the layout without knowing Turborepo or workspace hoisting rules. The cost is three `npm install` calls instead of one.

---

### 2. TypeScript Runtime for Server Development

**Options considered:**
- `ts-node` with `--esm` flag (rejected — known ESM loader bugs on Node 20+; intermittent `ERR_UNKNOWN_FILE_EXTENSION` errors)
- `tsc --watch` + `node dist/` (rejected — build step in dev loop adds latency and noise)
- `tsx` with `nodemon` (selected)
- `ts-node-dev` (rejected — same underlying issues as ts-node on Node 20+)

**Decision:** `tsx` as the TypeScript executor inside `nodemon`. `nodemon.json` at `server/nodemon.json` watches `src/**/*.ts` and runs `tsx src/index.ts` on changes.

**Rationale:** `tsx` uses esbuild under the hood — it handles ESM natively on Node 20+ without the loader flag ceremony. `nodemon` provides file-watching with clear restart output. Combined, they give a dev experience equivalent to `ts-node-dev` without the stability issues.

---

### 3. ESM vs CommonJS

**Options considered:**
- CommonJS (`"type": "commonjs"`, `require()`) — would work but creates a mismatch with Vite and modern React tooling
- ESM (`"type": "module"`, `import/export`) with NodeNext resolution (selected)
- Dual CJS/ESM build (rejected — unnecessary complexity)

**Decision:** ESM throughout. Both `server/package.json` and `client/package.json` set `"type": "module"`. Server `tsconfig.json` uses `"module": "NodeNext"`.

**Rationale:** The project targets Node 20+ and modern browsers. ESM is the right default. The only gotcha is the `.js` extension requirement on local TypeScript imports under `NodeNext` resolution — this is documented in CONTEXT.md and captured in RESEARCH.md.

---

### 4. Shared Types Strategy

**Options considered:**
- npm workspace with a `@chispa/types` package (rejected — adds `npm install` complexity and a third package to explain in the workshop)
- Symlink from `client/src/types` to `server/src/types` (rejected — symlinks break on Windows and inside some Docker setups)
- Identical copy in both packages (selected)
- Runtime package from a CDN (rejected — adds network dependency, no TypeScript types)

**Decision:** Identical `analysis.ts` in `server/src/types/` and `client/src/types/`. Both are hand-maintained. The Phase 2 contract is: the `SSEMessage` union type defines the SSE wire format.

**Rationale:** Two identical small files is the lowest-friction option for a workshop demo. The risk of drift is low for a v1.0 project. A comment in both files notes they must stay in sync.

---

### 5. Frontend Dependencies at Phase 1

**Options considered:**
- Install only React basics now, add Framer Motion / Recharts / lz-string in the phases that need them (rejected — causes npm install during live workshop demo)
- Install all client dependencies upfront (selected)

**Decision:** Install `framer-motion ^12`, `recharts ^3`, `lz-string` in `client/` at Phase 1 alongside React and Tailwind. The Phase 3 and Phase 4 executors can import them immediately without an install step.

**Rationale:** Avoids `npm install` during the execute-phase live coding portion of the workshop. The tradeoff is slightly more dependencies than strictly needed at Phase 1, but there is no downside to having them installed early.

---

### 6. Vite Proxy Configuration

**Options considered:**
- Configure `X-Accel-Buffering: no` in the Vite proxy `configure` callback (considered but deferred)
- Set the header in the Express SSE handler (selected — decided in Phase 2 discussion)

**Decision at Phase 1:** Vite proxy uses the minimal config: `target: 'http://localhost:3001'`, `changeOrigin: true`. The SSE buffering header will be set server-side in Phase 2.

**Rationale:** The Phase 1 scope is infrastructure, not SSE. The proxy is verified working for the health endpoint. The SSE-specific header is better placed in the response handler anyway — it travels with the response, not the proxy config.

---

### 7. Production Static Serving

**Options considered:**
- Separate Nginx to serve `client/dist/` (rejected — requires nginx config, complex for demo deployment)
- `express.static()` serving `client/dist/` from within the Express server (selected)
- Serve client via a separate CDN (rejected — out of scope for v1.0)

**Decision:** `express.static(path.join(process.cwd(), '../client/dist'))` in `server/src/index.ts`. When `npm start` is run via `cd server && npm start`, `process.cwd()` is `server/`, so `../client/dist` resolves to the correct path.

**Rationale:** Single-port production deployment (`localhost:3001` serves everything). Simplest possible demo setup — no reverse proxy needed.

---

## Areas Delegated to Agent's Discretion

- Exact Tailwind CSS configuration beyond the required colour tokens
- Whether to use `helmet` middleware for security headers (added in Phase 4 scope if needed)
- React router vs single-page with manual URL management (Phase 3 decision)
- Exact `index.html` content and favicon

---

## Deferred Ideas

- WebSocket as an alternative real-time transport (deferred to Phase 2 discussion — SSE is sufficient)
- Shared TypeScript package via npm workspaces (deferred — acceptable duplication for demo scope)
- Docker setup for reproducible deployment (deferred — out of v1.0 scope)

---

*This log is for human audit only. Downstream agents read 01-CONTEXT.md, not this file.*
