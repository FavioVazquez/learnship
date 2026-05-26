# Architecture Research: Chispa Real-Time AI Streaming App

Researched: 2026-05-26
Sources: Anthropic SDK official docs (HIGH confidence), Vite official docs (HIGH confidence), community patterns verified via WebSearch (MEDIUM confidence)

---

## Component Boundaries

### Physical Components

```
┌─────────────────────────────────────────────────────────────────┐
│  BROWSER                                                         │
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │  React App (port 5173 dev / port 3001 prod)             │    │
│  │                                                          │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────┐ │    │
│  │  │  IdeaForm    │  │ ActivityFeed │  │  Dashboard    │ │    │
│  │  │  Component   │  │  Component   │  │  Component    │ │    │
│  │  │              │  │              │  │               │ │    │
│  │  │ POST /api/   │  │ SSE listener │  │ Reads ?r=     │ │    │
│  │  │ analyze      │  │ (EventSource)│  │ param,        │ │    │
│  │  └──────────────┘  └──────────────┘  │ atob() decode │ │    │
│  │                                       └───────────────┘ │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
                          │ HTTP/SSE
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  EXPRESS SERVER (port 3001)                                      │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Route: POST /api/analyze                                 │  │
│  │                                                           │  │
│  │  1. Validate request body (idea, description)             │  │
│  │  2. Check concurrent analysis counter (max 3)             │  │
│  │  3. Set SSE headers on response                           │  │
│  │  4. Pipe Claude stream events → SSE writes                │  │
│  │  5. On tool_use event → send {type:"step"} SSE event      │  │
│  │  6. On message_stop → send {type:"result"} SSE event      │  │
│  │  7. Decrement counter, close connection                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Route: GET /api/health                                   │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │  Static file serving: client/dist (production only)       │  │
│  └───────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                          │ HTTPS
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│  ANTHROPIC API                                                   │
│                                                                  │
│  @anthropic-ai/sdk  client.messages.stream()                    │
│  Model: claude-opus-4-7                                          │
│  Tool: web_search_20250305                                       │
│                                                                  │
│  Streams SSE events back to Express                              │
└─────────────────────────────────────────────────────────────────┘
```

### Boundary Rules

- **Client never calls Anthropic directly.** All Claude API calls go through the Express backend. The API key never reaches the browser.
- **Express is stateless per request.** No session data persists between requests. The only shared state is the concurrent analysis counter (module-level integer in the route handler).
- **SSE is one-directional.** Client cannot cancel in-flight analysis via SSE. If needed, a separate DELETE /api/analyze/:id endpoint would be required (out of scope for now).
- **URL is the only persistence layer.** `?r=<base64json>` query param carries the full `AnalysisResult` object. No database, no server-side state.
- **Vite proxy is dev-only.** In production, Express serves the React build from `client/dist`. The proxy config in `vite.config.ts` only applies during `vite dev`.

---

## Data Flow

### Flow 1: Analysis Request (Happy Path)

```
User types idea → IdeaForm submit
        │
        ▼
POST /api/analyze
Body: { idea: string, description: string }
        │
        ├─ [Guard] concurrent >= 3 → SSE {type:"error"} → 429
        │
        ▼
Express sets SSE response headers:
  Content-Type: text/event-stream
  Cache-Control: no-cache
  Connection: keep-alive
  X-Accel-Buffering: no        ← prevents nginx buffering
        │
        ▼
client.messages.stream({
  model: "claude-opus-4-7",
  tools: [web_search_20250305],
  messages: [{ role: "user", content: <constructed prompt> }]
})
        │
        ├──── Anthropic emits: content_block_start { type: "tool_use" }
        │         │
        │         ▼
        │     Express writes SSE event to browser:
        │     data: {"type":"step","text":"Searching for competitors..."}
        │     (blank line to flush)
        │
        ├──── Anthropic emits: content_block_delta (input_json_delta)
        │         │
        │         └── Accumulate partial JSON (do NOT emit to client yet)
        │
        ├──── Anthropic emits: content_block_stop
        │         │
        │         └── Tool input is now complete; Express executes search
        │             (web_search tool is invoked by the SDK / Anthropic)
        │
        ├──── Anthropic emits: message_delta { stop_reason: "end_turn" }
        │         │
        │         └── Parse accumulated text block as AnalysisResult JSON
        │
        └──── Anthropic emits: message_stop
                  │
                  ▼
              Express writes final SSE event:
              data: {"type":"result","data":{...AnalysisResult}}

              Then closes response.
```

### Flow 2: Error Path

```
Anthropic API error / timeout
        │
        ▼
Express catches exception in stream handler
        │
        ▼
Writes SSE event: data: {"type":"error","message":"..."}
        │
        ▼
Decrements concurrent counter
Ends response
```

### Flow 3: Shareable URL Load

