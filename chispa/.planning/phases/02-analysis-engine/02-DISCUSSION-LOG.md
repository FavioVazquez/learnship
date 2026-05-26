# Phase 2: Analysis Engine - Discussion Log

**Date:** 2026-05-26
**Mode:** autonomous (all decisions pre-answered by user)
**Facilitator:** Claude (learnship discuss-phase workflow)

---

## Areas Covered

### 1. Route Contract

**Options considered:**
- GET with query params (rejected — SSE via GET doesn't support a request body cleanly)
- POST /api/analyze with JSON body (selected)
- WebSocket (rejected — SSE is simpler and fits the one-shot analysis pattern)

**Decision:** POST /api/analyze, body `{ idea: string, country?: string }`, validation 20–500 chars.

**Rationale:** Matches the established architecture decision (SSE over WebSockets). Country as optional param supports LatAm context without being required.

---

### 2. SSE Setup and Header Flushing

**Options considered:**
- Set headers and flush after async operations (rejected — buffering causes silent failures)
- Set headers synchronously, flush immediately before any await (selected)
- Use a middleware to handle SSE setup (rejected — adds indirection without benefit)

**Decision:** Set all 4 headers + call `res.flushHeaders()` as the very first operations in the handler body, synchronously, before any `await`.

**Rationale:** This is a known pitfall from Phase 1 research. Node.js will buffer the response until the first flush; if an error happens before flush, the client receives an HTTP error status instead of an SSE error event.

---

### 3. Claude Model and Streaming API

**Options considered:**
- `client.messages.create()` (rejected — non-streaming, can't emit step events)
- `client.messages.stream()` (selected)
- claude-sonnet-4-6 (rejected — opus-4-7 is more capable for research synthesis)

**Decision:** `claude-opus-4-7` with `client.messages.stream()`, `timeout: 90_000`.

**Rationale:** Model capability matters here — we're asking Claude to synthesize real web search results into a structured verdict. Sonnet is faster but less reliable for complex JSON synthesis. 90s timeout matches the <120s requirement with buffer.

---

### 4. JSON Accumulation Strategy

**Options considered:**
- Parse each `input_json_delta` as it arrives (rejected — partial JSON throws SyntaxError)
- Buffer all `input_json_delta` strings, parse on `content_block_stop` (selected)
- Use a streaming JSON parser library (rejected — unnecessary dependency)

**Decision:** String concatenation into a buffer variable; single `JSON.parse()` call on `content_block_stop`.

**Rationale:** This is explicitly documented as a critical pitfall in Phase 2 research. The Anthropic streaming API sends JSON fragments, not complete JSON objects.

---

### 5. Step Events

**Options considered:**
- Emit one step event per search query (dynamic, maps to actual queries)
- Emit fixed step events keyed to tool_use block starts (selected)
- No step events until analysis complete (rejected — kills the "live" feel)

**Decision:** Emit a step event on each `tool_use` content block start, cycling through 4 fixed Spanish descriptions.

**Rationale:** The Spanish-first UX is established in the project. Fixed descriptions are simpler to implement and still communicate meaningful progress to the user. The exact mapping between descriptions and search queries is agent's discretion.

---

### 6. Rate Limiting

**Options considered:**
- Redis-backed rate limiter (rejected — no Redis, overkill for demo)
- `express-rate-limit` middleware (rejected — doesn't protect in-flight SSE streams, only new requests)
- In-memory counter with synchronous check-and-increment + try/finally (selected)

**Decision:** Module-level `let activeAnalyses = 0`, synchronous check, increment before async work, decrement in `finally`.

**Rationale:** The synchronous check is critical — async operations between check and increment would create a race condition. `try/finally` guarantees the counter is always decremented, preventing counter leak on errors.

---

### 7. File Organization

**Options considered:**
- Everything in routes/index.ts (rejected — mixes concerns, makes Phase 3 integration harder)
- Route handler + agent logic in separate files (selected)
- Shared module for SSE helpers (agent's discretion)

**Decision:** `server/src/routes/analyze.ts` for Express route handler; `server/src/agent/analyzer.ts` for Claude integration logic. Replace 501 stub in `routes/index.ts`.

---

## Areas Delegated to Agent's Discretion

- Exact system prompt wording (constraints are specified, phrasing is open)
- Whether step descriptions rotate sequentially or map to specific tool call types
- Internal TypeScript types for SSE frame construction
- Whether to extract a `sendSSE()` helper function

---

## Deferred Ideas

None raised during this session.

---

*This log is for human audit only. Downstream agents read 02-CONTEXT.md, not this file.*
