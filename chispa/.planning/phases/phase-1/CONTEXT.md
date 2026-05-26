# Phase 1: Foundation — Context

## Phase Goal

Establish a working monorepo where `npm run dev` starts both Express (port 3001) and Vite (port 5173) with a single command, the health endpoint responds, shared TypeScript types are defined, and the Anthropic SDK is installed and ready.

## Requirements Covered

- INFRA-01 — Single `npm run dev` command
- INFRA-02 — Port 3001 (Express) + Vite proxy routing `/api/*`
- INFRA-04 — `/api/health` endpoint

## Key Decisions

### Ports
- Express runs on **3001**; Vite dev server on **5173**
- Vite proxies `/api/*` to `http://localhost:3001` via `vite.config.ts`
- Production: Express serves client `dist/` statically; only port 3001 needed

### ESM throughout
- Both `server/package.json` and `client/package.json` set `"type": "module"`
- Server `tsconfig.json` uses `"module": "NodeNext"` and `"moduleResolution": "NodeNext"`
- All server imports use `.js` extensions (NodeNext requirement)

### `tsx` instead of `ts-node`
- `tsx` used as the TypeScript executor for `nodemon` — avoids ESM loader bugs present in `ts-node` on Node 20+
- `nodemon.json` runs `tsx src/index.ts`; `concurrently` drives both servers from the root `package.json`

### Shared types defined here (not in a shared package)
- `AnalysisResult`, `Competitor`, `Risk`, `SSEMessage` are defined at:
  - `server/src/types/analysis.ts`
  - `client/src/types/analysis.ts`
- Both files are identical — no symlink or shared package to keep the setup simple
- **Phase 2 contract**: these types are the SSE wire format; do not change the shape without updating both files

### Anthropic SDK version pinned at install time
- `@anthropic-ai/sdk ^0.30.0` installed in `server/` — Phase 2 will use `web_search_20250305` tool
- Note: roadmap targets `^0.98` upgrade before Phase 2 work begins (check latest before Phase 2 planning)

### `concurrently` at root
- Root `package.json` has `concurrently` as a devDependency
- `npm run dev` → `concurrently "npm run dev:server" "npm run dev:client"`

## Outputs Produced

| Artifact | Location |
|----------|----------|
| Express server entry | `server/src/index.ts` |
| Route definitions | `server/src/routes/index.ts` |
| Health endpoint | `GET /api/health` → `{"status":"ok","model":"claude-opus-4-7","timestamp":"..."}` |
| Stub analyze endpoint | `POST /api/analyze` → 501 (Phase 2 placeholder) |
| Server types | `server/src/types/analysis.ts` |
| Client types | `client/src/types/analysis.ts` |
| Vite config with proxy | `client/vite.config.ts` |
| Root dev script | `package.json` `dev` script |

## What Phase 2 Needs to Know

1. **Route file is `server/src/routes/index.ts`** — replace the 501 stub `POST /api/analyze` with the real SSE handler.
2. **Types are the SSE contract** — `SSEMessage` union (`step | result | error | ping`) defines the wire format; the client will parse these in Phase 3.
3. **SSE pitfall**: Vite proxy is NOT configured with `X-Accel-Buffering: no` yet — add this header in the SSE handler (`res.setHeader('X-Accel-Buffering', 'no')`) before Phase 2 integration testing.
4. **`res.flushHeaders()` must fire before any `await`** in the SSE handler — do not await the Anthropic client construction first.
5. **Concurrency counter** must be a module-level synchronous integer, not async — in-memory, no Redis needed for Phase 2.
6. **Node version**: Node 20+ (ESM strict mode); keep `.js` extensions on all server imports.

## Constraints

- No database — all state is either in-memory (concurrency counter) or URL-encoded (Phase 4)
- No auth — demo app, open endpoints
- Deployment target undecided — must be resolved before Phase 4 (shareable URLs require a stable hostname)
