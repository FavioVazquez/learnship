# Phase 4: Polish & Demo Prep - Context

**Gathered:** 2026-05-26
**Mode:** autonomous (all decisions pre-answered)
**Status:** Ready for planning

<domain>
## Phase Boundary

Shareable URL error handling, graceful error states for all failure modes, production build that serves the SPA, enhanced health endpoint, mobile responsiveness, and empty/partial-data states. This phase makes the app demo-safe — no crashes, no blank screens, no unhandled failures.

Note: ShareButton (lz-string encoding + URL update) was pulled into Phase 3. Phase 4 owns the error handling for corrupt `?r=` params and any unfinished shareable URL work.

</domain>

<decisions>
## Implementation Decisions

### Shareable URL Error Handling
If Phase 3 left any shareable URL work incomplete:
- Install in client: `npm install lz-string @types/lz-string` (if not already done)
- Encode: `lzstring.compressToEncodedURIComponent(JSON.stringify(result))`
- Decode on load: `lzstring.decompressFromEncodedURIComponent(param)`
- Error handling for corrupt `?r=` param: catch any exception from decode/parse, show "Enlace inválido" message, reset app to idle state (do NOT crash or show blank screen)

### Error States (All Four Must Be Handled)

**Network failure** (fetch throws — e.g., server unreachable, CORS, DNS failure):
- Message: "Error de conexión. Intenta de nuevo."
- Show retry button that resets to idle state

**Claude timeout** (analysis takes >120s — server sends error SSE with timeout message):
- Message: "El análisis tardó demasiado. Intenta con una idea más específica."
- No retry button (user should refine their idea)

**JSON parse error on result** (Claude returns malformed JSON in the result SSE event):
- Message: "Análisis incompleto. Los datos no están en el formato esperado."
- Show partial results if any data is available; full error card if nothing is parseable

**429 response** (server returns 429 before SSE starts):
- Message: "Demasiados análisis en curso. Espera un momento e intenta de nuevo."
- Show retry button

### Production Build
Current state: `server/src/index.ts` already serves `client/dist/` as static. The catch-all returns a 404 JSON response — this must become an SPA catch-all serving `index.html`.

Changes required:
- `server/src/index.ts`: Replace the 404 catch-all with `res.sendFile(path.join(__dirname, '../../client/dist/index.html'))` — only for non-API routes (routes starting with `/api/` keep JSON 404)
- `npm run build`: Already wired — `cd client && npm run build` then `cd ../server && npm run build`
- `npm start`: Already wired — `cd server && npm start` (runs `node dist/src/index.js`)
- Verify: `npm run build && npm start` → `curl localhost:3001` returns HTML (not JSON 404)

No `NODE_ENV` gate needed — serving `client/dist/` is already unconditional.

### Enhanced `/api/health`
Current response: `{ status, model, timestamp }`
Add to response:
- `uptime: process.uptime()` — seconds since process started
- `version: "1.0.0"` — hardcoded string
- `nodeVersion: process.version` — e.g., "v20.x.x"

### Mobile Responsiveness
Use Tailwind responsive prefixes throughout client components. Key breakpoints:
- Default (mobile-first): single column, full-width cards, smaller text
- `sm:` (640px+): wider padding, 2-column competitor grid where appropriate
- `md:` (768px+): larger typography for verdict, wider radar chart container
- `lg:` (1024px+): max-width container centered on desktop

No new components needed — apply responsive classes to existing component markup.

### Empty State: No Competitors Found
If `AnalysisResult.competitors` is an empty array:
- Show a card with Spanish message: "No se encontraron competidores directos — eso puede ser una ventaja."
- Do not render `CompetitorCard` list (avoid empty sections)
- Show this inside the Dashboard component where the competitor list would appear

### Smooth Scroll to Results
After analysis completes and Dashboard mounts:
- `useEffect` in Dashboard with `[state]` dependency — when state transitions to `"complete"`, call `window.scrollTo({ top: 0, behavior: 'smooth' })` or scroll to the dashboard container ref
- Simple implementation: `dashboardRef.current?.scrollIntoView({ behavior: 'smooth' })`

### Agent's Discretion
- Exact timing/easing of the scroll behavior
- Whether to debounce the scroll call
- Exact layout proportions for mobile vs desktop
- Whether to show a "scroll to top" button on long results pages

</decisions>

<specifics>
## Specific Ideas

- "Enlace inválido" for corrupt URL — Spanish error, inline text (not a full error card)
- Error messages are all in Spanish, consistent with the rest of the UI
- The 429 and network error cases both get retry buttons; timeout does not (user should rethink the idea)
- The production catch-all must NOT intercept `/api/*` routes — API 404s still return JSON

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `server/src/index.ts` — current static file serving setup and catch-all; the SPA catch-all change goes here
- `server/src/routes/index.ts` — current `/api/health` response shape; add fields here
- `.planning/phases/03-web-frontend/03-CONTEXT.md` — Phase 3 decisions: error state machine (`"error"` state), ShareButton implementation, `useAnalysis()` hook return shape `{ state, steps, result, error, submit, abort }`
- `.planning/ROADMAP.md` Phase 4 section — requirements: INFRA-03, SHARE-01, SHARE-02, SHARE-03
- `client/src/types/analysis.ts` — `AnalysisResult` shape including `competitors: Competitor[]` (may be empty array)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `server/src/index.ts`: Already imports `path` and `__dirname` shim — SPA catch-all can use these directly
- `server/src/routes/index.ts`: `/api/health` handler — add fields inline, no new route needed
- Phase 3's `useAnalysis()` hook: already has `"error"` state — error state UI just needs to be wired to a component

### Established Patterns
- ESM throughout — no `require()`
- TypeScript strict mode — no implicit `any`
- All error messages in Spanish
- Tailwind for all styling — no inline styles except Framer Motion dynamic values
- Single catch-all error card pattern (established in Phase 3 state machine)

### Integration Points
- `server/src/index.ts` line with 404 catch-all: must become SPA catch-all for non-API routes
- `client/src/App.tsx`: `?r=` param decode happens in `useEffect` on mount — error handling wraps the JSON.parse call
- `client/src/components/Dashboard.tsx`: empty competitor list check and smooth scroll ref go here
- `client/src/hooks/useAnalysis.ts`: 429 detection and timeout error classification happen in the hook's fetch handler

### Build State
- Root `package.json` `build` script: `cd client && npm run build && cd ../server && npm run build` — correct, no changes needed
- Root `package.json` `start` script: `cd server && npm start` → `node dist/src/index.js` — correct
- `server/tsconfig.json` should output to `dist/` — verify before assuming path is right

</code_context>

<deferred>
## Deferred Ideas

None — all pre-answered decisions fit within Phase 4 scope.

</deferred>

---
*Phase: 04-polish-demo-prep*
*Context gathered: 2026-05-26*
