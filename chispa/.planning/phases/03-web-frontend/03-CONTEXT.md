# Phase 3: Web Frontend - Context

**Gathered:** 2026-05-26
**Mode:** autonomous (all decisions pre-answered)
**Status:** Ready for planning

<domain>
## Phase Boundary

A complete, animated browser UI: form → live activity feed → animated dashboard. The user submits an idea, watches Claude's tool calls stream in real time, then sees the full analysis dashboard animate in. This phase covers all client-side code including the SSE consumer hook, all components, and the ShareButton.

Note: ShareButton (lz-string URL encoding) is included in this phase even though SHARE-01/02/03 appear in Phase 4 of the roadmap — user decision pre-answered to include it here.

</domain>

<decisions>
## Implementation Decisions

### App State Machine
Four states drive all rendering:
- `"idle"` → show IdeaForm
- `"streaming"` → show IdeaForm (disabled) + ActivityFeed
- `"complete"` → show Dashboard (slides up) + ActivityFeed (collapsed)
- `"error"` → show error card + retry button

Single state string in App.tsx; no external state library.

### SSE Client
- Use `fetch()` + `ReadableStream` (NOT `EventSource` — POST not supported by EventSource)
- Hook: `useAnalysis()` in `client/src/hooks/useAnalysis.ts`
- `AbortController` created in `useEffect` and called in cleanup to prevent connection leaks on unmount
- Hook returns: `{ state, steps, result, error, submit, abort }`
- On each SSE line: parse JSON → if `type === "step"`, append to steps array; if `type === "result"`, set result and transition to complete; if `type === "error"`, set error and transition to error

### Package Upgrades Required
Current installed versions are behind spec — must upgrade before building:
- `framer-motion`: ^11.3.0 → ^12.40.0
- `recharts`: ^2.12.7 → ^3.8.1
- Add: `lz-string` + `@types/lz-string` (new install in client/)

### Component Architecture
One file per component in `client/src/components/`. Components:

**IdeaForm.tsx**
- `<textarea>` with min 20 / max 500 chars (validation on submit, not on keypress)
- Live char counter displayed below textarea
- Optional country `<select>` with options: Guatemala, México, Colombia, Argentina, España, Otro
- Submit button shows Loader2 spinner (lucide-react) during streaming state
- Entire form disabled when state is `"streaming"` or `"complete"`
- Spanish labels throughout

**ActivityFeed.tsx**
- List of `SSEMessage` step events as they arrive
- Each item animates in with Framer Motion `staggerChildren` (parent `variants` with `staggerChildren: 0.08`)
- Source badge (domain string) shown next to step text when `source` field is present
- Auto-scrolls to bottom on new item (useRef + scrollIntoView)

**Dashboard.tsx**
- Container that animates in with slide-up + fade (Framer Motion: `y: 40 → 0`, `opacity: 0 → 1`)
- Renders all sub-components: VerdictCard, RadarChart, MarketSnapshot, CompetitorCard list, FirstSteps
- Receives full `AnalysisResult` as prop

**RadarChart.tsx**
- Recharts `RadarChart` with 6 fixed axes: Mercado, Competencia, Técnico, Regulatorio, Timing, Capital
- Maps `AnalysisResult.risks` by title to severity → numeric value: high=90, medium=60, low=30, missing=20
- `isAnimationActive={true}` on Recharts Radar component
- Dark theme: fill `#7c3aed` at 30% opacity, stroke `#7c3aed`

**VerdictCard.tsx**
- Displays verdict string with large font, color-coded:
  - LANZA (mapped from LAUNCH): `#22c55e` green
  - VALIDA (mapped from VALIDATE): `#f59e0b` amber
  - PIVOTA (mapped from PIVOT): `#f97316` orange
  - EVITA (mapped from AVOID): `#ef4444` red
- `verdictReason` text rendered below verdict in smaller font
- Framer Motion flip-in animation (rotateX: 90→0 with `perspective: 1000`)
- Spanish verdict labels (LAUNCH → LANZA, etc.) displayed in UI; original enum values kept in data

**CompetitorCard.tsx**
- Favicon: `<img src={\`https://www.google.com/s2/favicons?domain=${website}&sz=32\`}>` — only rendered when `website` is present
- Company name (bold), 1-line description
- Funding badge rendered if `funding` field is present
- Graceful fallback when `website` is missing (no broken img)

**MarketSnapshot.tsx**
- Displays `marketSize` string and `marketGrowth` string
- Timing badge with Spanish label:
  - `too_early` → "Demasiado temprano"
  - `right_time` → "Momento perfecto"
  - `too_late` → "Demasiado tarde"
