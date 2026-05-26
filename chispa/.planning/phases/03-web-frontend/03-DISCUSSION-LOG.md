# Phase 3: Web Frontend — Discussion Log

**Date:** 2026-05-26
**Mode:** autonomous (all decisions pre-answered by user before session)
**Facilitator:** Claude (Sonnet 4.6)

---

## Format

This log is an audit trail for human review only. Downstream planning agents read CONTEXT.md, not this file.

---

## Area: App State Machine

**Options considered:**
1. Four-string state: `"idle" | "streaming" | "complete" | "error"` (chosen)
2. Boolean flags (isLoading, isError, etc.)
3. Reducer with useReducer

**User decision:** Four-state string machine — `idle → streaming → complete | error`

**Rationale:** Simple, readable, matches the visual transitions exactly. No need for a reducer when four states cover all transitions.

**Rendering map:**
- idle → IdeaForm
- streaming → IdeaForm (disabled) + ActivityFeed
- complete → Dashboard (animated in) + ActivityFeed (collapsed)
- error → error card + retry button

---

## Area: SSE Client

**Options considered:**
1. `EventSource` API
2. `fetch()` + `ReadableStream` (chosen)
3. Third-party SSE client library

**User decision:** `fetch()` + `ReadableStream` with `AbortController` cleanup.

**Rationale:** `EventSource` doesn't support POST. `fetch()` + `ReadableStream` is the correct approach for POST-based SSE. Abort controller in useEffect cleanup prevents memory leaks on unmount.

**Hook signature:** `useAnalysis()` → `{ state, steps, result, error, submit, abort }`

---

## Area: Component List

**User decision:** Eight components, one file each in `client/src/components/`:
- IdeaForm.tsx
- ActivityFeed.tsx
- Dashboard.tsx
- RadarChart.tsx
- VerdictCard.tsx
- CompetitorCard.tsx
- MarketSnapshot.tsx
- FirstSteps.tsx

**Plus:** ShareButton (pulled from Phase 4 per user decision — see below).

---

## Area: IdeaForm

**Decisions:**
- Textarea: min 20 / max 500 chars, live char counter
- Country select: Guatemala, México, Colombia, Argentina, España, Otro (optional)
- Submit button: Loader2 spinner during streaming
- Disabled state: entire form disabled during streaming + complete

---

## Area: RadarChart

**Decisions:**
- 6 fixed axes: Mercado, Competencia, Técnico, Regulatorio, Timing, Capital
- Severity → value mapping: high=90, medium=60, low=30, missing=20
- Recharts RadarChart with isAnimationActive=true
- Fill: #7c3aed at 30% opacity; stroke: #7c3aed

---

## Area: VerdictCard

**Options for Spanish labels:**
1. Map enum values to Spanish in UI layer (chosen): LAUNCH→LANZA, VALIDATE→VALIDA, PIVOT→PIVOTA, AVOID→EVITA
2. Use English verdict names as-is

**User decision:** Spanish display labels, original enum values kept in data layer.

**Color mapping:**
- LANZA (LAUNCH): #22c55e green
- VALIDA (VALIDATE): #f59e0b amber
- PIVOTA (PIVOT): #f97316 orange
- EVITA (AVOID): #ef4444 red

**Animation:** Framer Motion flip-in (rotateX: 90→0, perspective: 1000)

---

## Area: ShareButton

**Original phase:** Phase 4 (SHARE-01/02/03)

**User decision:** Pull into Phase 3.

**Implementation:**
- Encode: `lzstring.compressToEncodedURIComponent(JSON.stringify(result))`
- URL update: `window.history.pushState({}, '', '/?r=' + encoded)`
- Clipboard copy + "¡Copiado!" toast for 2 seconds
- On mount: decode `?r=` param → load dashboard directly if valid
- New dependency: `lz-string` + `@types/lz-string`

---

## Area: Package Upgrades

**Existing versions (need upgrade):**
- framer-motion: ^11.3.0 → ^12.40.0
- recharts: ^2.12.7 → ^3.8.1

**New installs:**
- lz-string (+ @types/lz-string) in client/

---

## Areas Delegated to Agent's Discretion

- Exact Framer Motion variant timings
- Loading skeleton layout proportions
- Header/footer exact spacing
- React.memo usage on child components

---

## Deferred Ideas

None — all decisions pre-answered, ShareButton moved into Phase 3.

---

*Log created: 2026-05-26*
*Phase: 03-web-frontend*
