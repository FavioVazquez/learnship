---
id: CHISPA-002
title: "Express SSE with proper headers and in-memory rate limiting"
tags: [express, sse, server-sent-events, rate-limiting, typescript]
problem_domain: "HTTP streaming / API protection"
severity_when_wrong: high
discovery_date: 2026-05-26
project: chispa
---

## Problem

Setting up a Server-Sent Events (SSE) endpoint in Express that:
1. Reliably delivers events to the browser without buffering by proxies or Express itself
2. Limits concurrent or per-minute requests to protect an expensive downstream API (Claude)
3. Always releases the concurrency slot even when the client disconnects mid-stream or an error is thrown

## Root Cause

Express (and nginx) buffer responses by default. If `res.flushHeaders()` is not called before the first `await`, the browser receives nothing until the entire response is buffered and sent at once — defeating the purpose of SSE.

Rate limiting middleware (e.g. `express-rate-limit`) operates per-request and cannot easily enforce a concurrency cap. An in-memory counter with synchronous check-and-increment is simpler and sufficient for single-process deployments.

## Solution

Set the three required SSE headers and call `res.flushHeaders()` synchronously before any `await`. Implement the concurrency limit as a synchronous check-and-increment of a module-level counter, and wrap the entire handler body in `try/finally` to guarantee decrement.

## Code Example

```typescript
// server/src/routes/analyze.ts

let activeRequests = 0;
const MAX_CONCURRENT = 3;

router.post('/analyze', async (req, res) => {
  // 1. Set SSE headers first — before any await
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('X-Accel-Buffering', 'no'); // tells nginx not to buffer
  res.flushHeaders(); // <-- MUST fire before first await

  // 2. Synchronous rate-limit check
  if (activeRequests >= MAX_CONCURRENT) {
    res.write(`data: ${JSON.stringify({ type: 'error', message: 'Too many concurrent analyses' })}\n\n`);
    res.end();
    return;
  }
  activeRequests++;

  // 3. try/finally guarantees the slot is released
  try {
    await runAnalysis(req.body, (event) => {
      res.write(`data: ${JSON.stringify(event)}\n\n`);
    });
    res.write(`data: ${JSON.stringify({ type: 'done' })}\n\n`);
  } finally {
    activeRequests--;
    res.end();
  }
});
```

## When to Use

- Any Express endpoint that streams SSE to a browser
- Endpoints backed by expensive or rate-limited APIs where you need concurrency control
- Situations where nginx or another reverse proxy sits in front of Express

## Pitfalls

- **`flushHeaders()` before the first `await` is mandatory.** Moving it even one line later (after a DB lookup, for example) can silently break SSE delivery in some environments.
- **`X-Accel-Buffering: no` is nginx-specific.** For Apache or Caddy, check their equivalent unbuffering directives.
- The in-memory counter resets on process restart and does not work across multiple Node processes. Use Redis or a proper rate-limit store for multi-instance deployments.
- Always call `res.end()` in the `finally` block — if you throw before `res.end()`, the client connection hangs open until timeout.
- `express-rate-limit` by default counts requests, not concurrent connections. Use it for per-minute caps; use the counter pattern for concurrency caps.