```
User visits /?r=<base64json>
        │
        ▼
App.tsx mounts
        │
        ▼
useEffect reads window.location.search
new URLSearchParams(search).get('r')
        │
        ├─ null → render IdeaForm (fresh session)
        │
        └─ string present →
               atob(param) → JSON.parse → AnalysisResult
               setState(result) → render Dashboard directly
               (no network request; fully offline-capable)
```

### SSE Wire Format

Each message sent by Express follows the SSE spec (HIGH confidence — MDN + Anthropic docs):

```
data: {"type":"step","text":"Searching for competitors..."}\n\n
data: {"type":"step","text":"Analyzing market size..."}\n\n
data: {"type":"result","data":{...}}\n\n
```

The double newline (`\n\n`) is mandatory — it signals end-of-event to the browser's `EventSource` parser. Omitting it causes the browser to buffer and never fire the `onmessage` handler.

### EventSource Client Pattern (React)

```typescript
// Inside the submit handler — do NOT use fetch() for SSE
const source = new EventSource('/api/analyze?' + params)
// OR: POST body requires a polyfill since EventSource only supports GET
// Recommended: use fetch with ReadableStream for POST + SSE hybrid
// (see Integration Points for the POST vs GET tradeoff)

source.onmessage = (e) => {
  const msg = JSON.parse(e.data)
  if (msg.type === 'step') appendActivity(msg.text)
  if (msg.type === 'result') transitionToDashboard(msg.data)
  if (msg.type === 'error') showError(msg.message)
}
source.onerror = () => { source.close(); showError('Connection lost') }
```

---

## Build Order

Build in this sequence — each phase gates the next:

### Phase 1 — Foundation (DONE)
- Express + TypeScript server scaffold
- Vite + React client scaffold
- Vite proxy config (`/api` → `localhost:3001`)
- Shared `AnalysisResult` and `SSEMessage` TypeScript types
- `GET /api/health` endpoint

**Gate:** `curl localhost:3001/api/health` returns 200. Client loads at 5173.

### Phase 2 — Claude + SSE Engine
- Implement `POST /api/analyze` route
- Set SSE headers before streaming begins
- Call `client.messages.stream()` with `web_search_20250305` tool
- Translate Claude stream events to SSE events (`step`, `result`, `error`)
- Module-level concurrent counter with guard (reject if >= 3)
- Prompt engineering: instruct Claude to return final answer as JSON matching `AnalysisResult`

**Gate:** `curl -N localhost:3001/api/analyze` streams SSE events to terminal. `step` events appear while search runs. `result` event contains valid `AnalysisResult` JSON.

### Phase 3 — React UI
- `IdeaForm` component: idea title + description inputs, submit → POST
- Switch to `fetch` + `ReadableStream` for POST-based SSE (EventSource only supports GET)
- `ActivityFeed` component: renders `step` events as they arrive
- State machine: `idle` → `loading` → `done` / `error`
- `Dashboard` component: renders `AnalysisResult` (competitors, verdict, risks, market)
- URL write: on `result` event, `btoa(JSON.stringify(data))` → push to `?r=` param

**Gate:** Full analysis flow works in browser. URL updates on completion.

### Phase 4 — Shareable URLs
- On mount, read `?r=` param
- `atob` → `JSON.parse` → validate shape → render Dashboard
- Handle malformed base64 gracefully (try/catch → redirect to IdeaForm)
- Copy-link button in Dashboard UI

**Gate:** Pasting a `?r=` URL into a new tab renders the dashboard without any network call to `/api/analyze`.

### Phase 5 — Polish
- Loading states, skeleton screens, Framer Motion transitions
- Recharts for market size visualization
- Error boundary for malformed URL params
- Responsive layout (Tailwind)
- Production build: `vite build` → Express serves `client/dist`

---

## Integration Points

### 1. POST vs GET for SSE (HIGH risk)

**Problem:** The native browser `EventSource` API only supports GET requests. The `/api/analyze` endpoint must receive a POST body (idea text). This is a fundamental incompatibility.

**Resolution:** Use `fetch()` with `ReadableStream` instead of `EventSource`.

```typescript
const response = await fetch('/api/analyze', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ idea, description }),
})
const reader = response.body!.getReader()
const decoder = new TextDecoder()
while (true) {
  const { done, value } = await reader.read()
  if (done) break
  const text = decoder.decode(value)
  // parse SSE text manually: split on '\n\n', extract 'data:' lines
}
```

This is the correct modern pattern (MEDIUM confidence — widely used, no official standard for POST+SSE but well-established in practice). The alternative is encoding the idea as a GET query string, but that limits length and exposes data in server logs.

### 2. Vite Dev Proxy and SSE Buffering

**Problem:** Vite's dev proxy (http-proxy under the hood) may buffer streaming responses, causing SSE events to arrive in batches rather than individually.

