---
project: chispa
milestone: v1.0
scope: all-phases
threats_found: 12
threats_closed: 9
threats_accepted: 3
threats_open: 0
status: verified
audited: 2026-05-26
---

# Chispa — STRIDE Threat Register

Security verification for milestone v1.0 (all phases). Covers the full stack:
server (Express + Anthropic SDK), client (React + SSE consumer), and the
lz-string shareable URL mechanism.

---

## Trust Boundaries

| Boundary | From | To | Data |
|----------|------|----|------|
| TB-1 | Browser | Server `/api/analyze` | User idea (string), optional country (string) |
| TB-2 | Browser | Server `/api/health` | None |
| TB-3 | Server | Anthropic API | Constructed prompt with user idea |
| TB-4 | Anthropic API | Server | Streamed SSE events → JSON result |
| TB-5 | URL `?r=` param | Browser state | lz-string compressed AnalysisResult |
| TB-6 | Filesystem | Server | Static assets from `client/dist/` |

---

## Threat Register

### Spoofing

| ID | Component | Description | Status | Evidence |
|----|-----------|-------------|--------|---------|
| T-01 | `server/src/index.ts:14` | **CORS wildcard** — `app.use(cors())` with no origin restriction allows any website to POST to `/api/analyze`. No session credentials are at risk since the app uses no cookies or auth headers. CORS restriction would not prevent direct (non-browser) API abuse. | ACCEPTED | See Accepted Risks Log |

### Tampering

| ID | Component | Description | Status | Evidence |
|----|-----------|-------------|--------|---------|
| T-02 | `server/src/routes/analyze.ts:17` | **Idea length validation** — idea must be 20–500 characters; validated server-side before any API call. | CLOSED | `if (typeof idea !== 'string' \|\| idea.length < 20 \|\| idea.length > 500)` |
| T-03 | `server/src/routes/analyze.ts:21` | **Country field length** — country injected into Claude prompt. Previously unbounded; now capped at 100 characters to limit prompt-injection surface. | CLOSED | `body.country.length <= 100` (fixed 2026-05-26) |
| T-04 | `server/src/agent/analyzer.ts:51-53` | **Prompt injection via user idea** — idea is interpolated directly into the Claude user message. No technical barrier prevents adversarial payloads. Mitigations in place: (1) SYSTEM_PROMPT grounds the model with strict instructions; (2) output is JSON-parsed against a known schema (`AnalysisResult`); (3) client validates shape before render (`verdict`, `competitors`, `risks` required); (4) input is length-bounded to 500 chars. Blast radius is limited to influencing web search queries — no server data exfiltration path exists. | CLOSED | System prompt + `JSON.parse` + shape validation in `useAnalysis.ts:103-108` |
| T-05 | `client/src/App.tsx:23-38` | **lz-string URL decode tampering** — `?r=` param is decoded and JSON-parsed. Validated for minimal shape before use. React JSX renders all data through the DOM API (not innerHTML), preventing HTML injection. | CLOSED | Shape check: `!parsed.verdict \|\| !parsed.competitors \|\| !parsed.risks`; React escapes text interpolations |
| T-06 | `client/src/components/CompetitorCard.tsx:16` | **Competitor website in img src** — `website` from Claude used inside a Google favicon proxy URL. React sets the DOM property directly (no HTML string construction); `javascript:` in an `img src` does not execute. | CLOSED | React DOM property assignment; img src cannot trigger JS execution |

### Repudiation

| ID | Component | Description | Status | Evidence |
|----|-----------|-------------|--------|---------|
| T-07 | `server/src/index.ts` | **No request logging** — no audit trail of which IPs submitted what ideas. | ACCEPTED | See Accepted Risks Log |

### Information Disclosure

| ID | Component | Description | Status | Evidence |
|----|-----------|-------------|--------|---------|
| T-08 | `.env` + `server/src/index.ts:1` | **API key exposure** — `ANTHROPIC_API_KEY` loaded server-side via `dotenv/config`. No `VITE_*` env variables reference it. `.gitignore` excludes `.env`. Client bundle contains no secrets. | CLOSED | `grep VITE_ client/src/` → no results; `.gitignore` includes `.env` |
| T-09 | `server/src/routes/index.ts:6-15` | **Health endpoint fingerprinting** — previously exposed `nodeVersion`, `model`, `version`, `uptime`. Now returns only `status`, `timestamp`, `uptime`. Model name and Node version removed. | CLOSED | Reduced to `{ status, timestamp, uptime }` (fixed 2026-05-26) |

