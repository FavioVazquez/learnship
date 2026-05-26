# Chispa Build — Agentic Learning Reflections

> Captured from the Chispa live demo build for AI Week Summit Guatemala 2026.
> Chispa is a startup idea validator powered by Claude with web_search, streaming SSE, and an animated React dashboard.
> Built using learnship workflows run headlessly via `claude -p`.

---

## 1. Claude SDK Streaming API

**What we thought before**
`create()` and `stream()` were interchangeable — just call `finalMessage()` whenever you need the result, even inside the loop.

**What we discovered**
`stream()` surfaces intermediate tool call events that `create()` hides. Calling `finalMessage()` inside the `for await` loop crashes because the stream is still open; the SDK throws when you try to read the final message before iteration completes.

Tool call detection requires watching for `content_block_start` events where `content_block.type === 'tool_use'` — that is the only reliable signal that Claude has decided to invoke a tool during a streaming response.

**The rule**
> Use `stream()` for live tool call visibility. Iterate the full `for await` loop to completion, then call `finalMessage()` exactly once, outside the loop.

**When it matters**
Any time you stream a response that may include tool calls — validation pipelines, agentic research, anything where users benefit from seeing "Claude is searching…" in real time.

---

## 2. SSE in Node.js Express

**What we thought before**
SSE headers could be set at any point before the first `write()`, and rate limiting could use async database checks without special ordering concerns.

**What we discovered**
`res.flushHeaders()` must fire synchronously before any `await`. If an `await` runs first, Express may buffer or drop the initial handshake, leaving the client hanging. Rate limiting must be a synchronous check-and-increment — async checks introduce a race where concurrent requests all pass the limit simultaneously. The decrement on cleanup must live in a `try/finally` block so it runs even when the stream errors or the client disconnects.

Required headers for reliable streaming across proxies:
- `Content-Type: text/event-stream`
- `X-Accel-Buffering: no`
- `Cache-Control: no-cache`

**The rule**
> Call `res.flushHeaders()` synchronously on the first line of an SSE handler. Rate-limit synchronously. Always decrement in `try/finally`.

**When it matters**
Every SSE endpoint in Express, especially behind nginx or any reverse proxy. The `X-Accel-Buffering: no` header is the difference between a live stream and a blank page until the response ends.

---

## 3. SSE Consumption in React

**What we thought before**
`EventSource` is the browser's native SSE API — use it for SSE. A simple `isLoading` boolean is enough to represent streaming state.

**What we discovered**
`EventSource` only supports GET requests. Sending a startup-idea payload in the body requires `fetch()` with `ReadableStream` decoding instead. The cleanup function of a `useEffect` must call `AbortController.abort()` — without it, navigating away or re-mounting the component leaves the old connection alive and leaks memory. A boolean `isLoading` flag cannot represent the full lifecycle; a state machine with explicit states is necessary to avoid impossible UI combinations.

States needed: `idle → streaming → complete | error`

**The rule**
> Use `fetch()` + `ReadableStream` for POST-based SSE. Always abort in `useEffect` cleanup. Model state as a machine, not a boolean.

**When it matters**
Any React component that opens a long-lived server connection: chat interfaces, progress streams, live validation — anywhere the component might unmount before the server finishes.

---

## 4. JSON Safety with Streaming LLMs

**What we thought before**
If the prompt instructs the model not to wrap output in markdown code fences, it won't. Checking `stop_reason` is optional bookkeeping. Input JSON from tool results can be parsed as soon as bytes arrive.

**What we discovered**
Models add markdown fences anyway — even when explicitly instructed not to. A response truncated by `max_tokens` produces partial JSON that throws on parse. Streaming tool input arrives as `input_json_delta` chunks that must be accumulated into a buffer; only the `content_block_stop` event signals that the buffer is complete and safe to parse.

**The rule**
> Strip markdown fences before every `JSON.parse()`. Check `stop_reason === 'max_tokens'` before parsing. Accumulate `input_json_delta` into a buffer; parse only on `content_block_stop`.

