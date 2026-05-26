# UAT Report — Chispa v1.0

**Date:** 2026-05-26
**Scope:** 26 v1 requirements verified against codebase (no running browser)
**Method:** Static code analysis — file reads and grep across `/home/user/learnship/chispa/`

---

## Summary Table

| Req | Status | Evidence |
|-----|--------|----------|
| INFRA-01 | PASS | `package.json` root `dev` script: `concurrently "npm run dev:server" "npm run dev:client"` — single command starts both processes |
| INFRA-02 | PASS | `server/src/index.ts` listens on `PORT ?? 3001`; `client/vite.config.ts` proxies `/api` → `http://localhost:3001` with SSE-safe headers (`Connection: keep-alive`) |
| INFRA-03 | PASS | Root `build` script: `cd client && npm run build && cd ../server && npm run build`; `start` script: `cd server && npm start` → `node dist/index.js`; `client/dist/` and `server/dist/` both exist |
| INFRA-04 | PASS | `server/src/routes/index.ts` line 6: `router.get('/api/health', ...)` returns `{ status: 'ok', timestamp, uptime }` |
| ANLYS-01 | FAIL | Form textarea enforces 20–500 chars (both client `IdeaForm.tsx` and server `analyze.ts`); `REQUIREMENTS.md` specifies **max 2000 chars**. Implementation uses 500 consistently but contradicts the written requirement. Country select and submit button are present. |
| ANLYS-02 | PASS | `server/src/agent/analyzer.ts` line 60: `tools: [{ type: 'web_search_20250305', name: 'web_search' }]` |
| ANLYS-03 | FAIL | Structured JSON output matches most fields (`competitors[]`, `marketSize`, `marketGrowth`, `marketTiming`, `risks[]`, `verdict`, `verdictReason`, `firstSteps[]`, `searchedAt`). However, `REQUIREMENTS.md` specifies `competitors[].positioning` but the `Competitor` interface has `name, description, funding, founded, website` — **no `positioning` field** in type, prompt, or UI. |
| ANLYS-04 | PASS | 90s Anthropic client timeout (`new Anthropic({ timeout: 90_000 })`) ensures completion well within 120s limit |
| ANLYS-05 | PASS | No `ANTHROPIC_API_KEY` references in `client/src/` or in compiled `client/dist/assets/index-CkPpbNeN.js`; all Claude calls are in `server/src/agent/analyzer.ts` |
| STRM-01 | PASS | `server/src/routes/analyze.ts` lines 29–33: sets `Content-Type: text/event-stream`, `Cache-Control: no-cache`, `Connection: keep-alive`, `X-Accel-Buffering: no`, then calls `res.flushHeaders()` |
| STRM-02 | PASS | `STEP_TEXTS` array in `analyzer.ts` lines 38–43: `['Buscando competidores directos...', 'Analizando el mercado...', 'Revisando actividad de inversión...', 'Sintetizando resultados...']`; emitted on each `content_block_start` tool call |
| STRM-03 | PASS | `client/src/components/ActivityFeed.tsx` renders steps list with per-item Framer Motion `opacity/x` entrance animation; auto-scrolls to bottom via `useRef` |
| STRM-04 | PASS | `analyzer.ts` line 105: `yield { type: 'result', data: result }` after successful `JSON.parse` |
| STRM-05 | PASS | `analyzer.ts` lines 106–111: outer `catch` yields `{ type: 'error', message }`. `analyze.ts` lines 39–43: additional outer `catch` sends error SSE; `finally` block always calls `res.end()` — server does not crash |
| SAFE-01 | PASS | `analyze.ts` line 6: `const MAX_CONCURRENT = 3`; lines 23–26: `if (activeAnalyses >= MAX_CONCURRENT)` returns `res.status(429).json(...)` |
| SAFE-02 | PASS | `analyze.ts` lines 44–46: `finally { activeAnalyses--; res.end() }` — counter decremented on both success and error paths |
| SAFE-03 | PASS | `analyzer.ts` line 4: `const client = new Anthropic({ timeout: 90_000 })` |
| DASH-01 | PASS | `Dashboard.tsx` is a `motion.div` with `initial={{ y: 40, opacity: 0 }}`, `animate={{ y: 0, opacity: 1 }}`, `transition={{ duration: 0.5, ease: 'easeOut' }}` |
| DASH-02 | PASS | `RiskRadarChart.tsx`: imports `RadarChart`, `PolarAngleAxis` from recharts; `AXES = ['Mercado', 'Competencia', 'Técnico', 'Regulatorio', 'Timing', 'Capital']` — exactly 6 axes; `Radar isAnimationActive={true}` |
| DASH-03 | FAIL | `CompetitorCard.tsx` renders `name` and `description` (and optional `funding` badge). Requirement specifies **name, description, and positioning**. No `positioning` field exists in the `Competitor` type or UI. |
| DASH-04 | PASS | `VerdictCard.tsx` has `VERDICT_CONFIG` map for all 4 verdicts with distinct `color` and `bg` values; Framer Motion `rotateX` flip-in animation |
| DASH-05 | PASS | `MarketSnapshot.tsx` renders `marketSize`, `marketGrowth`, and `marketTiming` as a colored badge (too_early / right_time / too_late) |
| DASH-06 | PASS | `FirstSteps.tsx` renders up to 5 steps (`firstSteps.slice(0, 5)`); prompt enforces `EXACTAMENTE 5 elementos`; shown for LAUNCH/VALIDATE only (requirement says minimum 3) |
| SHARE-01 | FAIL | Requirement: "URL updates to `/?r=<base64-encoded-result>` **after analysis completes**". Implementation: URL only updates when the user **clicks the ShareButton** (`window.history.pushState` is inside `handleShare()`). No automatic URL push on analysis completion. |
| SHARE-02 | PASS | `App.tsx` `useEffect` (lines 18–39): reads `?r=` param on mount, decompresses with `lzstring.decompressFromEncodedURIComponent`, parses JSON, sets `urlResult` → renders dashboard immediately without re-analysis |
| SHARE-03 | PASS | `App.tsx` lines 23–38: `try/catch` around decompression and `JSON.parse`; shape validation (`!parsed.verdict || !parsed.competitors || !parsed.risks`); on failure sets `urlLoadError` state and clears the bad URL with `replaceState('/', ...)` — no crash |

