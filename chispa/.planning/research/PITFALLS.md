# PITFALLS.md — Chispa Real-Time AI Streaming App

Research date: 2026-05-26. Sources verified against official Anthropic docs and community production reports.

---

## Common Mistakes

### 1. Parsing tool_use JSON Before content_block_stop

**What happens:** The Claude SDK streams tool input as partial JSON string fragments via `input_json_delta` events. Each `content_block_delta` carries a `partial_json` string — NOT a valid JSON object. Developers who try to `JSON.parse()` on individual delta fragments will crash on every call.

**Official warning (HIGH confidence):** The Anthropic fine-grained tool streaming docs explicitly state: "you may potentially receive invalid or partial JSON inputs." The `content_block_start` event for a `tool_use` block sets `input: {}` (an empty object placeholder), while actual data arrives later as string fragments. The correct pattern is:
1. On `content_block_start` with type `tool_use`: initialize `inputJson = ""`
2. On each `input_json_delta`: append `event.delta.partial_json` to `inputJson`
3. On `content_block_stop`: call `JSON.parse(inputJson)` — only here

**Additional risk:** If `stop_reason` is `max_tokens`, the stream ends mid-parameter. The accumulated string is permanently incomplete. Code must check stop reason before parsing.

---

### 2. Not Handling error Events Inside the SSE Stream

**What happens:** A streaming response begins with HTTP 200, then errors mid-stream. Standard HTTP error handling (checking status codes) misses these. The Anthropic API can emit an `event: error` SSE frame mid-stream — most commonly an `overloaded_error` during high-traffic periods. If the client only listens for `message_stop`, it silently drops errors.

**Official confirmation (HIGH confidence):** From Anthropic streaming docs: "The API may occasionally send errors in the event stream. For example, during periods of high usage, you may receive an `overloaded_error`, which would normally correspond to an HTTP 529 in a non-streaming context."

Example error frame:
```
event: error
data: {"type": "error", "error": {"type": "overloaded_error", "message": "Overloaded"}}
```

Forwarding this raw SSE event to the browser without a catch means the React client never sees a usable error state — the stream just ends.

---

### 3. No Read Timeout on the Claude Streaming Connection

**What happens:** If the Anthropic API stalls (network partition, model hang), the Express server's HTTP connection to the API stays open indefinitely. This is documented as a real production bug in the Claude Code codebase itself (GitHub issue #25979). With Chispa's 120-second requirement, an undetected stall eats the full slot in the 3-concurrent limit without ever resolving.

**Risk:** Each stalled request holds one of the 3 concurrent analysis slots permanently. Three simultaneous stalls = full deadlock.

**Prevention:** Set an explicit read/response timeout on the `axios` or `fetch` call to the Anthropic API — something shorter than 120s (90s is safe). The Anthropic SDK's `timeout` option covers this.

---

### 4. SSE Proxy Buffering Silently Breaks Streaming

**What happens:** Intermediate proxies (nginx, AWS ALB, Cloudflare) see an HTTP response with no `Content-Length` and buffer the entire response before forwarding. From the browser's perspective, nothing arrives until the analysis is complete — defeating the live feed entirely. This is not obvious in development (Vite's dev proxy doesn't buffer), but breaks in any deployed environment.

**Required headers on every SSE response (HIGH confidence):**
```
Content-Type: text/event-stream
Cache-Control: no-cache
X-Accel-Buffering: no       // nginx-specific
Connection: keep-alive
```

Missing any of these, especially `X-Accel-Buffering: no`, causes silent buffering that is very hard to debug because the data eventually arrives — just all at once.

---

### 5. SSE Connection Leaks in React from Missing useEffect Cleanup

**What happens:** React components that open an `EventSource` in `useEffect` without returning a cleanup function leave the connection open after unmount. In Chispa, if the user navigates away during analysis or the component re-renders (e.g., hot reload), the old `EventSource` keeps receiving events and firing handlers on an unmounted component. This causes React "Can't perform a state update on an unmounted component" warnings and potentially a memory leak that grows with each analysis.

