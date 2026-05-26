# Research Summary — Chispa

Synthesized: 2026-05-26. Source files: STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md.

---

## Executive Summary

Chispa is a well-scoped demo product with a clearly defensible niche: the only LatAm-specific, Spanish-first AI startup validator in a market of English-centric competitors. The technical approach — stateless Express + React + SSE + Claude with web_search — is architecturally sound and correctly matched to the 90-second demo constraint. No database, no auth, and no multi-turn conversation state means the core engineering problem is precisely one thing: getting Claude's streaming events reliably from the Anthropic API through Express to the browser as a live activity feed, then serializing the result into a shareable URL.

The market is crowded with global competitors (IdeaProof, ValidatorAI, Preuve AI, WorthBuild), but none targets LatAm. The table stakes are well-established: verdict label, named competitors, TAM estimate, risk factors, actionable next steps, and sub-120-second speed. Chispa can clear all table stakes within the 4-phase plan. The LatAm differentiation (Spanish-first UI, LatAm competitor search layer, explicit statelessness as a trust signal) is real and achievable without extending scope.

The primary risks are not product risks but implementation risks: SSE streaming is fragile at every layer (Vite proxy, Express buffer, EventSource lifecycle, Anthropic mid-stream errors), and three specific dependency upgrades are mandatory before Phase 2 begins. If the streaming pipeline is built correctly in Phase 2, Phases 3 and 4 are straightforward UI work. The demo timeline is achievable if Phase 2 is not underestimated.

---

## Recommended Stack

All packages below are pinned to researched versions (2026-05-26). Caret ranges allow minor/patch upgrades.

| Layer | Technology | Version | Rationale |
|---|---|---|---|
| Runtime | Node.js | 20 LTS | ESM support required; tsx hot reload |
| Server framework | Express | ^4.19.2 | Express 5 ecosystem not mature; 4.x is stable |
| AI SDK | @anthropic-ai/sdk | ^0.98.0 | Must upgrade from ^0.30.0; stream() API required |
| AI model | claude-sonnet-4-6 | (model ID) | Current production Sonnet; Opus is unnecessary cost |
| Search tool | web_search_20250305 | (built-in) | Pass in tools[]; Claude calls autonomously |
| TypeScript | typescript | ^5.5.3 | Both client and server; do not upgrade mid-project |
| Dev runtime | tsx | ^4.16.2 | Replaces ts-node; ESM-safe; works with nodemon |
| Real-time | SSE via fetch+ReadableStream | (native) | EventSource does not support POST; fetch does |
| UI framework | React | ^18.3.1 | Stay at 18.x; React 19 breaks framer-motion/recharts |
| Build tool | Vite | ^5.3.2 | Already configured with /api proxy to Express |
| Styling | Tailwind CSS | ^3.4.4 | Do not upgrade to v4; breaking config changes |
| Animation | framer-motion | ^12.40.0 | Upgrade from ^11.3.0; API identical, v12 is stable |
| Charts | recharts | ^3.8.1 | Upgrade from ^2.12.7; v3 required for clean RadarChart |
| Icons | lucide-react | ^0.400.0 | No change needed |
| Monorepo | npm workspaces + concurrently | ^9.2.1 | No Turborepo; overkill for 2-package repo |

Three upgrades are mandatory before starting Phase 2: @anthropic-ai/sdk (0.30 to 0.98), framer-motion (11 to 12), and recharts (2 to 3). All others are keep-as-is.

---

## Table Stakes Features

These must be present in v1 for Chispa to be taken seriously at the demo. Every major competitor delivers all of these.

1. Verdict label — LAUNCH / VALIDATE / PIVOT / AVOID. The primary output users seek. Non-negotiable.
2. Verdict reason in plain language — 2-4 sentences written for a first-time founder, not an MBA. No jargon.
3. Named competitors — minimum 3 real companies with brief positioning. Generic placeholders cause abandonment.
4. TAM estimate — a dollar figure, not a vague description. With basis (e.g., "Statista, $4.2B by 2028").
5. Market growth signal — Growing / Flat / Shrinking directional indicator.
6. Risk factors — minimum 3 specific, idea-level risks (not generic "market risk" boilerplate).
7. Actionable first steps — minimum 3 concrete actions, not "do market research."
8. Sub-120-second total response time — non-negotiable; users conditioned by competitors marketing 60-120s.
9. No login required — stateless by design; no registration friction.

For LatAm differentiation (v1, not deferred):
- Spanish-first UI — default language Spanish, Latin American register
- LatAm competitor search layer — prompt explicitly instructs Claude to surface LatAm-region players
- Visible statelessness — "Your idea is not stored" as a UI element, not a footnote

Deferred to v2: PDF export, Portuguese toggle, source citations (add latency), multi-idea comparison.

---

