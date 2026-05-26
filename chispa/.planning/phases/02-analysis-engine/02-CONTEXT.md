# Phase 2: Analysis Engine - Context

**Gathered:** 2026-05-26
**Mode:** autonomous (all decisions pre-answered)
**Status:** Ready for planning

<domain>
## Phase Boundary

POST /api/analyze streams a complete Claude analysis via SSE. The endpoint accepts an idea string, calls Claude with web_search_20250305, and streams step + result events back to the client. Verified with curl -N. No frontend work in this phase.

</domain>

<decisions>
## Implementation Decisions

### Route Contract
- Method: POST /api/analyze
- Body: `{ idea: string, country?: string }`
- Validation: idea must be 20–500 chars; return 400 with `{ error: string }` JSON if invalid

### SSE Setup
- Headers set synchronously, immediately on request receipt (before any `await`):
  - `Content-Type: text/event-stream`
  - `Cache-Control: no-cache`
  - `Connection: keep-alive`
  - `X-Accel-Buffering: no`
- Call `res.flushHeaders()` immediately after setting headers, BEFORE any `await`
- SSE event format: `data: <JSON>\n\n` on each line

### Claude Integration
- Model: `claude-opus-4-7`
- Tool: `web_search_20250305`
- Client constructor must include `timeout: 90_000`
- Streaming: use `client.messages.stream()` — NOT `client.messages.create()`
- API key loaded from `process.env.ANTHROPIC_API_KEY` (never exposed to client)

### JSON Accumulation (critical — no partial parsing)
- On `input_json_delta` events: append `delta.partial_json` to a buffer string
- On `content_block_stop` events: `JSON.parse()` the accumulated buffer — this is the ONLY place JSON.parse is called on tool input
- NEVER call JSON.parse on partial JSON fragments

### Step Events
- On each `tool_use` content block start event, emit:
  ```
  { type: "step", text: "<Spanish description>", source: "<domain>" }
  ```
- Spanish descriptions for each tool invocation (rotate through as tool calls happen):
  1. "Buscando competidores directos..."
  2. "Analizando el mercado..."
  3. "Revisando actividad de inversión..."
  4. "Sintetizando resultados..."

### Result Event
- After `client.messages.stream()` completes, extract the last assistant text message from the stream
- Parse it as JSON → must conform to `AnalysisResult` shape
- Emit: `{ type: "result", data: <AnalysisResult> }`
- Set `searchedAt` to `new Date().toISOString()` if not already present in Claude's output

### Error Handling
- Wrap the entire SSE handler body in `try/catch`
- On any error: emit `{ type: "error", message: string }` then call `res.end()`
- Never let an error propagate to Express's error handler — that would send an HTTP error after SSE headers are already sent

### Rate Limiting (in-memory, synchronous)
- Module-level counter: `let activeAnalyses = 0`
- Synchronous check-and-increment at handler entry (before any async):
  ```ts
  if (activeAnalyses >= 3) return res.status(429).json({ error: "Too many concurrent analyses" })
  activeAnalyses++
  ```
- Decrement in `finally` block: `activeAnalyses--` — guaranteed to run even on error

### System Prompt
Claude system prompt must instruct:
1. Search for REAL competitors using web search (not hallucinated names)
2. When `country` is provided, focus on LatAm market context and region-specific competitors
3. Return ONLY valid JSON matching the `AnalysisResult` shape as the final assistant message
4. `firstSteps` must contain exactly 5 items (only meaningful for LAUNCH/VALIDATE verdicts)

### File Organization
- `server/src/routes/analyze.ts` — Express route handler (SSE setup, validation, rate limiting, SSE emit helpers)
- `server/src/agent/analyzer.ts` — Claude integration logic (stream setup, event handling, JSON accumulation)
- `server/src/routes/index.ts` — import and mount the new route, remove the 501 stub

### Agent's Discretion
- Exact system prompt wording (beyond the 4 constraints above)
- Whether step descriptions rotate sequentially or map to specific search query types
- Internal TypeScript helper types for SSE frame construction

</decisions>

<specifics>
## Specific Ideas

- The `source` field in step events should reflect the domain being searched (e.g., "web_search") — pass the tool name or a derived label
- Country context in system prompt: "Si se especificó un país, prioriza competidores y contexto de mercado en Latinoamérica y especialmente en [country]"
- The 501 stub in routes/index.ts must be replaced entirely, not patched

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

- `client/src/types/analysis.ts` — canonical AnalysisResult and SSEMessage types; do not change the shape
- `server/src/types/analysis.ts` — server-side copy; keep in sync with client types
- `.planning/ROADMAP.md` Phase 2 section — requirements covered (ANLYS-02 through SAFE-03)
- `.planning/REQUIREMENTS.md` — full requirement definitions for cross-reference

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `client/src/types/analysis.ts` and `server/src/types/analysis.ts`: `AnalysisResult`, `SSEMessage`, `Competitor`, `Risk` — these are the Phase 2 contract; import from server types in the new route
- `server/src/routes/index.ts`: existing router with health endpoint — import and mount analyze route here

### Established Patterns
- ESM throughout (`import`/`export`, `.js` extensions in TypeScript imports) — follow this, no `require()`
- `dotenv/config` imported in `server/src/index.ts` — env vars are available at route handler time
- TypeScript strict mode — no implicit `any`, no untyped error catches
- Express 4.x — `Router()` pattern, no Express 5 async error handling

### Integration Points
- `server/src/routes/index.ts`: the 501 stub for POST /api/analyze must be replaced with the new handler
- `server/src/index.ts`: no changes needed — already imports and uses the router
- The Vite proxy in `client/vite.config.ts` already forwards `/api/*` to port 3001 — no proxy changes needed for SSE (X-Accel-Buffering header is set in the handler, not the proxy)

</code_context>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---
*Phase: 02-analysis-engine*
*Context gathered: 2026-05-26*
