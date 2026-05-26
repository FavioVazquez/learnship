# Roadmap: Chispa

**Milestone:** v1.0 — Demo-Ready for AI Week Summit Guatemala 2026
**Total phases:** 4
**Total v1 requirements:** 26
**Coverage:** 26/26 ✓

---

## Phase 1 — Foundation

**Goal:** A working monorepo where `npm run dev` starts both Express and Vite, the health endpoint responds, and the Anthropic SDK is imported and authenticated.

**Requirements covered:** INFRA-01, INFRA-02, INFRA-04

**Success criteria:**
- After this phase, `npm run dev` starts both processes with a single command
- After this phase, `curl localhost:3001/api/health` returns `{"status":"ok"}`
- After this phase, the React app renders at localhost:5173 with the Vite proxy routing `/api/*` to Express
- After this phase, `new Anthropic()` constructs without error in the server (API key loaded from `.env`)
- After this phase, all three mandatory package upgrades are applied (@anthropic-ai/sdk ^0.98, recharts ^3, framer-motion ^12)

**Notes from research:**
- Shared TypeScript types (`AnalysisResult`, `SSEMessage`) must be defined here — they are the Phase 2/3 contract
- Vite proxy must be configured for SSE (default config is not SSE-safe; add `X-Accel-Buffering: no`)
- Use `tsx` not `ts-node` for server execution (ts-node has ESM bugs on Node 20+)
- Use `concurrently` for running both dev servers

---

## Phase 2 — Analysis Engine

**Goal:** `POST /api/analyze` streams a complete Claude analysis via SSE, verified with `curl -N`. No frontend yet.

**Requirements covered:** ANLYS-02, ANLYS-03, ANLYS-04, ANLYS-05, STRM-01, STRM-02, STRM-04, STRM-05, SAFE-01, SAFE-02, SAFE-03

**Success criteria:**
- After this phase, `curl -N -X POST -d '{"idea":"..."}' localhost:3001/api/analyze` streams SSE events to the terminal
- After this phase, each Claude tool call produces a `step` SSE event with a human-readable Spanish message
- After this phase, the stream ends with a `result` SSE event containing valid `AnalysisResult` JSON
- After this phase, a 4th concurrent request receives a 429 response immediately
- After this phase, an Anthropic API error produces an `error` SSE event (not a server crash)

**Notes from research (critical pitfall prevention):**
- Tool_use JSON must be accumulated into a buffer; `JSON.parse()` only on `content_block_stop` — NOT on `input_json_delta`
- Set `timeout: 90_000` on Anthropic SDK client constructor before concurrency testing
- `res.flushHeaders()` must fire before any `await` call in the SSE handler
- In-memory counter must use synchronous check-and-increment; `try/finally` guarantees decrement
- LatAm competitor search instruction must be in the prompt at this phase (not deferred to Phase 3)

---

## Phase 3 — Web Frontend ✓ Complete (2026-05-26)

**Goal:** A complete, animated browser UI — form → live activity feed → animated dashboard.

**Requirements covered:** ANLYS-01, STRM-03, DASH-01, DASH-02, DASH-03, DASH-04, DASH-05, DASH-06

**Success criteria:**
- After this phase, user submits an idea in the form and sees a live activity feed of Claude's tool calls
- After this phase, when analysis completes, the dashboard animates in (Framer Motion transitions)
- After this phase, the radar chart renders with 6 axes and animates on mount (Recharts RadarChart)
- After this phase, competitor cards display with name, description, and positioning for each competitor
- After this phase, the verdict card (LAUNCH/VALIDATE/PIVOT/AVOID) is color-coded and visually dominant
- After this phase, the market snapshot and first steps sections render correctly

**Notes from research:**
- Build the `fetch` + `ReadableStream` SSE consumer BEFORE any UI components — it is the foundation
- Use `AbortController` in `useEffect` cleanup to prevent connection leaks on unmount
- Build the state machine (idle → loading → streaming → complete → error) before individual components
- Build RadarChart with mock data first, then wire to live results
- Dark theme: `#0a0a0f` background, `#7c3aed` purple accent throughout

---

## Phase 4 — Polish & Demo Prep ✓ Complete (2026-05-26)

**Goal:** Production build runs, README is complete, deployment target confirmed.

**Requirements covered:** INFRA-03, SHARE-01*, SHARE-02*, SHARE-03*

> *SHARE-01/02/03 were pulled forward into Phase 3 (Plan 05) by explicit user decision — ShareButton + ?r= URL loader are already implemented. Phase 4 must NOT re-implement these.

**Success criteria:**
- After this phase, completing an analysis updates the URL to `/?r=<encoded>` without page reload
- After this phase, loading `/?r=<encoded>` in a new tab renders the dashboard instantly (no re-analysis)
- After this phase, a corrupt `?r=` param shows a graceful error message (not a crash)
- After this phase, `npm run build && npm start` serves the production app on port 3001
- After this phase, the README has setup instructions, env variable documentation, and a demo script

**Notes from research:**
- Use `lz-string` compression before base64 encoding (Claude web search output can exceed nginx's 8KB header limit)
- Pattern: `lzstring.compressToEncodedURIComponent(JSON.stringify(result))` → URL; reverse on load
- Test shareable URL load with both valid and malformed base64 before demo day
- Verify `res.flushHeaders()` works behind production proxy (not just Vite dev proxy)
- Decide deployment target before this phase (localhost = shareable URLs don't work across devices at the conference)

---

## Requirement → Phase Mapping

| Req | Phase | Description |
|-----|-------|-------------|
| INFRA-01 | 1 | Single `npm run dev` command |
| INFRA-02 | 1 | Port 3001 + Vite proxy |
| INFRA-04 | 1 | `/api/health` endpoint |
| ANLYS-02 | 2 | Claude with web_search_20250305 |
| ANLYS-03 | 2 | Structured JSON output |
| ANLYS-04 | 2 | <120 second analysis |
| ANLYS-05 | 2 | API key never exposed |
| STRM-01 | 2 | SSE from server |
| STRM-02 | 2 | Human-readable activity messages |
| STRM-04 | 2 | `result` SSE event |
| STRM-05 | 2 | `error` SSE event (never crash) |
| SAFE-01 | 2 | Max 3 concurrent (429 on 4th) |
| SAFE-02 | 2 | Counter always decremented |
| SAFE-03 | 2 | 90s timeout on Anthropic client |
| ANLYS-01 | 3 | Idea submission form |
| STRM-03 | 3 | Live activity feed in browser |
| DASH-01 | 3 | Animated transition to dashboard |
| DASH-02 | 3 | Radar chart (6 axes) |
| DASH-03 | 3 | Competitor cards |
| DASH-04 | 3 | Verdict card |
| DASH-05 | 3 | Market snapshot |
| DASH-06 | 3 | First steps list |
| INFRA-03 | 4 | Production build |
| SHARE-01 | 4 | URL update after analysis |
| SHARE-02 | 4 | Load dashboard from `?r=` |
| SHARE-03 | 4 | Graceful error on corrupt URL |

**Coverage: 26/26 ✓**

---
*Roadmap created: 2026-05-26*
