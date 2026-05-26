# Phase 1: Foundation — Plan

**Goal:** Running Express + React monorepo — `npm run dev` starts both servers, `/api/health` responds, shared types defined, Anthropic SDK installed.

**Requirements:** INFRA-01, INFRA-02, INFRA-04

**Status: COMPLETE**

---

## Wave 1 — Parallel scaffolding

- [x] **Server scaffolding** — `server/` with Express, TypeScript (NodeNext ESM), `tsx`+`nodemon` dev runner, `cors`, `dotenv`, health route stub, error middleware
- [x] **Client scaffolding** — `client/` with React 18, Vite 5, Tailwind CSS, TypeScript, `@vitejs/plugin-react`, proxy config pointing `/api/*` → `localhost:3001`

## Wave 2 — Parallel setup

- [x] **npm installs** — `server/` deps (`@anthropic-ai/sdk`, `express`, `cors`, `dotenv`) and devDeps (`tsx`, `nodemon`, `typescript`, `@types/*`); `client/` deps (`react`, `react-dom`, `framer-motion`, `recharts`, `lucide-react`) and devDeps; root `concurrently`
- [x] **Shared types** — `AnalysisResult`, `Competitor`, `Risk`, `SSEMessage` defined identically in `server/src/types/analysis.ts` and `client/src/types/analysis.ts`

## Wave 3 — Integration

- [x] **Root dev script** — `package.json` `dev` runs `concurrently "npm run dev:server" "npm run dev:client"`
- [x] **Health endpoint** — `GET /api/health` returns `{"status":"ok","model":"claude-opus-4-7","timestamp":"..."}` on port 3001
- [x] **Analyze stub** — `POST /api/analyze` returns 501 (Phase 2 placeholder)
- [x] **TypeScript checks pass** — `npm run typecheck` clean in both `server/` and `client/`
- [x] **Vite proxy verified** — React app renders at localhost:5173; `/api/health` reachable through Vite proxy

---

*Phase completed: 2026-05-26*
