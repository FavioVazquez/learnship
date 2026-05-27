---
id: CHISPA-004
title: "JSON safety with Claude streaming — brace extraction and max_tokens guard"
tags: [claude, json, streaming, markdown, typescript, robustness]
problem_domain: "LLM output parsing / defensive coding"
severity_when_wrong: high
discovery_date: 2026-05-26
updated: 2026-05-27
project: chispa
---

## Problem

After collecting the final text from a Claude stream, `JSON.parse()` throws `SyntaxError` in production even though the prompt explicitly instructs Claude to return raw JSON. Claude occasionally wraps its JSON output in markdown code fences (` ```json ... ``` `) or adds preamble text, and may also truncate the JSON if the response hits `max_tokens`.

## Root Cause

Claude's instruction-following for output format is probabilistic. Under certain conditions (long system prompts, model temperature, tool-use context) it reverts to its training default of wrapping code in markdown fences or adding explanation before the JSON. Additionally, when `stop_reason === 'max_tokens'`, the JSON object is truncated mid-structure and will always fail parsing.

**Subtle regex bug:** The original fix used `.replace(/^```(?:json)?\s*/m, '')` with the `m` multiline flag. With `m`, `^` matches the start of *any line*, not the start of the string — so preamble text before the fence was not stripped. This caused silent parse failures when Claude emitted a sentence before the code block.

## Solution

After extracting the raw text from the final message:
1. Check `finalMessage.stop_reason` — if it is `'max_tokens'`, yield a user-facing error SSE before attempting to parse.
2. Extract the JSON object by finding the outermost `{` and `}` positions — this is immune to preamble text, trailing commentary, and any fence variation.
3. Validate the parsed result shape at runtime before accepting it (TypeScript casts don't validate at runtime).

## Code Example

```typescript
// server/src/agent/analyzer.ts

if (finalMsg.stop_reason === 'max_tokens') {
  yield { type: 'error', message: 'El análisis fue demasiado largo. Intenta con una idea más concisa.' }
  return
}

const textBlocks = finalMsg.content.filter((b) => b.type === 'text')
const rawText = textBlocks.at(-1)?.text ?? ''

// Extract the JSON object by finding the outermost braces — more reliable than
// stripping markdown fences with regexes, which break when Claude adds preamble.
const start = rawText.indexOf('{')
const end = rawText.lastIndexOf('}')
if (start === -1 || end === -1 || end < start) {
  throw new Error('No JSON object found in model response')
}
const cleaned = rawText.slice(start, end + 1)

const result = JSON.parse(cleaned) as AnalysisResult

// Runtime shape guard — TypeScript casts don't validate at runtime
if (
  !['LAUNCH', 'VALIDATE', 'PIVOT', 'AVOID'].includes(result.verdict) ||
  !Array.isArray(result.competitors) ||
  !Array.isArray(result.risks) ||
  !Array.isArray(result.firstSteps) ||
  !result.marketTiming ||
  !result.marketSize
) {
  yield { type: 'error', message: 'Respuesta incompleta del modelo. Intenta de nuevo.' }
  return
}
```

## When to Use

- Any endpoint where Claude is instructed to return structured JSON
- Streaming pipelines where the final message text is parsed programmatically
- Situations where Claude is given tools (tool use can affect formatting behaviour)

## Pitfalls

- **Regex with `m` flag and `^` is dangerous for fence stripping.** With `m`, `^` matches any line start — preamble before the fence is NOT stripped. Use `indexOf('{')` / `lastIndexOf('}')` instead; it handles any wrapping format.
- **Always check `stop_reason` before parsing.** A truncated JSON object will never parse successfully.
- **Always validate shape after `JSON.parse`.** TypeScript `as SomeType` is a cast, not a runtime check. An invalid verdict string will crash downstream components that index into config maps.
- **Strip fences even when the prompt says "return raw JSON".** Claude's instruction adherence is not 100% reliable across model versions.
- Consider using `JSON5.parse()` or `jsonrepair` as a fallback for minor JSON formatting issues (trailing commas, unquoted keys) if strict compliance is not required.