---

## Results

| | Count |
|---|---|
| **PASS** | **22** |
| **FAIL** | **4** |
| **Total** | **26** |

---

## FAIL Items — Specific Gaps

### ANLYS-01 — Char limit mismatch (implementation vs. requirement)
- **Requirement:** "textarea, max 2000 chars" (`REQUIREMENTS.md` line 17)
- **Implementation:** `IdeaForm.tsx` enforces `maxLength={500}` and client-side validation `> 500`; `analyze.ts` server-side rejects `idea.length > 500`
- **Gap:** Written requirement says 2000; all code enforces 500. The 500-char limit appears intentional (it appears in the system prompt example and verify-work spec), but contradicts `REQUIREMENTS.md`.
- **Recommended fix:** Update `REQUIREMENTS.md` ANLYS-01 to say "max 500 chars" to match the implementation.

### ANLYS-03 / DASH-03 — `positioning` field missing from data model and UI
- **Requirement (ANLYS-03):** `competitors[]` schema specified in `REQUIREMENTS.md` doesn't list fields explicitly, but `DASH-03` says "name, description, and **positioning**"
- **Requirement (DASH-03):** "competitor cards with name, description, and positioning for each competitor found"
- **Implementation:** `Competitor` interface has `{ name, description, funding?, founded?, website? }` — no `positioning` field. `CompetitorCard.tsx` renders name, description, and funding badge — no positioning.
- **Gap:** The `positioning` field is fully absent from type definition, Claude prompt, and dashboard UI. `funding` is shown instead.
- **Recommended fix:** Either add a `positioning` field to the `Competitor` type and prompt and render it in `CompetitorCard.tsx`, or update the requirement to replace "positioning" with "funding" to match the actual implementation.

### SHARE-01 — URL not auto-updated after analysis; requires user action
- **Requirement:** "After analysis completes, the URL updates to `/?r=<base64-encoded-result>` without a page reload"
- **Implementation:** URL is only updated when the user explicitly clicks the "Compartir análisis" (`ShareButton`) button. `App.tsx` has no `useEffect` that pushes the URL on state transition to `complete`.
- **Gap:** The URL does NOT update automatically — the user must click Share. Loading the app fresh (SHARE-02) works correctly once the URL is updated by the user. For demo purposes this may be acceptable, but it does not satisfy the stated requirement.
- **Recommended fix:** Add a `useEffect` in `App.tsx` that calls `lzstring.compressToEncodedURIComponent` + `pushState` when `displayState === 'complete' && displayResult !== null`, or update the requirement to say "URL updates when user clicks Share."

---

*UAT completed: 2026-05-26*
*Analyst: verify-work workflow (static code analysis)*
