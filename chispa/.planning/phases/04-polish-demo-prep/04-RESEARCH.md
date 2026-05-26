# Phase 4: Polish & Demo Prep — Research

**Researched:** 2026-05-26
**Phase goal:** Shareable URLs work, error states are handled gracefully, production build runs, README is complete.

---

## Don't Hand-Roll

| Problem | Recommended solution | Why |
|---------|---------------------|-----|
| URL-safe compression of large JSON | `lz-string@1.5.0` — already installed in `client/` | Already in `client/package.json`. `compressToEncodedURIComponent` produces a URL-safe string directly — no extra `encodeURIComponent` call needed. Verified: 60-char JSON compresses to 87 chars; roundtrip is lossless. |
| Detecting malformed `?r=` params | Wrap `lzstring.decompressFromEncodedURIComponent` + `JSON.parse` in try/catch | `decompressFromEncodedURIComponent` returns `null` for garbage input (tested: `"garbage"`, `"not-base64!!!"` all return `null`). Empty string or `null` input returns empty string. `JSON.parse(null)` throws. Always check for falsy return before parsing. |
| TypeScript types for lz-string | Use the bundled typings — no `@types/lz-string` needed | `lz-string` ships `typings/lz-string.d.ts` directly. `@types/lz-string` is NOT installed and NOT needed. Import as `import lzstring from 'lz-string'` — Vite handles the CJS-to-ESM interop automatically. |

---

## Common Pitfalls

### Pitfall 1: `__dirname` path breaks in compiled production output
**What goes wrong:** `server/src/index.ts` line 17 already uses `path.join(__dirname, '../../client/dist')`. This path works when `tsx` runs the source file directly (`__dirname` = `/chispa/server/src`, so `../../client/dist` = `/chispa/client/dist`). But when compiled TypeScript runs as `node dist/src/index.js`, `__dirname` = `/chispa/server/dist/src`, so `../../client/dist` resolves to `/chispa/server/client/dist` — a path that does not exist. The production app silently serves nothing.

**Why:** TypeScript compilation adds a `dist/` directory level. The relative path that works for tsx (2 levels up from `src/`) needs one extra level (3 levels up from `dist/src/`).

**How to avoid:** Replace the `__dirname`-relative path with a `process.cwd()`-based path. The `npm start` script runs `cd server && npm start`, so `process.cwd()` is always `/path/to/chispa/server` at runtime. Use `path.join(process.cwd(), '../client/dist')` for both the `express.static` call and the SPA catch-all `res.sendFile`. This is environment-agnostic and immune to compilation depth changes.

Both the `express.static` line (line 17) AND the new SPA catch-all must use the corrected path.

### Pitfall 2: SPA catch-all intercepts `/api/*` 404s
**What goes wrong:** If the catch-all is placed after all routes (as intended) but uses `app.use((_req, res) => res.sendFile(...))` without filtering, it will intercept requests to unknown `/api/` routes and return `index.html` instead of a JSON 404. This breaks API consumers who expect JSON error responses.

**Why:** `app.use` without a path prefix matches everything. The existing router-level 404 handler (`{ error: 'Not found' }`) must still handle `/api/*` misses.

**How to avoid:** The catch-all must check for `/api/` prefix before sending `index.html`. Pattern:
```typescript
app.use((req, res) => {
  if (req.path.startsWith('/api/')) {
    res.status(404).json({ error: 'Not found' })
  } else {
    res.sendFile(path.join(process.cwd(), '../client/dist/index.html'))
  }
})
```
Replace the existing `(_req, res) => res.status(404).json(...)` catch-all in `server/src/index.ts` with this conditional version.

### Pitfall 3: 429 error message is a raw `Error 429: {...}` string, not the Spanish copy
**What goes wrong:** `useAnalysis.ts` line 55 sets `setError(\`Error ${response.status}: ${text}\`)` for any non-OK response. A 429 response will show `"Error 429: Demasiados análisis en curso. Intenta en unos segundos."` — technically correct but not the polished copy specified in CONTEXT.md: `"Demasiados análisis en curso. Espera un momento e intenta de nuevo."`.

