# Changelog

## 2026-05-27 — Pre-workshop review pass

**Fixes**
- `analyzer.ts`: Replaced fragile markdown fence regex with `indexOf('{')` / `lastIndexOf('}')` — the `m` flag on `/^```/` made `^` match any line start, causing silent parse failures when Claude emits preamble text
- `analyzer.ts`: Added runtime shape validation before yielding result — TypeScript casts don't catch malformed model responses at runtime
- `analyzer.ts`: Added `signal?: AbortSignal` param; passed to SDK stream so client disconnect actually aborts the Anthropic call
- `analyzer.ts`: Mapped raw SDK errors to user-friendly Spanish messages; AbortError is silently ignored
- `analyze.ts`: Wired `AbortController` to `req.on('close')` — concurrency counter now decrements correctly on client disconnect
- `index.ts`: Fixed dead `__dirname` variables — now used for static file paths instead of fragile `process.cwd()`
- `index.ts`: Replaced wildcard `cors()` with explicit origin list; `CORS_ORIGIN` env var for production overrides
- `routes/index.ts`: Added `model` and `version` fields to `/api/health` response — matches WORKSHOP.md demo script
- `App.tsx`: `formState = urlResult ? 'idle' : state` — form stays enabled when viewing a URL-loaded result
- `App.tsx`: Added `disabled={!lastIdea}` to retry button — prevents silent no-op on first error before any submission
- `App.tsx`: Clears `?r=` param immediately on new submission — mid-stream refresh won't reload stale shared result
- `App.tsx`: Verdict enum check on URL-loaded result — guards VerdictCard crash from crafted `?r=` values
- `ActivityFeed.tsx`: `behavior: 'instant'` scroll — prevents stutter with rapid step arrivals
- `ActivityFeed.tsx`: `key={step.text}` instead of `key={index}` — stable key for append-only list
- `RiskRadarChart.tsx`: `useReducedMotion()` from Framer Motion replaces `useMemo(matchMedia)` anti-pattern
- `Dashboard.tsx`: `key={competitor.name}` instead of `key={index}`
- `CompetitorCard.tsx`: `encodeURIComponent` on favicon domain parameter
- `WORKSHOP.md`: Fixed 10+ factual errors (workflow count, health response shape, SDK name, repo URL, deployment caveat, spend limit warning)
- `README.md`: Fixed repo clone URL, architecture diagram filename, SSE protocol examples

**Learnings**
- The `m` flag on regex `^` changes semantics from "string start" to "line start" — dangerous when stripping code fences from model output that may include preamble
- TypeScript `as SomeType` is a cast, not a runtime validator — always add a shape check before using model-generated JSON in conditional logic
- `process.cwd()` depends on where the process was launched from; `__dirname` (via `fileURLToPath(import.meta.url)`) is always relative to the source file — prefer `__dirname` for path resolution in libraries and servers
- `useReducedMotion()` from Framer Motion is the correct API; `useMemo(() => window.matchMedia(...), [])` runs once at mount and misses OS preference changes

## 2026-05-26 — v1.0 complete

All 4 phases complete. Milestone: Demo-Ready for AI Week Summit Guatemala 2026.

- Phase 1: Foundation (monorepo, health endpoint, Claude SDK wired)
- Phase 2: Analysis engine (SSE streaming, web_search_20250305, rate limiting)
- Phase 3: Full React UI (form → activity feed → animated dashboard, shareable URLs)
- Phase 4: Production build, error states, README, URL hardening
