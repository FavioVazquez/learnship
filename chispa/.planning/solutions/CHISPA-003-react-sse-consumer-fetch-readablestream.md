---
id: CHISPA-003
title: "React SSE consumer using fetch + ReadableStream (POST endpoint)"
tags: [react, sse, fetch, readablestream, typescript, hooks]
problem_domain: "Browser streaming / React data fetching"
severity_when_wrong: high
discovery_date: 2026-05-26
project: chispa
---

## Problem

Consuming a Server-Sent Events stream from a React component when the SSE endpoint requires a POST request (to send a JSON body). The native `EventSource` API only supports GET requests with no body — it cannot send a JSON payload to start the stream.

## Root Cause

The `EventSource` Web API was designed for simple push notifications and intentionally does not support HTTP methods other than GET or custom request bodies. When the server needs input (e.g. the idea text to analyze), the connection must be initiated as a POST, which `EventSource` cannot do.

## Solution

Use `fetch()` with `method: 'POST'` and a JSON body, then access `response.body` as a `ReadableStream`. Pump the stream with a `reader.read()` loop, accumulate chunks into a buffer, split on `\n\n` (the SSE message delimiter), and parse the `data: {...}` prefix from each complete message.

## Code Example

```typescript
// client/src/hooks/useAnalysis.ts

export function useAnalysis() {
  const [status, setStatus] = useState<AnalysisStatus>('idle');
  const [events, setEvents] = useState<AnalysisEvent[]>([]);
  const controllerRef = useRef<AbortController | null>(null);

  const start = useCallback(async (idea: string) => {
    controllerRef.current = new AbortController();
    setStatus('running');
    setEvents([]);

    const response = await fetch('/api/analyze', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ idea }),
      signal: controllerRef.current.signal,
    });

    if (!response.ok || !response.body) {
      setStatus('error');
      return;
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });

      // SSE messages are separated by double newlines
      const parts = buffer.split('\n\n');
      buffer = parts.pop() ?? ''; // keep incomplete last chunk

      for (const part of parts) {
        const line = part.trim();
        if (!line.startsWith('data: ')) continue;
        try {
          const payload = JSON.parse(line.slice('data: '.length));
          setEvents((prev) => [...prev, payload]);
          if (payload.type === 'done') setStatus('complete');
          if (payload.type === 'error') setStatus('error');
        } catch {
          // malformed JSON — skip
        }
      }
    }
  }, []);

  const cancel = useCallback(() => {
    controllerRef.current?.abort();
    setStatus('idle');
  }, []);

  return { status, events, start, cancel };
}
```

## When to Use

- Any React app that needs to consume SSE from a POST endpoint
- Streaming AI responses where the request body contains user input
- Progressive UI updates while a long-running server operation is in flight

## Pitfalls

- **Never use `EventSource` for POST endpoints.** It silently opens a GET request and ignores any body you pass.
- **Always store the `AbortController` in a ref, not state.** Storing it in state causes re-renders that can create a new controller before the old stream is aborted.
- **Buffer splitting must use `\n\n`**, not `\n`. A single `\n` separates fields within one SSE message; `\n\n` separates messages.
- **Keep the trailing incomplete chunk** (`parts.pop()`). Chunks from `reader.read()` do not align with SSE message boundaries — a message may be split across two reads.
- Pass `{ stream: true }` to `TextDecoder.decode()` to correctly handle multi-byte UTF-8 characters split across chunk boundaries.
- Clean up by aborting the controller in a `useEffect` cleanup function if the component unmounts mid-stream.