**When it matters**
Every place in a streaming pipeline where you call `JSON.parse()` on model output — report generation, structured extraction, tool result handling. One missing fence-strip silently breaks production for a subset of responses.

---

## 5. Shareable URL State Compression

**What we thought before**
Base64-encoding the response and putting it in a URL parameter is a straightforward way to make results shareable. URL length limits are a vague concern for extreme edge cases.

**What we discovered**
Claude's verbose JSON output, base64-encoded, routinely exceeds nginx's default 8 KB header/URI limit — resulting in 414 or 502 errors that are difficult to trace. `lz-string`'s `compressToEncodedURIComponent` achieves roughly 60% compression, bringing most payloads under the limit. Decoding must be wrapped in `try/catch` because both base64 and lz-string decoding can throw on corrupt or truncated input (e.g., a URL that was copy-pasted with characters stripped).

**The rule**
> Compress shareable state with `lz-string` before base64. Always wrap URL decode in `try/catch`. Validate decoded output before rendering.

**When it matters**
Any feature that encodes state into a URL: share links, permalink results, report export. The pain appears only in production when URLs pass through nginx or load balancers with conservative header-size defaults.

---

## 6. ESM + TypeScript on Node 20+

**What we thought before**
`ts-node` is the standard way to run TypeScript on Node. Import paths in TypeScript source files can omit the extension — TypeScript resolves them.

**What we discovered**
`ts-node` has ESM resolution bugs on Node 20+ that produce cryptic `ERR_UNKNOWN_FILE_EXTENSION` and module-not-found errors that are hard to diagnose. `tsx` is a drop-in replacement that handles ESM correctly. Even though the source files are `.ts`, import paths must use the `.js` extension — Node's ESM resolver looks for the compiled output, and TypeScript's `--moduleResolution bundler` or `node16` modes require this. Running a React dev server alongside an Express API server requires `concurrently` (or `npm-run-all`) rather than two separate terminal sessions.

**The rule**
> Use `tsx` over `ts-node` on Node 20+. Write import paths with `.js` extensions in TypeScript source. Use `concurrently` for multi-server dev.

**When it matters**
Any Node 20+ project using ESM (`"type": "module"` in `package.json`) with TypeScript. The `.js` extension requirement surprises every TypeScript developer the first time they encounter it.

---

## 7. Learnship Headless Orchestration

**What we thought before**
Workflow prompts that ask the user questions require interactive sessions. Phases must run sequentially. Config keys are flat and any format works.

**What we discovered**
`AskUserQuestion` calls in workflows can be bypassed by prepending a large pre-answers context block at the top of the prompt — the model reads it as ground truth and skips interactive questions. `discuss-phase` (capturing decisions) is independent from code-writing phases and can be parallelized when the decisions are already known. Config keys in `config.json` must be nested (`{ "project": { "name": "..." } }`) — flat keys are read without errors but silently fail to populate workflow variables, causing mysterious empty outputs.

**The rule**
> Prepend pre-answers context to bypass interactive questions in headless runs. Parallelize discuss-phase with code phases. Always use nested keys in learnship config.json.

**When it matters**
Any learnship workflow run via `claude -p` in CI or automated pipelines — demos, automated scaffolding, batch phase execution. The flat-key config failure is especially insidious because it produces no error output.

---

## Summary Table

| Area | Core Rule |
|---|---|
| Claude SDK streaming | `for await` to completion, then `finalMessage()` once |
| Express SSE | `flushHeaders()` before any `await`; rate-limit sync; `try/finally` |
| React SSE | `fetch()` + `ReadableStream` for POST; abort in cleanup; state machine |
| JSON + streaming | Strip fences; check `stop_reason`; accumulate then parse |
| URL compression | lz-string compress; `try/catch` decode; validate before render |
| ESM + TypeScript | `tsx` not `ts-node`; `.js` extensions; `concurrently` for multi-server |
| Learnship headless | Pre-answers context; parallelize phases; nested config keys |

---

*Generated via `/agentic-learning reflect` — Chispa build, AI Week Summit Guatemala 2026.*