**Why:** The hook does not distinguish between different HTTP error codes when setting error messages.

**How to avoid:** Add explicit `response.status === 429` check in `useAnalysis.ts` before the generic `!response.ok` fallback:
```typescript
if (response.status === 429) {
  setError('Demasiados análisis en curso. Espera un momento e intenta de nuevo.')
  setState('error')
  return
}
if (!response.ok) {
  // ... generic handler
}
```
Similarly, timeout errors arrive as SSE `error` events with `msg.message` from the server — the hook already forwards these verbatim to `setError`, so the server-side message is what the UI shows. Ensure the server's timeout error message is the Spanish copy from CONTEXT.md.

### Pitfall 4: `lzstring.decompressFromEncodedURIComponent` on `null`/`undefined` returns empty string, not `null`
**What goes wrong:** When `URLSearchParams.get('r')` returns `null` (no param), and you call `lzstring.decompressFromEncodedURIComponent(null)`, it returns an empty string `""` instead of throwing or returning `null`. If the code only checks `if (!decompressed)`, it will catch this. But if the check uses `=== null`, it will not catch the empty-string case.

**Why:** lz-string's behavior for falsy input is inconsistent: `null`/`undefined` → `""`, empty string `""` → `null`, garbage → `null`. Tested directly against the installed `1.5.0` package.

**How to avoid:** Check `!param` (the raw URL param) before calling decompress at all. Then check `!decompressed` (falsy) after decompress, covering both `null` and `""` returns. Do NOT rely on `=== null` alone.

### Pitfall 5: `navigator.clipboard.writeText` fails silently on HTTP (non-localhost)
**What goes wrong:** At a conference, if the app is served over plain HTTP (not localhost, not HTTPS), `navigator.clipboard.writeText` will either throw or return a rejected promise. The ShareButton's "¡Copiado!" state may trigger even though the clipboard was not actually written to.

**Why:** The Clipboard API requires a secure context (HTTPS or localhost). HTTP deployments on a public IP/domain won't have this.

**How to avoid:** The Phase 3 plan already wraps `navigator.clipboard.writeText` in `.catch(() => {})`. Preserve this. The URL still updates via `window.history.pushState` even when clipboard fails — the user can manually copy from the address bar. This is acceptable demo behavior. Do NOT remove the `.catch()`.

### Pitfall 6: `res.sendFile` requires an absolute path
**What goes wrong:** `res.sendFile('../client/dist/index.html')` throws `TypeError: path must be absolute` — Express enforces absolute paths for security.

**Why:** `res.sendFile` with a relative path requires an explicit `root` option. Easiest solution is to construct a fully resolved absolute path via `path.resolve` or `path.join(process.cwd(), ...)`.

**How to avoid:** Always use `path.join(process.cwd(), '../client/dist/index.html')` or `path.resolve(process.cwd(), '../client/dist/index.html')` — both produce absolute paths.

### Pitfall 7: Phase 3 plan 03-05 owns SHARE-01 and SHARE-02 — Phase 4 must not re-implement them
**What goes wrong:** The plan says "Plan A: Shareable URL — lz-string encode/decode, window.history.pushState, clipboard copy, ?r= mount check." But `03-05-PLAN.md` explicitly pulls SHARE-01 and SHARE-02 into Phase 3, with all the ShareButton and `?r=` load logic fully specified there. If Phase 4 re-implements these, there will be conflicts.

**Why:** The CONTEXT.md says "Phase 4 owns the error handling for corrupt `?r=` params and any unfinished shareable URL work." This is a conditional — Phase 4's URL work is ONLY what Phase 3 left incomplete.

**How to avoid:** Before planning Wave 1/Plan A, check whether `client/src/components/ShareButton.tsx` and the `?r=` load logic in `App.tsx` were completed in Phase 3. If they were, Plan A reduces to: (a) verify SHARE-01/02 work end-to-end, (b) add the corrupt URL error handling (SHARE-03) if not already present. Do not re-write code that Phase 3 already built.