**The fix is mandatory:**
```typescript
useEffect(() => {
  const es = new EventSource('/api/analyze');
  es.onmessage = handler;
  return () => es.close(); // REQUIRED
}, []);
```

Without the return cleanup, multiple EventSource connections accumulate per browser tab session.

---

### 6. Concurrent Request Counter Race Condition

**What happens:** Chispa uses an in-memory counter to enforce max 3 concurrent analyses. The naive implementation reads the counter, checks if < 3, then increments — three steps that are NOT atomic in Node.js if the counter is managed across async boundaries (e.g., stored in a shared object modified by async handlers). Under concurrent load, two requests can both read `count = 2`, both pass the `< 3` check, and both increment to 3 — resulting in 4 simultaneous analyses briefly.

**Node.js single-threaded caveat (MEDIUM confidence):** Pure synchronous counter checks in Node.js are safe (no true thread race). The risk arises when the check and increment are separated by an `await`. Keep the check-and-increment synchronous:

```typescript
// SAFE: synchronous check+increment before any await
if (activeCount >= 3) return res.status(429).json(...);
activeCount++;
try {
  await runAnalysis();
} finally {
  activeCount--;
}
```

The `finally` block is critical — a thrown error without it permanently inflates the counter.

---

### 7. base64 URL State Exceeding Browser/Server Limits

**What happens:** Chispa encodes the full analysis result as base64 JSON in the URL for sharing. Claude's `web_search_20250305` tool can return extensive search results. A comprehensive startup analysis with citations, scores, and structured data can easily produce 10–50KB of JSON. Base64 increases size by 33%, pushing a 20KB payload to ~27KB of URL characters. Chrome enforces a 2MB internal URL limit, but servers (nginx, Express) default to 8KB–16KB header limits, and some proxy configurations enforce 2048 characters (the sitemaps/IE legacy limit).

**Practical limits:**
- Chrome address bar: ~2048 characters visible; internal limit ~2MB
- nginx default `large_client_header_buffers`: 8KB
- Express `maxHeaderSize`: 16KB default
- Safe cross-browser/server limit: ~2000 characters for URL path + query combined

**What breaks first:** The server rejects the request with HTTP 431 (Request Header Fields Too Large) before the browser URL limit is hit.

---

### 8. Not Flushing the SSE Response Buffer in Node.js

**What happens:** Node.js HTTP responses are buffered. Writing to `res` does not immediately send data to the client. Calling `res.write(data)` must be followed by `res.flush()` (if using a compression middleware) or the data sits in the Node.js write buffer. Compression middleware (like `compression` npm package) is especially problematic — it buffers SSE chunks to compress them, which eliminates the real-time benefit entirely.

**Prevention:** Either disable compression for SSE routes, or use `res.flush()` after every `res.write()`. The `compression` middleware respects `res.flush()` as a signal to emit buffered data.

---

### 9. Vite Dev Proxy Not Configured for SSE

**What happens:** Vite's built-in dev proxy does support SSE, but only when configured correctly. The default proxy config does not set `changeOrigin: true`, and more critically, does not configure the proxy to handle long-lived connections. Some Vite versions time out proxy connections shorter than the 120-second analysis window.

**Known issue:** The Vite proxy forwards the SSE connection but may close it on its own timeout before the analysis completes, causing the browser to receive a premature `close` event and trigger EventSource auto-reconnect — which starts a second analysis.

---

### 10. Unhandled Unknown SSE Event Types Crashing the Client

**What happens:** The Anthropic API versioning policy explicitly states: "new event types may be added, and your code should handle unknown event types gracefully." A switch statement or if-chain that throws on unrecognized event types will crash the analysis when Anthropic adds a new event type (e.g., new thinking delta variants, new ping formats).

**The consequence for Chispa:** The SSE consumer on the server side — the part that reads from Anthropic and re-emits to the browser — must silently skip unknown event types, not throw.

---

## Warning Signs

