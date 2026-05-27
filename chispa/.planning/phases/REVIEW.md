# Multi-Persona Code Review — Chispa v1.0

**Date:** 2026-05-26
**Scope:** Full codebase quality review (no remote diff; quality-only pass)
**Reviewers:** correctness · testing · security · performance · maintainability · adversarial

---

## Intent

Chispa accepts a startup idea, calls Claude claude-opus-4-7 with `web_search_20250305` via SSE streaming, and returns a research-backed competitive analysis to the client in real time. v1.0 is demo-ready for AI Week Summit Guatemala 2026.

---

## Spec Compliance

SKIPPED — no remote; reviewing full codebase quality.

---

## Findings

> **Resolution status updated 2026-05-27** — 10 of 13 findings resolved. See status column.

### P1 — High

| # | File | Line | Issue | Status |
|---|------|------|-------|--------|
| 1 | `client/src/App.tsx` | 74 | **urlResult never cleared on new submission** — new analysis ran invisibly when a shared URL was loaded first. | ✅ FIXED — `setUrlResult(null)` added to onSubmit handler |
| 2 | `client/src/hooks/useAnalysis.ts` | 76 | **No post-loop state transition** — stream close without result/error left state stuck at `'streaming'` forever. | ✅ FIXED — `hasResult` flag; `if (!hasResult)` block transitions to error state |
| 3 | `client/src/components/MarketSnapshot.tsx` | 16 | **Unguarded map lookup on AI-returned value** — unknown `marketTiming` crashed the component; crafted `?r=` URL exploitable. | ✅ FIXED — `TIMING_CONFIG[marketTiming] ?? { label: marketTiming, ... }` fallback |

---

### P2 — Moderate

| # | File | Line | Issue | Status |
|---|------|------|-------|--------|
| 4 | `client/src/components/RiskRadarChart.tsx` | 23–43 | **Axis matching routinely fails for real Claude output** — partial string match couldn't map "Regulaciones locales" → "Regulatorio". Chart showed all axes at low-risk sentinel value. | ✅ FIXED — Added `category` field to `Risk` type; prompt instructs Claude to emit exact axis values; `buildChartData` prefers `category` over string matching |
| 5 | `server/src/routes/analyze.ts` | 21 | **No length limit on `country` field** — arbitrary-length string sent verbatim to Claude prompt. | ✅ FIXED — `body.country.length <= 100` validation |
| 6 | `server/src/index.ts` | 14 | **CORS open to all origins** — any site could trigger paid Claude API calls. | ✅ FIXED — `cors({ origin: process.env.CORS_ORIGIN ?? [...] })` |
| 7 | `server/src/agent/analyzer.ts` | 51–53 | **`idea`/`country` embedded unsanitized in Claude prompt** — prompt injection possible. Practical impact low (output parsed as JSON; failures become errors). | ⚠️ OPEN — Acceptable for demo. Fix for public deployment: wrap inputs in XML tags. |
| 8 | `server/src/agent/analyzer.ts` | 94–98 | **JSON fence regex failed on preamble text** — markdown fence stripping with `m` flag made `^` line-anchored; preamble before `{` caused silent parse failure. | ✅ FIXED — Replaced with `indexOf('{')` / `lastIndexOf('}')` extraction |

---

### P3 — Low

| # | File | Line | Issue | Status |
|---|------|------|-------|--------|
| 9 | `(all)` | — | **Zero test coverage** — no `*.test.*` files exist. | ⚠️ OPEN — Acceptable for demo scope. |
| 10 | `client/src/App.tsx` | 105 | **Error type detection via `startsWith` on Spanish copy** — retry button silently disappears if error strings change. | ⚠️ OPEN — Low risk; string constants haven't changed. |
| 11 | `client/src/components/VerdictCard.tsx` | 21 | **`transformPerspective` is not a valid CSS property** — correct property is `perspective: '1000px'`. | ✅ FIXED — Changed to `style={{ perspective: '1000px' }}`; removed unused `React` import |
| 12 | `client/src/components/ShareButton.tsx` | 18 | **`setTimeout` without cleanup** — fires on unmounted component. | ✅ FIXED — `useRef` stores timeout ID; `clearTimeout` on repeat clicks and cleanup |
| 13 | `server/src/agent/analyzer.ts` | 59–60 | **`as any` cast for `web_search_20250305` tool type** — SDK doesn't include this tool type yet. | ✅ ADDRESSED — Cast retained with explanatory comment; no alternative until SDK update |

---

## Verdict

**PASS** — All P1 findings resolved. All P2 findings resolved except #7 (prompt injection — acceptable for demo, document for public deployment). P3 #9 (tests) and #10 (startsWith) are low-risk deferred items.

**Total: 13 findings** — 10 resolved, 3 open (all acceptable for demo scope)

---

## Recommended Fixes (Priority Order)

### Fix 1 — Clear urlResult on new submission (`App.tsx:74`) [P1]

```tsx
onSubmit={(idea, country) => {
  setLastIdea(idea)
  setLastCountry(country)
  setUrlResult(null)          // ← add this
  submit(idea, country)
}}
```

### Fix 2 — Transition out of streaming on stream close (`useAnalysis.ts`) [P1]

After the `while(true)` loop, add a state cleanup:

```ts
// After: while (true) { ... } break
if (state === 'streaming') {  // only if no result/error arrived
  setError('El análisis no completó correctamente. Intenta de nuevo.')
  setState('error')
}
```
The challenge is that `state` inside `run()` is a stale closure. Use a `hasResult` ref instead:

```ts
let hasResult = false
// inside the loop, set hasResult = true when result or error is received
// after the loop:
if (!hasResult) {
  setError('El análisis no completó correctamente. Intenta de nuevo.')
  setState('error')
}
```

### Fix 3 — Guard TIMING_CONFIG lookup (`MarketSnapshot.tsx:16`) [P1]

```tsx
const timing = TIMING_CONFIG[marketTiming] ?? {
  label: marketTiming,
  color: '#9ca3af',
  bg: 'rgba(156,163,175,0.1)',
}
```

### Fix 4 — Add country length validation (`analyze.ts:21`) [P2]

```ts
const country = typeof body.country === 'string' && body.country.length <= 100
  ? body.country
  : undefined
```

### Fix 5 — Improve radar chart matching or use a different visualization [P2]

Option A: Pass `risks` directly to the chart and show a list of colored risk badges instead of a fixed-axis radar.  
Option B: Map by index (first risk → first axis, etc.) as a display approximation.  
Option C: Add `category` field to `Risk` type and prompt Claude to use exactly `Mercado | Competencia | Técnico | Regulatorio | Timing | Capital` as category values.

Option C requires a prompt change and type update but produces the most accurate chart.

---

## Design Pass Suggested

This review touched all UI files. Consider:
- `/impeccable audit` — accessibility, contrast, layout
- `/impeccable critique` — typography, hierarchy, motion

---

## Learning Checkpoint

Most significant pattern: **state machine gaps at boundary conditions**. Both P1 findings #1 and #2 are variants of the same failure: the state machine doesn't handle the "unexpected exit" case (stream closed without terminal message, URL result not cleared on new submission). A useful principle: for every state, enumerate all ways to exit it, including abnormal paths, and ensure each one transitions to a valid next state.

→ `/agentic-learning learn state-machine-completeness` to make this pattern stick.
