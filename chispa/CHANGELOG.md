# Changelog

## 2026-05-28 — v1.1 Impeccable UI complete

**Features**

- **Typography system**: Plus Jakarta Sans (400–700) replaces Inter as body font; Space Grotesk 700 added as display font for brand/verdict moments. Both loaded via Google Fonts CDN with `display=swap`.
- **App header**: Space Grotesk `text-6xl` brand name, `✦` spark icon, subtle radial glow (8% primary opacity), two-tone tagline.
- **VerdictCard**: `font-display text-7xl` verdict word (Space Grotesk), `border-2`, `p-8`, 60% border color opacity — the verdict reveal now dominates the screen.
- **ActivityFeed**: Left primary accent border (`border-l-2 border-l-primary`), "En vivo" header with green pulsing dot, `animate-pulse` only on the latest step bullet.
- **MarketSnapshot**: Market size and growth values promoted to `text-xl font-semibold` — readable at conference projection distance.
- **CompetitorCard**: Favicon 28px, competitor name `text-base`.
- **RiskRadarChart**: PolarGrid stroke `#2a2a42` (more visible), fill opacity 0.45.
- **FirstSteps**: Framer Motion stagger entrance — each item animates in with 70ms delay, x:-12 → 0. `useReducedMotion()` respected.
- **ShareButton**: `Link2` icon from lucide-react replaces plain text arrow.
- **Dashboard**: "Competidores" heading gets `pl-3 border-l-2 border-primary` accent left border.
- **IdeaForm**: `bg-surface-elevated` on textarea and select, `ChevronDown` icon on select, `hover:brightness-110` button.
- **Color tokens**: `surface`, `surface-elevated`, `border`, `border-strong` deepened for better layering on dark backgrounds.

**Learnings**

- `border-l-2` layered over `border` in Tailwind works correctly — the more-specific utility overrides the shorthand for that side only.
- `animate-pulse` on only the latest item in a live list is far more effective than pulsing every item. Restricting motion to the active element makes the feed feel alive without being noisy.
- `font-display` as a Tailwind utility class requires `fontFamily.display` in the config — not a built-in class. Easy to miss when first setting up a dual-font system.

---

## 2026-05-27 — Live-test bug fixes (3 critical, 1 security)

**Fixes**
- `analyze.ts`: `req.on('close')` → `res.on('close', () => { if (!res.writableEnded) abort() })` — `req` fires close immediately after POST body parsing, aborting every request before the Anthropic call even started. `res` fires only when the client disconnects from the SSE stream.
- `analyzer.ts`: Add `APIUserAbortError` to abort guard — the Anthropic SDK throws its own error class (not the native `AbortError`) when a stream is cancelled via signal; unguarded, this leaked as a user-facing "Error interno" message.
- `analyzer.ts`: `textBlocks.at(-1)?.text` → `textBlocks.map(b => b.text).join('')` — with `web_search_20250305` active, Claude interleaves `server_tool_use` blocks between text fragments; grabbing only the last fragment produced partial JSON that always failed parsing.
- `client/package.json`: Vite `^5.3.2` → `6.4.2` — patches 2 moderate CVEs (esbuild dev-server request smuggling, path traversal in static file serving).

**Learnings**
- `req.on('close')` and `res.on('close')` are not the same event on an SSE endpoint. `req` closes when the body is parsed (immediately); `res` closes when the client drops the connection. Always use `res` for SSE disconnect detection.
- The Anthropic SDK wraps native AbortError in `APIUserAbortError`. When guarding against abort, check both `.name` values.
- Claude with active tools returns interleaved content blocks. Never use `.at(-1)` on text blocks — always join all of them.

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