**Resolution:** Add `X-Accel-Buffering: no` response header in Express. Vite 5.x passes this header through and disables its own buffering. Also set `changeOrigin: true` in `vite.config.ts` (already in place).

If buffering persists in development, setting `configure` on the proxy to forward the response directly resolves it:
```typescript
proxy: {
  '/api': {
    target: 'http://localhost:3001',
    changeOrigin: true,
    configure: (proxy) => {
      proxy.on('proxyRes', (proxyRes) => {
        proxyRes.headers['x-accel-buffering'] = 'no'
      })
    },
  },
}
```

### 3. Concurrent Analysis Limiter

**Problem:** Each SSE connection holds an open TCP connection and an active Anthropic API call. Unbounded concurrency risks rate limit hits and memory growth.

**Resolution:** Module-level counter in the route file (not middleware):

```typescript
let activeAnalyses = 0
const MAX_CONCURRENT = 3

router.post('/api/analyze', (req, res) => {
  if (activeAnalyses >= MAX_CONCURRENT) {
    res.setHeader('Content-Type', 'text/event-stream')
    res.write(`data: ${JSON.stringify({ type: 'error', message: 'Server busy. Try again in a moment.' })}\n\n`)
    return res.end()
  }
  activeAnalyses++
  // ... stream logic ...
  // in finally block:
  activeAnalyses--
  res.end()
})
```

Use `try/finally` to guarantee decrement even on Anthropic API errors. (HIGH confidence — standard Node.js pattern.)

### 4. Claude Tool Use Event Sequence

**Problem:** `content_block_start` with `type: "tool_use"` fires before the tool input is fully streamed. The tool name is available immediately, but the input (search query) is streamed as `input_json_delta` fragments.

**Resolution:** Emit the `step` SSE event on `content_block_start` (tool name is sufficient for user feedback). Do not wait for the full input JSON before telling the user a search is happening.

Anthropic SDK TypeScript event sequence (HIGH confidence — from official docs):
```
message_start
content_block_start  { type: "tool_use", name: "web_search" }   ← emit step event here
content_block_delta  { type: "input_json_delta", partial_json: "{\"q..." }
content_block_delta  { type: "input_json_delta", partial_json: "uery\"...}" }
content_block_stop
content_block_start  { type: "text" }                            ← Claude's response text
content_block_delta  { type: "text_delta", text: "..." }
content_block_stop
message_delta        { stop_reason: "end_turn" }
message_stop                                                      ← emit result event here
```

### 5. Base64 URL Safety

**Problem:** Standard `btoa()` produces `+`, `/`, and `=` characters. These break URL query params if not encoded.

**Resolution:** Always wrap with `encodeURIComponent` when writing to URL, and `decodeURIComponent` when reading:

```typescript
// Write
const encoded = encodeURIComponent(btoa(JSON.stringify(result)))
window.history.pushState({}, '', `?r=${encoded}`)

// Read
const raw = new URLSearchParams(window.location.search).get('r')
if (raw) {
  try {
    const result = JSON.parse(atob(decodeURIComponent(raw)))
    // render dashboard
  } catch {
    // malformed — redirect to home
  }
}
```

For typical `AnalysisResult` objects (< 5KB of JSON), base64 expansion (~33% overhead) fits comfortably within browser URL length limits (~64KB). No compression needed. (MEDIUM confidence — tested pattern, no official limit documentation found for modern browsers at this size.)

### 6. Production Build: Static File Serving Order

**Problem:** Express serves both API routes and the React SPA. React uses client-side routing (if added later). Express must not intercept React's routes.

**Resolution:** The current `index.ts` structure is correct — `app.use(router)` (API routes) comes before static file serving would catch all routes. Add a catch-all for SPA routing if React Router is introduced:

```typescript
app.use(express.static(path.join(__dirname, '../../client/dist')))
app.get('*', (_req, res) => {
  res.sendFile(path.join(__dirname, '../../client/dist/index.html'))
})
```

Register this after all API routes to avoid intercepting `/api/*` paths.

---

## Key Verified Facts

- `@anthropic-ai/sdk ^0.30.0` is already installed. Use `client.messages.stream()` — it returns an async stream that fires named events. (HIGH confidence — package.json confirmed.)
- The SDK's TypeScript stream helper fires `.on('message', ...)`, `.on('text', ...)`, and raw `.on('streamEvent', ...)`. Use `streamEvent` to intercept `content_block_start` for tool detection. (HIGH confidence — Anthropic docs.)
- Vite 5.x proxy works correctly for SSE with the `X-Accel-Buffering: no` header. (MEDIUM confidence — community verified, no official Vite docs entry found.)
- `EventSource` does not support POST. `fetch` + `ReadableStream` is the correct substitute. (HIGH confidence — MDN spec.)
- Base64 with `encodeURIComponent` wrapping is the established shareable URL pattern. No external library needed for this payload size. (HIGH confidence — multiple sources.)
