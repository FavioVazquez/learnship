# Phase 2: Analysis Engine — Research

**Researched:** 2026-05-26
**Phase goal:** POST /api/analyze streams a complete Claude analysis via SSE, verified with curl -N. No frontend.

---

## Don't Hand-Roll

| Problem | Recommended solution | Why |
|---------|---------------------|-----|
| Extracting final text from stream | Use `stream.finalMessage()` (returns `Promise<Message>`) then filter `content` for `type === 'text'` blocks | The SDK's `MessageStream` class accumulates the full message — calling `finalText()` concatenates all text blocks with a space, which is wrong if Claude emits a preamble before the JSON. Filter manually instead. |
| Accumulating tool input JSON | The SDK already does partial accumulation internally — `snapshotContent.input` on the snapshot contains a `partialParse()` result. But do NOT use this for final parsing: use the raw `input_json_delta` buffer approach described in CONTEXT.md for correctness at `content_block_stop` | The internal `partialParse` is for UI display only; it produces incomplete objects. The only safe parse point is `content_block_stop`. |
| Iterating over stream events | Use `for await (const event of stream)` — the `MessageStream` implements `[Symbol.asyncIterator]` which re-emits all `streamEvent` events in order | Mixing `.on('streamEvent', ...)` callbacks with `for await` on the same stream is safe but redundant. Pick one pattern: `for await` is cleaner for a single handler. |
| Getting the tool name at call-start | Read `event.content_block.name` on a `content_block_start` event where `event.content_block.type === 'tool_use'` | The tool name (`"web_search"`) is available immediately at block start — no need to wait for the full input JSON to describe the step to the user. |

---

## Common Pitfalls

### Pitfall 1: The `stream()` method returns synchronously — `await` goes inside the loop, not on the call

**What goes wrong:** Developers write `const stream = await client.messages.stream(...)`, which resolves the stream object immediately and is fine, but then forget that the stream itself is not yet consumed. The actual streaming work happens when you iterate with `for await`. If you skip the `for await` and jump straight to `await stream.finalMessage()`, you get the final result but never process intermediate events — so no `step` SSE events reach the client.

**Why:** `client.messages.stream()` (line 51 in SDK source) is synchronous — it creates a `MessageStream` and fires `_run()` internally. The HTTP request starts in the background. `for await` and `.finalMessage()` both drive consumption, but only `for await` lets you intercept intermediate events.

**How to avoid:** Always use `for await (const event of stream)` to process intermediate events, then call `await stream.finalMessage()` after the loop completes (or extract the final text from your own accumulated state inside the loop).

---

### Pitfall 2: `stream.finalText()` joins multiple text blocks with a space — wrong for JSON extraction

**What goes wrong:** The CONTEXT.md says "extract the last assistant text content block." `stream.finalText()` (SDK source, line 270–278) filters all text blocks and joins them with `' '` (a space). If Claude emits any preamble text before the JSON block (e.g., "Here is the analysis:" followed by a separate text block with the JSON), `finalText()` returns a corrupted string: `"Here is the analysis: {...}"` which fails `JSON.parse`.

**Why:** The SDK's `#getFinalText()` does `textBlocks.join(' ')` — not `.at(-1)`.

**How to avoid:** After `await stream.finalMessage()`, extract the last text block manually:
```ts
const msg = await stream.finalMessage()
const textBlocks = msg.content.filter(b => b.type === 'text')
const jsonText = textBlocks.at(-1)?.text ?? ''
const result = JSON.parse(jsonText) as AnalysisResult
```
This is resilient to preamble text.

---

### Pitfall 3: SSE headers must be set AND `res.flushHeaders()` called before the first `await`

**What goes wrong:** Developers set SSE headers but then do input validation or counter checks with async code before calling `flushHeaders()`. Node.js buffers the response until either enough data accumulates or headers are explicitly flushed. If `res.flushHeaders()` is called after an `await`, the client waits for that `await` to complete before receiving the 200 response — negating early connection establishment. In the worst case, if the first `await` throws, the response may fall through to Express's error handler which sends a `500` with `Content-Type: application/json` after SSE headers were already queued but not sent.

**Why:** Express buffers headers until `res.write()` or `res.end()` is called, unless `res.flushHeaders()` is called explicitly. The SSE contract requires the 200 OK and headers to arrive before any data.

**How to avoid:** Exact order must be:
1. Validate input body (synchronous) — return 400 if invalid (before SSE headers)
2. Check counter (synchronous) — return 429 if exceeded (before SSE headers)
3. Increment counter (synchronous)
4. Set SSE headers
5. `res.flushHeaders()` — IMMEDIATELY, no await yet
6. `try { await runAnalysis(...) } finally { activeAnalyses-- }`

---

### Pitfall 4: Missing `X-Accel-Buffering: no` in the SSE handler (not Vite proxy config)