---

## Existing Patterns in This Codebase

- **`__dirname` shim:** `server/src/index.ts` already imports `fileURLToPath` and constructs `__dirname` via the ESM-compatible shim (`const __filename = fileURLToPath(import.meta.url); const __dirname = path.dirname(__filename)`). The SPA catch-all can use the same `__dirname` — but use `process.cwd()` instead (see Pitfall 1 above).

- **Error state machine:** `useAnalysis.ts` exports `AppState = 'idle' | 'streaming' | 'complete' | 'error'` and already has an `'error'` state path. All four error cases (network failure, timeout, JSON parse error, 429) flow into `setState('error')` + `setError(message)`. The UI only needs to render appropriate messages for each error string — the hook's mechanics are already in place.

- **SSE error forwarding:** `useAnalysis.ts` lines 98-100 already handle `msg.type === 'error'` SSE events by calling `setError(msg.message)` and `setState('error')`. Timeout and malformed JSON errors from the server arrive this way — Phase 4 just needs to ensure the server sends the right Spanish message strings.

- **Spanish error copy convention:** All error messages throughout the codebase are in Spanish. The `analyze.ts` route already returns `"Demasiados análisis en curso. Intenta en unos segundos."` for 429. Any new error messages must follow this convention.

- **Tailwind color tokens:** `tailwind.config.js` defines `background: '#0a0a0f'`, `surface: '#13131a'`, `border: '#1f1f2e'`, `primary: '#7c3aed'`, `primary-light: '#a855f7'`. Error states should use `red-950/30` + `red-800` border + `red-300` text (pattern established in Phase 3 plan 03-05). Use these tokens, not raw hex values.

- **Responsive grid already started:** `Dashboard.tsx` already has `grid-cols-1 md:grid-cols-2` on the competitor and chart grids. Mobile responsiveness in Phase 4 extends this existing pattern to other components — it does not introduce a new approach.

- **`useAnalysis` hook shape is locked:** The hook returns `{ state, steps, result, error, submit, abort }`. Phase 4 error state UI consumes `error: string | null` directly — do not change the hook's return type or internal structure.

- **`AnalysisResult` type shape:** `client/src/types/analysis.ts` defines `competitors: Competitor[]` (can be empty array), `verdict`, `risks`, etc. The empty competitor check in Dashboard already exists: `{result.competitors.length > 0 && ...}`. The empty state card ("No se encontraron competidores directos — eso puede ser una ventaja.") is an `else` branch here, not a separate component.

- **ESM throughout:** `server/package.json` has `"type": "module"`. No `require()` anywhere. All new server code must use ESM `import`/`export` syntax.

- **`process.uptime()`** returns a float (seconds since process start). The `/api/health` addition is `uptime: process.uptime()` — no rounding needed.

---

## Recommended Approach

**Confidence: HIGH** on all four waves based on direct codebase inspection.

Wave 1 (Plan A + Plan B) can run in parallel because ShareButton/URL error handling touches `client/src/App.tsx` and error state UI touches `client/src/hooks/useAnalysis.ts` + error component rendering — they share `App.tsx` as a merge point, so coordinate carefully or serialize them. The safest approach is Plan B (error states) first since it modifies `useAnalysis.ts` independently, then Plan A verifies/completes the `?r=` work.

Wave 2 (Plan C, production build) is the highest-risk plan due to the `__dirname` path bug in `server/src/index.ts`. Fix the `express.static` path AND the catch-all simultaneously using `process.cwd()`-based paths, then do a real `npm run build && npm start && curl localhost:3001` end-to-end test before marking it done.

Wave 3 (Plan D, final polish) is low-risk incremental work — health endpoint additions are additive, mobile responsive tweaks use established Tailwind patterns, smooth scroll and empty state are small additions to `Dashboard.tsx`. The README is already partially written (`README.md` exists with structure); Phase 4 adds setup instructions and the `ANTHROPIC_API_KEY` env variable documentation.