| Warning Sign | What It Indicates | Severity |
|---|---|---|
| `SyntaxError: Unexpected token` in tool input handler | Parsing `partial_json` before `content_block_stop` | CRITICAL |
| SSE stream completes but browser shows nothing until end | Proxy buffering (nginx, Cloudflare, etc.) | HIGH |
| React console: "state update on unmounted component" | Missing `EventSource.close()` in useEffect cleanup | HIGH |
| HTTP 431 on share URL | base64 payload exceeds server header size limit | HIGH |
| `activeCount` never returns to 0 after errors | Missing `finally { activeCount-- }` block | HIGH |
| Analysis silently hangs past 120 seconds | No read timeout on the Anthropic streaming connection | HIGH |
| Second analysis starts immediately after first (no user action) | EventSource auto-reconnect triggered by proxy timeout | MEDIUM |
| All events arrive at once after analysis completes | `res.flush()` missing or compression middleware buffering | MEDIUM |
| Overloaded error not shown to user | Not listening for `event: error` in SSE stream | MEDIUM |
| Tool parameters contain unexpected keys | `strict: true` not set; model over-generating parameters | LOW |

---

## Prevention Strategies

### Phase: Server Setup (before any Claude integration)

**P1. SSE response headers — set all four, always:**
```typescript
res.setHeader('Content-Type', 'text/event-stream');
res.setHeader('Cache-Control', 'no-cache');
res.setHeader('X-Accel-Buffering', 'no');
res.setHeader('Connection', 'keep-alive');
res.flushHeaders(); // send headers immediately
```

**P2. Disable compression middleware for SSE routes:**
```typescript
app.use('/api/analyze', (req, res, next) => {
  // Skip compression for SSE endpoint
  res.setHeader('Content-Encoding', 'identity');
  next();
});
```

**P3. Concurrent counter with atomic check-and-increment and guaranteed decrement:**
```typescript
let activeCount = 0;
const MAX_CONCURRENT = 3;

if (activeCount >= MAX_CONCURRENT) {
  return res.status(429).json({ error: 'Rate limit: max 3 concurrent analyses' });
}
activeCount++; // synchronous, before any await
try {
  await streamAnalysis(req, res);
} finally {
  activeCount--; // always runs, even on throw
}
```

**P4. Set a read timeout on the Anthropic SDK client:**
```typescript
const client = new Anthropic({
  timeout: 90_000, // 90 seconds — inside the 120s requirement
});
```

---

### Phase: Claude Streaming Integration

**P5. Accumulate tool_use input correctly — never parse partial fragments:**
```typescript
const toolInputBuffers = new Map<number, string>();

for await (const event of stream) {
  if (event.type === 'content_block_start' && event.content_block.type === 'tool_use') {
    toolInputBuffers.set(event.index, '');
  } else if (event.type === 'content_block_delta' && event.delta.type === 'input_json_delta') {
    toolInputBuffers.set(event.index, (toolInputBuffers.get(event.index) ?? '') + event.delta.partial_json);
  } else if (event.type === 'content_block_stop' && toolInputBuffers.has(event.index)) {
    try {
      const parsed = JSON.parse(toolInputBuffers.get(event.index)!);
      // use parsed
    } catch {
      // Handle incomplete JSON if stop_reason was max_tokens
    }
  }
}
```

**P6. Handle mid-stream error events and unknown event types:**
```typescript
for await (const event of stream) {
  if (event.type === 'error') {
    sendSSEToClient(res, 'error', { message: event.error.message });
    return;
  }
  if (!KNOWN_EVENT_TYPES.has(event.type)) {
    continue; // silently skip unknown types per Anthropic versioning policy
  }
  // ... handle known types
}
```

**P7. Check stop_reason before finalizing:**
```typescript
if (finalMessage.stop_reason === 'max_tokens') {
  sendSSEToClient(res, 'error', { message: 'Analysis exceeded token limit — result may be incomplete' });
}
```

---

### Phase: Frontend (React SSE Consumer)

**P8. Always close EventSource in useEffect cleanup:**
```typescript
useEffect(() => {
  const es = new EventSource('/api/analyze', { withCredentials: false });
  es.addEventListener('tool_call', handleToolCall);
  es.addEventListener('text', handleText);
  es.addEventListener('error', handleError);
  es.onerror = () => { es.close(); setError('Connection lost'); };
  return () => es.close(); // MANDATORY cleanup
}, [analysisId]);
```

