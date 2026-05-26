# Phase 3: Web Frontend — Research

**Researched:** 2026-05-26
**Phase goal:** A complete, animated browser UI — form → live activity feed → animated dashboard.

---

## Don't Hand-Roll

| Problem | Recommended solution | Why |
|---------|---------------------|-----|
| SSE consumer for POST requests | `fetch()` + `ReadableStream` + `TextDecoder` — already decided. The pattern is: `const res = await fetch(...)`, then `res.body.getReader()`, decode chunks, split on `\n\n`, parse `data: <json>` lines. | `EventSource` only supports GET. This is the architecturally correct choice for a POST-based SSE endpoint. |
| URL-safe result compression | `lz-string` — specifically `compressToEncodedURIComponent` / `decompressFromEncodedURIComponent`. Verified: a realistic 3.6KB AnalysisResult JSON compresses to ~2.3KB URL-safe string. Round-trip confirmed. | Do NOT use raw JSON + btoa. At realistic payloads (3–20KB), raw base64 exceeds nginx's 8KB header limit. lz-string produces ~36% smaller output than base64 with correct URL encoding. |
| lz-string types | Do NOT install `@types/lz-string`. It is deprecated. lz-string 1.5.0 ships its own `typings/lz-string.d.ts`. Just `npm install lz-string` — types are included. | The `@types/lz-string` stub on npm is explicitly deprecated with a notice saying lz-string provides its own types. |
| Staggered list item animations | Use `framer-motion`'s `stagger()` function, NOT `staggerChildren`. In framer-motion 12, `staggerChildren` is `@deprecated` with the message: "Use `delayChildren: stagger(interval)` instead." | Confirmed in `motion-dom` type definitions: `@deprecated - Use 'delayChildren: stagger(interval)' instead`. The `stagger` function is available from `import { motion, stagger } from 'framer-motion'` via `export * from 'motion-dom'`. |
| Radar chart | Recharts `RadarChart` + `Radar` + `PolarAngleAxis` + `PolarGrid`. No third-party wrappers. | Recharts 3.8.1 ships full TypeScript types. The RadarChart API is compatible: `data` on `RadarChart`, `dataKey` on `Radar`, `isAnimationActive` on `Radar`. Confirmed against actual type definitions. |
| Inline "¡Copiado!" toast | Local `useState` boolean + `setTimeout` reset — already decided. No toast library. | Adding a toast library (react-hot-toast, sonner, etc.) for a single use case is unjustified. The pattern is 4 lines of state. |

---

## Common Pitfalls

### Pitfall 1: SSE chunk boundaries split events — must buffer across chunks

**What goes wrong:** The `ReadableStream` reader yields `Uint8Array` chunks that do NOT align with SSE event boundaries. A single `\n\n`-terminated event may span two chunks, and a single chunk may contain multiple events. Developers who parse each chunk independently with `.split('\n\n')` and call `JSON.parse` on each part will silently drop events at boundaries.

**Why:** TCP delivers data in arbitrary segment sizes. The SSE `\n\n` delimiter is only meaningful when processing the full accumulated stream.

**How to avoid:** Maintain a mutable `let buffer = ''` outside the reader loop. On each chunk: `buffer += decoder.decode(chunk, { stream: true })`. Split on `\n\n`, process all complete events, and reassign `buffer = parts.pop()` to retain the trailing incomplete fragment. Verified with a unit test — all 3 events recovered correctly across arbitrary chunk boundaries.

---

### Pitfall 2: React StrictMode fires useEffect twice — AbortError must be silently swallowed

**What goes wrong:** `main.tsx` wraps `App` in `<StrictMode>`. In React 18 StrictMode (development only), every `useEffect` fires twice: mount → unmount (cleanup) → remount. This means `useAnalysis` fires the `AbortController.abort()` cleanup immediately after the first mount, then re-subscribes. The aborted fetch throws a `TypeError` with `name: "AbortError"`. If the hook's catch block calls `setError(err.message)`, the UI flashes into error state every time the component mounts in development.