- Badge colors: too_early=amber, right_time=green, too_late=red

**FirstSteps.tsx**
- Numbered list of 5 steps from `firstSteps` array
- Only rendered when verdict is `LAUNCH` or `VALIDATE` (i.e., `"LAUNCH"` or `"VALIDATE"` enum values)
- Not rendered for PIVOT or AVOID

### Loading Skeleton
While state is `"streaming"`, show pulsing placeholder divs where the dashboard will appear. Use Tailwind `animate-pulse` with bg-surface rounded blocks to suggest card layout. These are adjacent to ActivityFeed, not replacing it.

### ShareButton
- Rendered in Dashboard after analysis is complete
- Encodes result: `lzstring.compressToEncodedURIComponent(JSON.stringify(result))`
- Updates URL without reload: `window.history.pushState({}, '', '/?r=' + encoded)`
- Copies encoded URL to clipboard
- Shows "¡Copiado!" toast for 2 seconds (local state, not a toast library)
- On App mount: check `new URLSearchParams(window.location.search).get('r')` — if present, decode with `lzstring.decompressFromEncodedURIComponent`, parse JSON, load dashboard directly (skip form, set state to complete)
- Install in client: `npm install lz-string @types/lz-string`

### App.tsx Structure
- Single page, no router
- Header: logo ("✦ Chispa") + tagline ("Valida tu idea. En segundos.")
- Main content area renders based on state machine
- `useAnalysis()` hook called at App level, state and handlers passed to children
- `?r=` param check on mount (useEffect with empty deps)

### Agent's Discretion
- Exact Framer Motion variant timings (beyond the decisions above)
- Loading skeleton exact layout proportions
- Header/footer exact spacing and typography
- Whether to memoize child components with React.memo

</decisions>

<specifics>
## Specific Ideas

- Dark theme throughout: `bg-background` (#0a0a0f) for page, `bg-surface` (#13131a) for cards, `border-border` (#1f1f2e) for card borders, `text-primary` / `#7c3aed` for purple accents
- Spanish-first: all UI copy in Spanish (labels, buttons, verdicts, timing badges, toasts)
- Tailwind custom colors already defined in `tailwind.config.js` — use semantic names (`bg-surface`, `border-border`, `text-primary`) not hex values
- The "¡Copiado!" toast is inline state, not a library — keep it simple

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `client/src/types/analysis.ts` — canonical `AnalysisResult`, `SSEMessage`, `Competitor`, `Risk` types; the Phase 3 contract
- `.planning/phases/02-analysis-engine/02-CONTEXT.md` — Phase 2 SSE event format: `{ type, text, source? }` for steps, `{ type: "result", data: AnalysisResult }` for result
- `.planning/ROADMAP.md` Phase 3 section — requirements covered (ANLYS-01, STRM-03, DASH-01 through DASH-06)
- `client/tailwind.config.js` — custom color tokens; use these, not raw hex
- `client/package.json` — current installed versions; framer-motion and recharts must be upgraded before implementing

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `client/src/types/analysis.ts`: `AnalysisResult`, `SSEMessage`, `Competitor`, `Risk` — import in all components that need data shape
- `client/src/App.tsx`: stub placeholder; will be completely replaced with state machine implementation
- `client/tailwind.config.js`: `background`, `surface`, `border`, `primary`, `primary-light` color tokens already registered

### Established Patterns
- ESM throughout (`import`/`export`) — no `require()`
- TypeScript strict mode — no implicit `any`
- Tailwind CSS for all styling — no inline styles except where Framer Motion requires dynamic values
- Component per file in `client/src/components/`
- Hooks in `client/src/hooks/`

### Integration Points
- `useAnalysis()` hook POSTs to `/api/analyze` — Vite proxy forwards to Express on 3001
- SSE consumer reads `data: <JSON>\n\n` lines from the response body ReadableStream
- `AnalysisResult` shape from `client/src/types/analysis.ts` is the exact output shape from Phase 2's `/api/analyze` result event
- `App.tsx` is the sole entry point; `main.tsx` mounts it — no routing layer needed

### Package State
- `framer-motion` installed at ^11.3.0 — needs upgrade to ^12.40.0 before using v12 APIs
- `recharts` installed at ^2.12.7 — needs upgrade to ^3.8.1
- `lz-string` not yet installed — add in this phase
- `lucide-react` already installed (Loader2 icon for spinner)

</code_context>

<deferred>
## Deferred Ideas

None — all decisions provided upfront. ShareButton (originally Phase 4 SHARE-01/02/03) pulled into this phase per user decision.

</deferred>

---
*Phase: 03-web-frontend*
*Context gathered: 2026-05-26*
