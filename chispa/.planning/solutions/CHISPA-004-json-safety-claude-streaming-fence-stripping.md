---
id: CHISPA-004
title: "JSON safety with Claude streaming — markdown fence stripping and max_tokens guard"
tags: [claude, json, streaming, markdown, typescript, robustness]
problem_domain: "LLM output parsing / defensive coding"
severity_when_wrong: high
discovery_date: 2026-05-26
project: chispa
---

## Problem

After collecting the final text from a Claude stream, `JSON.parse()` throws `SyntaxError` in production even though the prompt explicitly instructs Claude to return raw JSON. Claude occasionally wraps its JSON output in markdown code fences (` ```json ... ``` `) despite the instruction, and may also truncate the JSON if the response hits `max_tokens`.

## Root Cause

Claude's instruction-following for output format is probabilistic. Under certain conditions (long system prompts, model temperature, tool-use context) it reverts to its training default of wrapping code in markdown fences. Additionally, when `stop_reason === 'max_tokens'`, the JSON object is truncated mid-structure and will always fail parsing — attempting to parse it wastes time and produces a confusing error.

## Solution

After extracting the raw text from the final message:
1. Check `finalMessage.stop_reason` — if it is `'max_tokens'`, raise a descriptive error before attempting to parse.
2. Strip leading and trailing markdown code fences with two targeted regex replacements before calling `JSON.parse()`.

## Code Example

```typescript
// server/src/agent/analyzer.ts

const finalMessage = await stream.finalMessage();

// Guard: truncated response cannot be valid JSON
if (finalMessage.stop_reason === 'max_tokens') {
  throw new Error(
    'Claude response was truncated (max_tokens reached). Increase max_tokens or shorten the prompt.'
  );
}

const textBlock = finalMessage.content.find((b) => b.type === 'text');
const rawText = textBlock?.text ?? '';

// Strip markdown fences Claude sometimes adds despite instructions
const cleaned = rawText
  .replace(/^```(?:json)?\s*/m, '')  // leading ```json or ```
  .replace(/\s*```\s*$/m, '')         // trailing ```
  .trim();

let result: AnalysisResult;
try {
  result = JSON.parse(cleaned);
} catch (err) {
  throw new Error(`Failed to parse Claude output as JSON: ${(err as Error).message}\n\nRaw output:\n${cleaned}`);
}
```

## When to Use

- Any endpoint where Claude is instructed to return structured JSON
- Streaming pipelines where the final message text is parsed programmatically
- Situations where Claude is given tools (tool use can affect formatting behaviour)

## Pitfalls

- **Always check `stop_reason` before parsing.** A truncated JSON object will never parse successfully, and the error message from `JSON.parse()` ("Unexpected end of JSON input") is unhelpful without context.
- **The regex uses the `m` (multiline) flag.** Without it, `^` and `$` match the start/end of the entire string, not each line, and the fence won't be stripped if there is whitespace before it.
- **Strip fences even when the prompt says "return raw JSON".** Claude's instruction adherence is not 100% reliable across model versions.
- Do not use a single regex to strip both the opening and closing fence — it is easier to reason about and debug two separate replacements.
- Log or return the raw uncleaned text in error messages so you can inspect what Claude actually returned when parsing fails.
- Consider using `JSON5.parse()` or `jsonrepair` as a fallback for minor JSON formatting issues (trailing commas, unquoted keys) if strict compliance is not required.
