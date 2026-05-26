---
id: CHISPA-001
title: "Claude SDK streaming with web_search tool and live tool_use events"
tags: [claude, streaming, tool-use, typescript, anthropic-sdk]
problem_domain: "AI streaming / tool call progress feedback"
severity_when_wrong: high
discovery_date: 2026-05-26
project: chispa
---

## Problem

When using the Anthropic SDK to stream Claude responses that include tool calls (e.g. `web_search`), you need to:
1. Emit progress events to the client as tools are invoked (before the final text arrives)
2. Collect the complete final message including all tool results

Using `messages.create()` with `stream: true` makes it hard to intercept mid-stream tool_use events. Calling `finalMessage()` at the wrong point returns an incomplete or empty message.

## Root Cause

`messages.create()` returns a raw stream object that requires manual event parsing and does not expose a convenient `finalMessage()` helper. The `client.messages.stream()` method wraps the stream with typed helpers — but `finalMessage()` only resolves after the async iterator has been fully consumed. Calling it before the loop completes causes it to race against an incomplete stream.

## Solution

Use `client.messages.stream()` (not `messages.create()`), drive it with a `for await` loop, inspect `event.type` inside the loop to emit progress events, and call `stream.finalMessage()` only after the loop exits.

## Code Example

```typescript
// server/src/agent/analyzer.ts

const stream = client.messages.stream({
  model: 'claude-opus-4-5',
  max_tokens: 8192,
  tools: [{ type: 'web_search_20250305', name: 'web_search' }],
  messages: [{ role: 'user', content: prompt }],
});

for await (const event of stream) {
  if (
    event.type === 'content_block_start' &&
    event.content_block.type === 'tool_use'
  ) {
    // Emit progress to SSE client while Claude is searching
    onProgress?.({ type: 'tool_use', name: event.content_block.name });
  }
}

// MUST come after the for-await loop
const finalMessage = await stream.finalMessage();
const textBlock = finalMessage.content.find((b) => b.type === 'text');
const rawText = textBlock?.text ?? '';
```

## When to Use

- Any Claude feature that uses tool calls and needs real-time progress feedback
- Streaming pipelines where you need both incremental events AND the fully-assembled final message
- Server-Sent Events backends that forward Claude progress to a browser client

## Pitfalls

- **Do not call `stream.finalMessage()` inside or before the `for await` loop.** It will resolve with an incomplete message or hang.
- **Do not use `messages.create()` with `stream: true`** if you also need typed event helpers like `finalMessage()` — use `messages.stream()` instead.
- `event.content_block.type === 'tool_use'` only fires on `content_block_start`, not `content_block_delta`. Filter on the correct event type.
- If you need the tool input arguments (e.g. the search query), you must accumulate `content_block_delta` events with `type === 'input_json_delta'` — the full input is not available at `content_block_start`.