## Key Architecture Decisions

### 1. Single POST endpoint doubles as SSE stream

POST /api/analyze sets SSE headers immediately and streams events back on the same connection. The client uses fetch() + ReadableStream (not the native EventSource API, which only supports GET). This is the only correct pattern for POST-body + streaming response.

### 2. Three-tier event translation layer

Claude SDK events are translated to three client-visible SSE event types: step (emitted on each content_block_start with tool_use type — gives the activity feed its live updates), result (emitted on message_stop with the full AnalysisResult JSON), and error (emitted on mid-stream errors or Anthropic overloaded_error events). The client only needs to handle these three shapes.

### 3. URL as the only persistence layer

On result event, the client runs btoa(JSON.stringify(result)) + encodeURIComponent() and pushes to the ?r= query param. On mount, if ?r= is present, it decodes directly to Dashboard with zero network calls — fully offline-capable for shared links. Raw base64 of large JSON can exceed server header limits; use lz-string compression before encoding to stay under 8KB safely.

### 4. In-memory concurrency limiter

A module-level integer counter enforces a max of 3 concurrent analyses. The check-and-increment must be synchronous (before any await) to avoid the TOCTOU race condition. A try/finally block guarantees decrement even on Anthropic errors.

### 5. Vite proxy for dev; Express static serve for prod

In development, Vite forwards /api requests to Express on port 3001. In production, Express serves client/dist directly, with API routes registered before the static catch-all. The X-Accel-Buffering: no header must be set on SSE responses to prevent nginx/proxy buffering in both environments.

### 6. Shared TypeScript types (client and server)

AnalysisResult and SSEMessage types must be defined once. The architecture research leaves the shared location implicit — this is a structural decision needed before Phase 2 begins.

---

## Top Pitfalls

These are the highest-probability failure modes during implementation. Each one has caused real production bugs in similar systems.

### Pitfall 1: Parsing tool_use JSON before content_block_stop (CRITICAL)

Claude streams tool input as partial JSON string fragments. JSON.parse() on any individual input_json_delta event will crash. The correct pattern: accumulate all partial_json fragments into a string buffer keyed by block index, only call JSON.parse() on content_block_stop. Also check stop_reason !== 'max_tokens' before finalizing — a truncated stream leaves the buffer permanently incomplete.

Prevention: Use a Map<index, string> accumulator. Parse only on content_block_stop. See PITFALLS.md P5 for exact code.

### Pitfall 2: SSE proxy buffering silently breaks the live feed (HIGH)

Intermediate proxies (Vite dev proxy, nginx, ALB) buffer streaming responses by default. From the browser, nothing arrives until analysis completes — the live activity feed appears dead. The fix requires four headers on every SSE response: Content-Type: text/event-stream, Cache-Control: no-cache, X-Accel-Buffering: no, Connection: keep-alive, plus res.flushHeaders() immediately. Also: do not use compression middleware on the SSE endpoint.

Prevention: Set all four headers at the top of the route handler, before any async call. Call res.flushHeaders() before awaiting Claude.

### Pitfall 3: No read timeout on the Anthropic connection (HIGH)

If Anthropic stalls mid-stream, the Express connection stays open indefinitely. With a max-3 concurrency limit, three simultaneous stalls produce a full deadlock — no new analyses can start. This is a documented production bug in the Claude Code codebase.

Prevention: Pass timeout: 90_000 (90 seconds) when constructing the Anthropic SDK client. Inside the 120-second UX requirement.

### Pitfall 4: React connection leaks from missing cleanup (HIGH)

A ReadableStream reader (or EventSource) opened in useEffect without a cleanup return function stays open after component unmount. Multiple connections accumulate per browser session; state updates fire on unmounted components.

Prevention: Return an AbortController abort call from useEffect. For EventSource, return () => es.close().

### Pitfall 5: Base64 URL length exceeding server limits (HIGH)

Claude's web search can return extensive data. A comprehensive analysis result (10-50KB JSON) base64-encoded can exceed nginx's default 8KB header buffer, producing HTTP 431 errors. The Chrome address bar limit is irrelevant — the server rejects the request first.

Prevention: Compress with lz-string before encoding. A 20KB JSON result compresses to 2-4KB, then base64-encodes to 3-5KB — well within all server limits. Add lz-string as a client dependency in Phase 4.

---

## Implications for Roadmap

The 4-phase structure in the project brief is well-aligned with the research findings. The key implication is that Phase 2 is the critical path and the highest-risk phase — everything else depends on it working correctly.

**Phase 1 (Foundation) additions:**
- Upgrade @anthropic-ai/sdk to ^0.98.0 as the first task (scaffold has ^0.30.0, which predates the stream() API shape needed for Phase 2)
- Upgrade framer-motion to ^12 and recharts to ^3 now, not in Phase 3, to avoid mid-project breaking changes
- Define AnalysisResult and SSEMessage TypeScript types in a shared location before writing any route or component code — these types are the contract between Phase 2 and Phase 3
- Configure Vite proxy for SSE correctly from the start (default proxy config is not SSE-safe)