### Denial of Service

| ID | Component | Description | Status | Evidence |
|----|-----------|-------------|--------|---------|
| T-10 | `server/src/routes/analyze.ts:23-26` | **Global concurrency limit** — `MAX_CONCURRENT=3` prevents runaway parallelism. Single IP can still exhaust all 3 slots continuously. No per-IP rate limiting. | ACCEPTED | See Accepted Risks Log |
| T-11 | `server/src/index.ts:15` | **Request body size** — `express.json()` default limit is 100 KB. Idea validated to ≤500 chars inside the route after parsing. | CLOSED | Express default limit; route-level length check |

### Elevation of Privilege

| ID | Component | Description | Status | Evidence |
|----|-----------|-------------|--------|---------|
| T-12 | `server/src/index.ts:17` | **Path traversal in static serving** — `express.static()` resolves paths internally and sanitizes `..` sequences. | CLOSED | Express `serve-static` package normalizes and validates paths |

---

## Accepted Risks Log

| ID | Threat | Rationale | Owner | Revisit |
|----|--------|-----------|-------|---------|
| T-01 | CORS wildcard | No session credentials (cookies/auth headers) in use. CORS restriction would not prevent direct backend abuse — only browser-originated cross-site requests. Acceptable for a demo with no user accounts. For production: restrict to the deployment origin. | — | Pre-launch to production |
| T-07 | No request logging | Demo app with no PII handling. Adding logging infrastructure is out of scope for v1.0. For production: add structured request logging (ip, timestamp, response_status) — do NOT log idea content. | — | Pre-launch to production |
| T-10 | No per-IP rate limiting | Global concurrency limit (3) provides minimal guard. A determined attacker can burn API credits. Acceptable for a demo event with limited exposure. For production: add `express-rate-limit` middleware with per-IP window. | — | Pre-launch to production |

---

## OWASP Top 10 Coverage

| Category | Relevant? | Status | Notes |
|----------|-----------|--------|-------|
| A01 – Broken Access Control | Partial | Accepted | No auth system by design; concurrency limit only |
| A02 – Cryptographic Failures | N/A | — | No sensitive data stored or transmitted client-side |
| A03 – Injection | Yes | Closed | Prompt injection mitigated by system prompt + schema validation; no SQL/command vectors |
| A04 – Insecure Design | Yes | Accepted | Open CORS, no per-IP rate limiting documented as accepted risks |
| A05 – Security Misconfiguration | Yes | Closed | Health endpoint fingerprinting removed; CORS accepted for demo |
| A06 – Vulnerable Components | N/A | — | No known CVEs in pinned dependency versions as of audit date |
| A07 – Authentication Failures | N/A | — | No authentication by design (public demo tool) |
| A08 – Software and Data Integrity | Yes | Closed | Claude output JSON-parsed and shape-validated before use |
| A09 – Security Logging & Monitoring | Yes | Accepted | No request logging; accepted for demo |
| A10 – SSRF | N/A | — | No server-side URL fetching; Anthropic SDK handles outbound HTTP |

---

## Code Changes Made in This Audit

| File | Change | Threat Closed |
|------|--------|---------------|
| `server/src/routes/analyze.ts:21` | Added `&& body.country.length <= 100` to country validation | T-03 |
| `server/src/routes/index.ts:8-14` | Removed `model`, `version`, `nodeVersion` from health response | T-09 |

---

## Audit Trail

| Date | Action | By |
|------|--------|----|
| 2026-05-26 | Full STRIDE audit of all phases (v1.0) | learnship-security-auditor |
| 2026-05-26 | Applied country field length cap (100 chars) | learnship-security-auditor |
| 2026-05-26 | Removed stack fingerprinting from /api/health | learnship-security-auditor |

---

## Production Hardening Checklist (Pre-Launch)

Before deploying beyond the demo event:

- [ ] Restrict CORS to the production domain: `app.use(cors({ origin: 'https://chispa.app' }))`
- [ ] Add per-IP rate limiting: `express-rate-limit` with a ~10 req/minute window
- [ ] Add structured request logging (ip, status, timestamp — no idea content)
- [ ] Pin `ANTHROPIC_API_KEY` rotation schedule
- [ ] Add Content-Security-Policy header to prevent any future XSS vectors
- [ ] Consider a spend limit alert on the Anthropic account dashboard