**What goes wrong:** The Vite proxy config in `client/vite.config.ts` currently does NOT set `X-Accel-Buffering: no` — it only has `target` and `changeOrigin: true`. SSE events will be buffered by the Vite proxy in development if this header is missing from the Express response. The current proxy config is insufficient for SSE. (HIGH confidence — confirmed by reading `client/vite.config.ts`.)

**Why:** Vite's underlying `http-proxy` checks the response headers from upstream. When it sees `X-Accel-Buffering: no`, it disables its own buffering layer. Without it, the proxy buffers up to its internal threshold before forwarding.

**How to avoid:** Set the header on the Express SSE response, not in the proxy config:
```ts
res.setHeader('X-Accel-Buffering', 'no')
```
The CONTEXT.md already captures this — set it in the route handler alongside the other SSE headers. Do NOT try to fix it in `client/vite.config.ts`.

---

### Pitfall 5: The SDK `stream` object's `error` event throws into the `for await` loop — do NOT also attach a `.on('error', ...)` listener

**What goes wrong:** When a mid-stream error occurs (e.g., Anthropic overloaded_error, timeout), the SDK internally calls `_emit('error', ...)` which also calls `_rejectEndPromise`. This causes the `for await` loop to throw. If you also attach a `.on('error', handler)` listener AND have a `try/catch` around `for await`, the error is handled twice — once by the `.on` callback and once by the `catch` block — leading to double SSE error emission to the client.

**Why:** In `MessageStream._emit('error', ...)` (line 340–356 of SDK source), the error rejects the end promise AND notifies all `.on('error', ...)` listeners. The `for await` loop throws because the async iterator receives `reject` from the `readQueue`.

**How to avoid:** Use only one error handling path. With `for await`, wrap the whole loop in `try/catch`:
```ts
try {
  for await (const event of stream) {
    // handle events
  }
  const msg = await stream.finalMessage()
  // emit result
} catch (err) {
  sendSSE(res, { type: 'error', message: String(err) })
} finally {
  res.end()
}
```
Do not attach `.on('error', ...)` when using `for await`.

---

### Pitfall 6: Node.js single-threaded concurrency is safe for synchronous check-and-increment — but only if no `await` between check and increment

**What goes wrong:** If the counter check and increment are separated by any `await` (even a microtask-yielding one), two concurrent requests can both read `activeAnalyses = 2`, both pass the `>= 3` guard, and both increment to 3 — yielding 4 active analyses. This is NOT a thread-race (Node.js is single-threaded) but IS a cooperative-multitasking race.

**Why:** Node.js's event loop processes one task at a time, but `await` yields control back to the event loop. Between the `await` and resumption, another request can be processed.

**How to avoid:** Keep check and increment synchronous with no `await` between them:
```ts
// SAFE — both operations happen synchronously, no yield between them
if (activeAnalyses >= 3) return res.status(429).json({ error: '...' })
activeAnalyses++
// now it's safe to await
try {
  await runAnalysis(req, res)
} finally {
  activeAnalyses--
}
```
(MEDIUM confidence — this is definitively safe for synchronous Express route handlers; confirmed by Node.js event loop model.)

---

### Pitfall 7: `web_search_20250305` tool name in SDK vs API

**What goes wrong:** The tool is registered in the Anthropic API as `"web_search_20250305"`. The `content_block.name` on a `tool_use` block at stream time will be `"web_search_20250305"` (not `"web_search"`). If the step-event routing code does a string equality check against `"web_search"` it silently fails to emit step events.

**Why:** The tool is versioned by date. The name in stream events matches the name you pass in the `tools` array.

**How to avoid:** Either check for the prefix (`event.content_block.name.startsWith('web_search')`) or check for the exact string `"web_search_20250305"`. The CONTEXT.md correctly says to emit step events on ANY `tool_use` block start, not filtered by tool name — that is the correct approach and avoids this trap entirely.

---

### Pitfall 8: JSON extraction from final message will fail if Claude adds markdown code fences

**What goes wrong:** If the system prompt instructs Claude to "return ONLY valid JSON," Claude sometimes wraps the JSON in a markdown code block anyway:
````
```json
{...}
```
````
`JSON.parse()` on this string throws `SyntaxError: Unexpected token \``.

**Why:** Claude is trained to format code in markdown. "Return ONLY JSON" in the system prompt works most of the time but not always, especially when the model sees that its response will be displayed to a user.