**Why:** Node.js global `fetch` throws a `TypeError` (not `DOMException`) on abort, but the `.name` property is `"AbortError"`. Verified: `err.name === 'AbortError'` correctly identifies the cancellation.

**How to avoid:** In the `catch` block of the SSE fetch: `if (err instanceof Error && err.name === 'AbortError') return;`. Do not call `setError` for abort errors. This is a pure development concern — production builds don't use StrictMode double-invoke — but the hook must handle it or dev experience is broken.

---

### Pitfall 3: framer-motion 12 requires explicit package upgrade before any v12 APIs are used

**What goes wrong:** The client currently has `framer-motion@11.18.2` installed (the `^11.3.0` range resolved to 11.18.2). Using any v12-specific API (including the `stagger()` replacement for `staggerChildren`) on the installed 11.x version will fail silently or throw. The context doc says "must upgrade before building."

**Why:** The npm range `^11.3.0` resolves to the latest 11.x, not 12.x. A major version bump requires explicit install.

**How to avoid:** Run `npm install framer-motion@^12.40.0` in `client/` before writing any component code. Similarly upgrade `recharts@^3.8.1`. Verify with `npm ls framer-motion recharts` before starting implementation. These are the FIRST tasks in this phase — not mid-phase.

---

### Pitfall 4: `staggerChildren` is deprecated in framer-motion 12 — will still work but shows warning

**What goes wrong:** The CONTEXT.md describes ActivityFeed using `staggerChildren: 0.08` in variants. In framer-motion 12 (via `motion-dom`), `staggerChildren` is marked `@deprecated`. It still works functionally (the runtime code handles it via `calcChildStagger`), but type-checkers in strict mode may flag it, and it will be removed in a future major version.

**Why:** framer-motion 12 adopted the `stagger()` utility function from `motion-dom` as the canonical approach. The type annotation explicitly says: "Use `delayChildren: stagger(interval)` instead."