**Phase 2 (Analysis Engine) must-have gates:**
- SSE headers must include all four required fields including X-Accel-Buffering: no before any proxy testing
- The tool_use JSON accumulator pattern must be in place before any prompt testing (partial JSON parsing crashes are immediate and confusing)
- The 90-second Anthropic SDK timeout must be set before the concurrent limiter is tested
- Prompt engineering must explicitly request JSON output matching AnalysisResult and include the LatAm competitor search instruction — these are not Phase 3 concerns

**Phase 3 (Web Frontend) sequencing:**
- Build the fetch + ReadableStream SSE consumer before building any UI components — this is the hardest frontend piece and blocks the activity feed
- State machine (idle to loading to done / error) should be built before individual components
- The RadarChart should be built with mock data first, then wired to live AnalysisResult — isolates chart bugs from streaming bugs

**Phase 4 (Polish) additions:**
- Add lz-string for URL compression (without it, large results produce HTTP 431 in production)
- Test shareable URL load path with both valid and malformed base64 (the try/catch around atob() is mandatory)
- Verify res.flushHeaders() works behind any production proxy before demo day

**Demo preparation:**
- The demo target (AI Week Summit Guatemala 2026) is a Spanish-speaking audience. Spanish-first UI is not cosmetic — it is the core differentiation at this venue. Prioritize Spanish copy over English polish.
- Plan for the "busy server" case: if 3+ attendees submit simultaneously, the rate limit fires. The error message must be graceful and in Spanish.
- Decide on deployment target before Phase 4 begins (localhost means shareable URLs don't work across devices at the demo).

---

## Confidence Assessment

| Area | Confidence | Notes |
|---|---|---|
| Stack — core dependencies | HIGH | Codebase scanned; npm registry verified as of 2026-05-26 |
| Stack — framer-motion v12 API | MEDIUM | npm + motion.dev upgrade guide; no hands-on v12 migration tested |
| Stack — recharts v3 RadarChart | MEDIUM | GitHub wiki + npm; RadarChart-specific breaking changes not fully confirmed |
| Features — table stakes | HIGH | Verified across 5+ competitor products; consistent signal |
| Features — LatAm market gap | MEDIUM | No direct competitor found; absence-of-evidence, not evidence-of-absence |
| Features — Spanish-first impact on LatAm users | MEDIUM | Language gap confirmed; user impact inferred, not interview-validated |
| Architecture — SSE + fetch pattern | HIGH | MDN spec + Anthropic docs; POST+SSE pattern widely used in practice |
| Architecture — base64 URL size | MEDIUM | Limits documented; actual Claude output size under web_search not measured |
| Pitfalls — tool_use JSON parsing | HIGH | Official Anthropic docs explicitly warn about this |
| Pitfalls — proxy buffering | HIGH | Documented production issue; multiple independent sources |
| Pitfalls — Vite proxy timeout | MEDIUM | Community-verified; no official Vite docs entry for this specific issue |

---

## Gaps

The following questions were not resolved by the research and should be addressed during planning or early implementation:

1. **Actual Claude output size under web_search:** The base64 URL concern depends on how large Claude's AnalysisResult JSON gets in practice. A test run with web_search_20250305 active should be done in Phase 2 to measure real output size before Phase 4 URL encoding is designed.

2. **Shared TypeScript types location:** The research assumes AnalysisResult and SSEMessage types are shared between client and server but does not specify where in the monorepo they live. A shared/ package or a copy-to-both approach needs a decision before Phase 2 begins.

3. **Spanish copy ownership:** The research confirms Spanish-first is a differentiator but produces no copy. All UI strings, verdict explanations, error messages, and first-step templates need to be written in Latin American Spanish. This is a content task that should be scoped into Phase 3.

4. **LatAm competitor search prompt template:** The architecture research does not include the actual prompt that instructs Claude to search for LatAm-specific competitors. This is a prompt engineering task belonging in Phase 2 with significant impact on output quality. It needs to be drafted and tested, not left as a TODO.

5. **Deployment target:** The research does not address where Chispa runs on demo day. If it runs on localhost, shareable URLs do not work across devices. If deployed (Railway, Fly.io, Render), nginx buffering and CORS configuration become live concerns. Deployment target should be decided before Phase 4 begins.

6. **Market timing assessment feature:** FEATURES research flags this as LOW confidence — it is a potential differentiator but needs user validation that founders find it distinct from the market growth signal. It is currently in the v1 feature list; should be downgraded to v2 if the prompt makes it difficult to produce reliably.