**P9. Prevent EventSource auto-reconnect from triggering a new analysis:** The browser's native EventSource auto-reconnects on close. For a one-shot analysis, close the connection explicitly when `message_stop` is received, and do not open a new one:
```typescript
es.addEventListener('done', () => {
  es.close();
  setComplete(true);
});
```

---

### Phase: URL State / Sharing

**P10. Compress before base64-encoding:**
Use `lz-string` or `pako` (zlib) to compress the JSON before base64-encoding. A 20KB JSON result compresses to 2–4KB, then base64-encodes to ~3–5KB — well within all server limits.

```typescript
import LZString from 'lz-string';
const encoded = LZString.compressToEncodedURIComponent(JSON.stringify(result));
// Result: typically 80-90% smaller than raw base64
```

Use `LZString.decompressFromEncodedURIComponent` to decode. This library produces URL-safe output without `+`, `/`, or `=` characters.

**P11. Add server-side URL length guard:** Before redirecting to the share URL, check its length:
```typescript
if (shareUrl.length > 8000) {
  // Fall back to truncated result or server-side storage
  console.warn('Share URL exceeds safe length:', shareUrl.length);
}
```

---

### Phase: Development Environment

**P12. Vite proxy configuration for SSE and long-lived connections:**
```typescript
// vite.config.ts
export default {
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
        // Required for SSE: disable proxy timeout
        configure: (proxy) => {
          proxy.on('proxyReq', (proxyReq) => {
            proxyReq.setHeader('Connection', 'keep-alive');
          });
        },
      },
    },
  },
};
```

**P13. Express CORS for non-proxied environments (production):**
```typescript
app.use(cors({
  origin: process.env.ALLOWED_ORIGIN ?? 'http://localhost:5173',
  credentials: false,
}));
```

CORS is not needed in development when Vite proxy is active (same-origin from browser's perspective), but is required in any deployed environment where client and server have different origins.

---

## Which Phase Addresses Each Pitfall

| Pitfall | Phase |
|---|---|
| tool_use partial JSON parsing | Claude Streaming Integration |
| Mid-stream error events | Claude Streaming Integration |
| No read timeout on Anthropic connection | Server Setup |
| SSE proxy buffering | Server Setup + Deployment |
| React EventSource cleanup | Frontend |
| Concurrent counter race | Server Setup |
| base64 URL length | URL State / Sharing |
| res.flush() missing | Server Setup |
| Vite proxy SSE timeout | Development Environment |
| Unknown event types | Claude Streaming Integration |

---

Sources consulted:
- [Anthropic Streaming Messages Docs](https://platform.claude.com/docs/en/build-with-claude/streaming)
- [Anthropic Fine-Grained Tool Streaming Docs](https://platform.claude.com/docs/en/agents-and-tools/tool-use/fine-grained-tool-streaming)
- [Anthropic Tool Use Troubleshooting](https://platform.claude.com/docs/en/agents-and-tools/tool-use/troubleshooting-tool-use)
- [Node.js SSE Production Guide - HireNodeJS](https://www.hirenodejs.com/blog/nodejs-server-sent-events-sse-2026)
- [SSE Not Production Ready - DEV Community](https://dev.to/miketalbot/server-sent-events-are-still-not-production-ready-after-a-decade-a-lesson-for-me-a-warning-for-you-2gie)
- [Claude Code SSE Hang Bug #25979](https://github.com/anthropics/claude-code/issues/25979)
- [Express Rate Limiting - BetterStack](https://betterstack.com/community/guides/scaling-nodejs/rate-limiting-express/)
- [Vite CORS Setup - Medium](https://medium.com/@aparna1002v/setup-proxy-in-react-vite-for-cors-issues-167c6a1eb569)
- [URL Length Limits - Baeldung](https://www.baeldung.com/cs/max-url-length)
- [React SSE Implementation - Medium](https://medium.com/@dlrnjstjs/implementing-react-sse-server-sent-events-real-time-notification-system-a999bb983d1b)
- [Anthropic SDK TypeScript Streaming Examples - DeepWiki](https://deepwiki.com/anthropics/anthropic-sdk-typescript/7.1-streaming-examples)