**How to avoid:** Use `delayChildren: stagger(0.08)` instead of `staggerChildren: 0.08` in transition objects. Import `stagger` from `framer-motion` (it's re-exported via `export * from 'motion-dom'`). Example:
```ts
// Correct for framer-motion 12:
transition: { staggerChildren: undefined, delayChildren: stagger(0.08) }

// Or equivalently in the variants transition:
container: {
  animate: { transition: { delayChildren: stagger(0.08) } }
}
```
The old `staggerChildren` will not break — but use the new form for forward compatibility.

---

### Pitfall 5: `transformPerspective` not `perspective` for 3D rotation in framer-motion

**What goes wrong:** VerdictCard needs a flip-in animation (`rotateX: 90 → 0`). Developers may try to set `perspective: 1000` as a `style` prop or in `animate`. In framer-motion, `perspective` is NOT a recognized motion value — it will be silently ignored or cause TypeScript errors. The correct property is `transformPerspective`.

**Why:** framer-motion internally maps `transformPerspective` to the CSS `perspective()` function in the transform string: `perspective(${transformPerspective}px) rotateX(...)`. This is documented in the motion-dom source at line ~4368: `transformPerspective: "perspective"` in the value mapping.

**How to avoid:** Use `style={{ transformPerspective: 1000 }}` on the parent container element, combined with `initial={{ rotateX: 90 }} animate={{ rotateX: 0 }}` on the child. Or set `transformPerspective` in the `animate` prop directly on the motion element.

---

### Pitfall 6: Recharts 3 `isAnimationActive` defaults to `"auto"` — may not animate on first render

**What goes wrong:** The CONTEXT.md says `isAnimationActive={true}` on the Radar component. In recharts 3, the default is `"auto"` (not `true` or `false`). The `"auto"` value triggers animation only when the data changes after mount — meaning on the initial render with static data, animation may not fire.

**Why:** Recharts 3 type definition: `readonly isAnimationActive: "auto"`. The `"auto"` mode detects data changes and animates on update, not on initial mount.

**How to avoid:** Explicitly set `isAnimationActive={true}` on `<Radar>` to force animation on mount. This is already specified in CONTEXT.md and must be passed explicitly — do not rely on defaults.

---

### Pitfall 7: `@types/lz-string` must NOT be installed — it conflicts with lz-string's own types

**What goes wrong:** The CONTEXT.md mentions `npm install lz-string @types/lz-string`. The `@types/lz-string` package on npm is a deprecated stub that explicitly says lz-string provides its own types. Installing it alongside lz-string creates duplicate type declarations that may cause TypeScript to error with "Duplicate identifier" or type conflicts.

**Why:** lz-string 1.5.0 ships `typings/lz-string.d.ts` referenced via its `types` field in package.json. The `@types/lz-string` DefinitelyTyped entry is now a stub that only re-exports the bundled types, but having both installed can confuse module resolution.

**How to avoid:** Run `npm install lz-string` only. Do not add `@types/lz-string`. Confirmed: the stub's npm page says "DEPRECATED — This is a stub types definition. lz-string provides its own type definitions."

---

### Pitfall 8: Vite proxy has no timeout configured — SSE connections lasting >120s may be dropped

**What goes wrong:** The current `vite.config.ts` proxy has only `target` and `changeOrigin`. Vite's http-proxy has an internal socket timeout that may close the connection before the ~90s analysis completes. The analysis may succeed on the server but the browser gets a closed connection and sees it as an error.

**Why:** The Vite proxy uses `http-proxy` under the hood. Without explicit socket timeout configuration, it defaults to Node.js socket idle timeout which can be as low as 60s in some configurations.

**How to avoid:** Add a proxy configure callback to keep the connection alive. The existing PITFALLS.md (P12) documents the exact pattern:
```ts
configure: (proxy) => {
  proxy.on('proxyReq', (proxyReq) => {
    proxyReq.setHeader('Connection', 'keep-alive');
  });
},
```
This should be added to the proxy config in `vite.config.ts` at the start of this phase.

---

### Pitfall 9: RadarChart data must be keyed by axis name — not by risk `title` directly

**What goes wrong:** The 6 radar axes are fixed: `["Mercado", "Competencia", "Técnico", "Regulatorio", "Timing", "Capital"]`. `AnalysisResult.risks` is an array with arbitrary `title` strings from Claude. Developers who try to pass `risks` directly as `RadarChart` data will get mismatched or empty axes if Claude uses slightly different titles.

**Why:** Recharts RadarChart maps data entries to axes by the `subject` property (or the key used on `PolarAngleAxis dataKey`). The risk titles from Claude may not exactly match the fixed axis labels.

**How to avoid:** Build a fixed mapping function that normalizes Claude's risk titles to the 6 axis keys. The CONTEXT.md specifies: `high=90, medium=60, low=30, missing=20`. Create a transform like:
```ts
const AXIS_KEYS = ['Mercado','Competencia','Técnico','Regulatorio','Timing','Capital']
const riskMap = Object.fromEntries(risks.map(r => [r.title, r.severity]))
const data = AXIS_KEYS.map(key => ({
  axis: key,
  value: riskMap[key] === 'high' ? 90 : riskMap[key] === 'medium' ? 60 : riskMap[key] === 'low' ? 30 : 20
}))
```

---

### Pitfall 10: Google favicon API is HTTP — CSP or mixed-content blocking may fail the image

**What goes wrong:** `CompetitorCard` uses `https://www.google.com/s2/favicons?domain=${website}&sz=32`. If the server or Vite adds a Content-Security-Policy header that doesn't whitelist `www.google.com`, the favicons will fail to load. Broken img elements with no `onError` handler show a broken image icon.

**Why:** The Google favicon API is at `www.google.com` (a third-party origin). Some CSP configurations default-deny external image sources.

**How to avoid:** Add `onError={(e) => { (e.target as HTMLImageElement).style.display = 'none' }}` to every CompetitorCard favicon `<img>` element. This gracefully hides the broken image rather than showing the browser's broken icon. CONTEXT.md already specifies "graceful fallback when website is missing" but does NOT mention the onError for the fetch-failure case — add it.

---

## Existing Patterns in This Codebase

- **Color tokens:** `client/tailwind.config.js` defines `background` (#0a0a0f), `surface` (#13131a), `border` (#1f1f2e), `primary` (#7c3aed), `primary-light` (#a855f7). These are the only color values that should appear in component class names — use semantic names, never raw hex in Tailwind classes. Hex is allowed only in inline `style` props where Tailwind classes can't reach (e.g., Recharts fill/stroke props, Framer Motion color animations).

- **Global CSS:** `client/src/index.css` sets `body { background-color: #0a0a0f; color: #f8fafc }` and defines a purple scrollbar (`#7c3aed` thumb). Components do not need to repeat base text color — it's inherited from body. The scrollbar styling means `overflow-y-auto` divs (ActivityFeed auto-scroll container) will automatically get the branded scrollbar.

- **TypeScript types contract:** `client/src/types/analysis.ts` is the single source of truth. Import `AnalysisResult`, `SSEMessage`, `Competitor`, `Risk` from this file in every component. Do NOT redefine inline type aliases. The `SSEMessage` union discriminates on `type`: `"step" | "result" | "error" | "ping"`. The `ping` type must be handled (or explicitly skipped) in the hook's parser.

- **ESM-only codebase:** `client/package.json` has `"type": "module"`. All imports use ESM syntax. No `require()`. Vite handles module resolution — TypeScript import paths in `.tsx` files do NOT need `.js` extensions (unlike the server which does).

- **Entry point:** `client/src/main.tsx` mounts `App` in `StrictMode`. The App is the sole component. No router. `useAnalysis()` must be called at App level per CONTEXT.md.

- **Stub to replace:** `client/src/App.tsx` is a minimal placeholder (13 lines). It must be completely replaced, not patched. Read it before editing — it uses `bg-background` and `text-primary` class names that confirm Tailwind color token wiring works.

- **Server SSE format:** Confirmed from `server/src/routes/analyze.ts`: each event is `data: ${JSON.stringify(msg)}\n\n`. The `SSEMessage` type from `client/src/types/analysis.ts` is exactly what's serialized. The `ping` type is in the union for keep-alive events that the server may emit. The hook parser must handle `type === 'ping'` by doing nothing (not erroring).

---

## Package Upgrade Sequence

This must happen FIRST before any component work:

1. `cd client && npm install framer-motion@^12.40.0` — upgrades from 11.18.2
2. `cd client && npm install recharts@^3.8.1` — upgrades from 2.15.4
3. `cd client && npm install lz-string` — new install, types included
4. Do NOT install `@types/lz-string`
5. Run `npm run typecheck` to confirm no type errors from upgrades before writing components

Confirmed latest versions via npm registry: framer-motion@12.40.0 and recharts@3.8.1 both exist and are compatible with React ^18.3.1 (verified peer deps).

---

## Recommended Approach

Build in strict dependency order: upgrades first, then `useAnalysis` hook (the SSE consumer is the foundation everything else depends on), then App state machine in `App.tsx`, then components from simplest to most complex (IdeaForm → ActivityFeed → VerdictCard → MarketSnapshot → CompetitorCard → FirstSteps → RadarChart → Dashboard → ShareButton). Wire the Vite proxy keep-alive fix at the start since it affects the SSE connection stability during all testing. Test the hook against the live Phase 2 backend with `curl` output before building any UI — if the hook doesn't parse SSE correctly, all components are unreliable.

The `staggerChildren → stagger()` change and the `transformPerspective` detail are the two framer-motion 12 specifics most likely to cause wasted debugging time; address them at the component level when writing ActivityFeed and VerdictCard respectively.
