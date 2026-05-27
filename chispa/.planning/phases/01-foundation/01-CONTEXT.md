# Phase 1: Foundation — Context

**Gathered:** 2026-05-26
**Mode:** autonomous (all decisions pre-answered)
**Status:** Complete

<domain>
## Phase Boundary

Establish a working monorepo where `npm run dev` starts both Express (port 3001) and Vite (port 5173) with a single command. The health endpoint responds. Shared TypeScript types (`AnalysisResult`, `SSEMessage`) are defined and form the Phase 2 SSE contract. The Anthropic SDK is installed and importable. No analysis logic yet — POST /api/analyze returns a 501 stub.

</domain>

<decisions>
## Implementation Decisions

### Monorepo Structure
- Root `package.json` owns only the dev orchestration script (`concurrently`) and build orchestration
- `server/` is its own npm workspace with its own `package.json`, `tsconfig.json`, `nodemon.json`
- `client/` is its own npm workspace with its own `package.json`, `tsconfig.json`, `vite.config.ts`
- No symlinks, no shared package, no Turborepo — simple `cd server && ...` in root scripts

### Port Assignment
- Express: **3001**
- Vite dev server: **5173** (default)
- Vite proxies `/api/*` → `http://localhost:3001` via `server.proxy` in `vite.config.ts`
- Production: Express serves `client/dist/` statically from `path.join(process.cwd(), '../client/dist')` (CWD is `server/` when `npm start` runs)

### TypeScript Runtime: `tsx` not `ts-node`
- `tsx` used as the TypeScript executor for `nodemon` — avoids ESM loader bugs present in `ts-node` on Node 20+
- `nodemon.json` at `server/nodemon.json`: `{ "watch": ["src"], "ext": "ts", "exec": "tsx src/index.ts" }`
- `server/package.json` `dev` script: `nodemon` (reads `nodemon.json`)

### ESM Throughout
- Both `server/package.json` and `client/package.json` set `"type": "module"`
- Server `tsconfig.json`: `"module": "NodeNext"`, `"moduleResolution": "NodeNext"`
- All server TypeScript imports use `.js` extensions even on `.ts` source files (NodeNext requirement)
- Missing `.js` on local imports causes `ERR_MODULE_NOT_FOUND` at runtime

### Shared Types Strategy
- `AnalysisResult`, `Competitor`, `Risk`, `SSEMessage` defined identically in two files:
  - `server/src/types/analysis.ts`
  - `client/src/types/analysis.ts`
- No symlink or shared npm package — duplication accepted to keep setup simple
- **Invariant:** both files must stay identical for the SSE wire format to be consistent

### Dev Orchestration
- Root `package.json` has `concurrently` as a devDependency
- `npm run dev` → `concurrently "npm run dev:server" "npm run dev:client"`
- `dev:server` → `cd server && npm run dev` (runs nodemon via tsx)
- `dev:client` → `cd client && npm run dev` (runs vite)
- `build` → `cd client && npm run build && cd ../server && npm run build`
- `start` → `cd server && npm start` → `node dist/index.js` (production)

### Anthropic SDK
- Installed in `server/` as `@anthropic-ai/sdk ^0.98.0`
- Imported as `import Anthropic from '@anthropic-ai/sdk'` in Phase 2 work
- API key: `ANTHROPIC_API_KEY` in `server/.env` (loaded via `import 'dotenv/config'` as the first line of `server/src/index.ts`)
- Client never receives or imports the SDK

### Tailwind CSS
- Installed in `client/` as `tailwindcss ^3.4.x` with `postcss` and `autoprefixer`
- `client/tailwind.config.js` defines dark theme: `#0a0a0f` background, `#7c3aed` purple accent
- Configured via `client/postcss.config.js`
- `client/src/index.css` includes `@tailwind base/components/utilities`

### Health Endpoint
- `GET /api/health` → `{ "status": "ok", "timestamp": "...", "uptime": N }`
- Note: initial implementation included `model`, `version`, `nodeVersion` fields — these were later removed in Phase 4 (security audit T-09) to prevent stack fingerprinting

### 501 Stub
- `POST /api/analyze` returns `501 Not Implemented` in Phase 1
- This is the Phase 2 integration point — Phase 2 replaces the entire stub handler

</decisions>

<specifics>
## Specific Ideas

- Tailwind custom colours live in `tailwind.config.js` under `theme.extend.colors` — keys `background`, `surface`, `border`, `primary`, `primary-light` are used throughout the UI
- The Vite proxy config at `client/vite.config.ts` uses `server.proxy` — the Phase 2 SSE pitfall with buffering is handled in the Express handler (`X-Accel-Buffering: no`), not here
- `server/src/index.ts` adds `cors()`, `express.json()`, static serving, the router, 404 handler, and global error handler
- `framer-motion ^12` and `recharts ^3` installed in `client/` at Phase 1 — these are the Phase 3 animation and chart packages
- `lz-string` installed in `client/` at Phase 1 — used in Phase 4 for URL compression

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `server/src/types/analysis.ts` — canonical type definitions; import from `'../types/analysis.js'` in server routes
- `client/src/types/analysis.ts` — client-side copy; must stay identical to server types
- `.planning/ROADMAP.md` Phase 1 section — requirements covered: INFRA-01, INFRA-02, INFRA-04
- `.planning/REQUIREMENTS.md` — full requirement definitions

</canonical_refs>

<code_context>
## Existing Code Insights

### Key Files Produced by This Phase

| File | Purpose |
|------|---------|
| `server/src/index.ts` | Entry point: dotenv, cors, json middleware, static serving, router mount |
| `server/src/routes/index.ts` | Health endpoint + 501 analyze stub |
| `server/src/types/analysis.ts` | AnalysisResult, Competitor, Risk, SSEMessage types |
| `client/src/types/analysis.ts` | Identical copy for the React client |
| `client/vite.config.ts` | Vite config with `/api/*` proxy to port 3001 |
| `server/nodemon.json` | Nodemon config: watch `src/`, exec via `tsx` |
| `server/.env.example` | Template: `ANTHROPIC_API_KEY=your_key_here` |

### Patterns Established for Downstream Phases

- ESM imports with `.js` extensions everywhere in `server/src/`
- `catch (err: unknown)` + `err instanceof Error ? err.message : String(err)` pattern (TypeScript strict)
- `import 'dotenv/config'` as the first line of `server/src/index.ts` — env vars available at route handler time
- Express 4.x `Router()` pattern — `router.get(...)`, `router.post(...)`, `export default router`
- React component files are `.tsx`; pure TypeScript files are `.ts`

### Integration Point for Phase 2

`server/src/routes/index.ts` line 13–15 contains the 501 stub. Phase 2 removes this and imports `analyzeRouter` from `./analyze.js`.

</code_context>

<deferred>
## Deferred Ideas

- WebSocket alternative to SSE (deferred indefinitely — SSE covers the use case with less complexity)
- Shared npm package for types (deferred — duplication acceptable for a demo project)
- Docker/containerization (deferred — out of scope for v1.0 demo)

</deferred>

---
*Phase: 01-foundation*
*Context gathered: 2026-05-26*