**How to avoid:** Add a stripping step before `JSON.parse`:
```ts
const stripped = jsonText.replace(/^```(?:json)?\s*/m, '').replace(/\s*```\s*$/m, '').trim()
const result = JSON.parse(stripped) as AnalysisResult
```
This is a one-liner safety net with no downside.

---

### Pitfall 9: Missing `res.end()` after SSE stream completes leaves curl hanging

**What goes wrong:** `curl -N` (the verification criterion) will hang indefinitely after the `result` event if `res.end()` is not called. The SSE spec does not define a "stream end" frame — the server signals end by closing the connection.

**Why:** Express/Node.js SSE responses stay open until `res.end()` is explicitly called. The client (including curl) does not know the stream is done.

**How to avoid:** Always call `res.end()` in the `finally` block, after emitting the `result` event:
```ts
} finally {
  activeAnalyses--
  res.end()
}
```
Both error and success paths must call `res.end()`.

---

### Pitfall 10: `stop_reason: 'max_tokens'` produces truncated JSON — parsing will throw

**What goes wrong:** If the analysis prompt produces a response that exceeds Claude's output token limit, the stream ends with `stop_reason: 'max_tokens'`. The accumulated text block is an incomplete JSON string. `JSON.parse()` throws.

**Why:** Token limits are hit when the AnalysisResult is large (many competitors, long descriptions). Claude opus models have generous output limits but it can happen.

**How to avoid:** Check `stop_reason` before parsing. After the stream loop ends, call `stream.finalMessage()` and check `msg.stop_reason`:
```ts
const msg = await stream.finalMessage()
if (msg.stop_reason === 'max_tokens') {
  sendSSE(res, { type: 'error', message: 'El análisis fue demasiado largo. Intenta con una idea más corta.' })
  return
}
```

---

## Existing Patterns in This Codebase

- **ESM imports with `.js` extensions:** All server-side TypeScript imports use `.js` extensions (e.g., `import router from './routes/index.js'`). The installed Anthropic SDK also uses `.js` extensions internally. Follow this pattern in `server/src/routes/analyze.ts` and `server/src/agent/analyzer.ts`. Missing `.js` on local imports causes `ERR_MODULE_NOT_FOUND` at runtime.

- **Router pattern:** `server/src/routes/index.ts` uses `import { Router } from 'express'` and exports a single `router` default. The new `analyze.ts` route should export a Router or a handler function — not a standalone Express app. Mount it in `routes/index.ts` which is already imported by `server/src/index.ts`.

- **501 stub to replace:** `server/src/routes/index.ts` line 13–15 has `router.post('/api/analyze', ...)` returning 501. This ENTIRE handler must be replaced — do not patch around it. The `router` object itself stays, just swap the handler.

- **dotenv already loaded:** `import 'dotenv/config'` is the first line of `server/src/index.ts`. `process.env.ANTHROPIC_API_KEY` is available in any module loaded after server startup. No need to call `dotenv.config()` in the new route files.

- **TypeScript strict mode + no implicit any:** Both `server/tsconfig.json` patterns enforce strict. Error catches in TypeScript 4.x+ require explicit typing: `catch (err: unknown)` then `err instanceof Error ? err.message : String(err)`. Do not use `catch (err: any)`.

- **AnalysisResult and SSEMessage types:** Defined in `server/src/types/analysis.ts` (verified identical to client types). Import from `'../types/analysis.js'` in the new route files. The `SSEMessage` union type is the canonical shape for SSE event payloads — use it to type the `sendSSE` helper.

- **Installed SDK version is 0.30.1** (not 0.98.x): The `server/package.json` declares `^0.30.0` and `node_modules` contains `0.30.1`. The SDK source was read directly. `client.messages.stream()` exists at this version and returns a `MessageStream`. All the stream event types documented above were verified against the installed source. The ROADMAP and CONTEXT reference upgrading to 0.98.x — if that upgrade happened, verify the stream API hasn't changed (HIGH confidence it hasn't for the core streaming loop).

- **No compression middleware:** `server/src/index.ts` does not use the `compression` npm package. This means `res.flush()` is not needed — `res.write()` goes directly to the socket. Do not add compression middleware without also handling SSE route exclusion.

---

## Recommended Approach

**For the streaming loop:** Use `for await (const event of stream)` to process events, wrapped in a single `try/catch/finally`. Inside the loop, handle `content_block_start` (type `tool_use`) to emit `step` SSE events, accumulate `input_json_delta` into a per-block buffer, and call `JSON.parse` only on `content_block_stop`. After the loop, call `await stream.finalMessage()`, check `stop_reason`, extract the last text block manually (not via `finalText()`), strip markdown fences, then `JSON.parse` and emit the `result` SSE event. Call `res.end()` unconditionally in `finally`.

**For the route handler:** Keep the synchronous guard section (validation → counter check → counter increment → SSE headers → `flushHeaders()`) strictly in sequence before the first `await`. Export the Claude integration into `server/src/agent/analyzer.ts` so the route handler stays thin: validate, guard, set headers, call `runAnalysis(idea, country, res)`, done.

**For the system prompt:** Include an explicit instruction to return ONLY a raw JSON object with no markdown formatting, no preamble, no trailing commentary. Even so, implement the markdown fence stripping as a defensive measure — it costs nothing and prevents a silent failure mode that only surfaces during a live demo.

**For curl verification (the acceptance gate):** Test with `curl -N -X POST -H 'Content-Type: application/json' -d '{"idea":"app de delivery para mascotas en Guatemala"}' http://localhost:3001/api/analyze`. You should see `step` events appearing one by one (not batched), followed by a `result` event, followed by the connection closing cleanly. If events appear all at once, `X-Accel-Buffering: no` header is missing. If curl hangs after `result`, `res.end()` is not being called.
