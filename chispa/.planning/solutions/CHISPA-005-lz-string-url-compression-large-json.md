---
id: CHISPA-005
title: "lz-string URL compression for large JSON state (bypassing 8KB header limit)"
tags: [lz-string, url, compression, react, typescript, state-management]
problem_domain: "URL state / shareable links"
severity_when_wrong: medium
discovery_date: 2026-05-26
project: chispa
---

## Problem

Encoding large JSON objects (e.g. a full Claude analysis result with competitors, risks, and recommendations) into a URL query parameter for shareable links. Plain base64 encoding of a typical Claude analysis response produces strings exceeding 8 KB, which nginx rejects with `400 Request Header Or Cookie Too Large` — and some browsers silently truncate URLs beyond ~2000 characters.

## Root Cause

A Claude analysis result containing multiple sections (market size, competitors, risks, recommendations) serialises to 3–6 KB of JSON. Base64 encoding expands the payload by ~33%, pushing it to 4–8 KB. nginx's default `large_client_header_buffers` limit is 8 KB per header line, which includes the URL in the `GET` request line. lz-string's LZ77-based compression reduces English-language JSON by ~60%, keeping the encoded value well under the limit.

## Solution

Compress the JSON string with `lzstring.compressToEncodedURIComponent()` before placing it in the URL, and decompress with `lzstring.decompressFromEncodedURIComponent()` when reading it back. Wrap the decode path in `try/catch` to handle corrupt or expired share links gracefully.

## Code Example

```typescript
// client/src/components/ShareButton.tsx — encoding

import lzstring from 'lz-string';

function buildShareUrl(result: AnalysisResult): string {
  const json = JSON.stringify(result);
  const compressed = lzstring.compressToEncodedURIComponent(json);
  const url = new URL(window.location.href);
  url.searchParams.set('r', compressed);
  return url.toString();
}
```

```typescript
// client/src/App.tsx — decoding on load

import lzstring from 'lz-string';

function loadResultFromUrl(): AnalysisResult | null {
  const params = new URLSearchParams(window.location.search);
  const compressed = params.get('r');
  if (!compressed) return null;

  try {
    const json = lzstring.decompressFromEncodedURIComponent(compressed);
    if (!json) return null; // decompressFromEncodedURIComponent returns null on failure
    return JSON.parse(json) as AnalysisResult;
  } catch {
    console.warn('Could not parse shared result from URL — ignoring.');
    return null;
  }
}
```

## When to Use

- Shareable links where the full application state lives in the URL (no backend persistence)
- Any URL parameter that will hold more than ~1 KB of JSON
- React SPAs that need deep-link support without a database

## Pitfalls

- **`compressToEncodedURIComponent` is not the same as `compressToBase64`.** Only the `EncodedURIComponent` variant produces URL-safe output. Using the wrong variant causes `%` characters to corrupt the URL.
- **`decompressFromEncodedURIComponent` returns `null` (not `undefined` or an exception) on failure.** Always check for `null` before calling `JSON.parse()`.
- lz-string is designed for in-browser use. The compressed output is not compatible with standard zlib/gzip tools — do not try to decompress it server-side with Node's `zlib`.
- Compressed URLs are still long (~1–2 KB). They will break SMS and some email clients. Add a "Copy link" button with a fallback message rather than auto-navigating.
- If the JSON schema changes between app versions, old share URLs will decompress successfully but `JSON.parse()` will yield an object that no longer matches the current type. Add a schema version field and validate it after parsing.
- The `lz-string` npm package is ESM/CJS compatible and has no runtime dependencies — it is safe to import in both the browser bundle and Node.js.
