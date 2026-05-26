# Requirements: Chispa

**Defined:** 2026-05-26
**Core Value:** When a user submits an idea, they get a real, research-backed competitive landscape and verdict in under 90 seconds — not hallucinated guesses, but actual web-searched data surfaced live.

## v1 Requirements

### Infrastructure

- [ ] **INFRA-01**: Developer can start both server and client with a single `npm run dev` command
- [ ] **INFRA-02**: Server runs on port 3001; Vite dev server proxies API requests to it
- [ ] **INFRA-03**: Production build runs with `npm start` on port 3001
- [ ] **INFRA-04**: `GET /api/health` returns 200 with status payload

### Analysis Engine

- [ ] **ANLYS-01**: User can submit a startup idea (textarea, 20–500 chars) with an optional target country
- [ ] **ANLYS-02**: Server calls Claude with `web_search_20250305` tool to find real competitors (not hallucinated)
- [ ] **ANLYS-03**: Claude produces structured JSON: `competitors[]`, `marketSize`, `marketGrowth`, `marketTiming`, `risks[]`, `verdict` (LAUNCH/VALIDATE/PIVOT/AVOID), `verdictReason`, `firstSteps[]`
- [ ] **ANLYS-04**: Analysis completes in under 120 seconds
- [ ] **ANLYS-05**: ANTHROPIC_API_KEY is never exposed to the client (all Claude calls are server-side)

### Streaming

- [ ] **STRM-01**: Server streams Claude tool-call activity to the browser via Server-Sent Events
- [ ] **STRM-02**: Each SSE event includes a human-readable activity message ("Buscando competidores...", "Analizando el mercado...")
- [ ] **STRM-03**: Client displays a live activity feed that updates in real-time as Claude works
- [ ] **STRM-04**: SSE stream sends a `result` event with the final `AnalysisResult` JSON when complete
- [ ] **STRM-05**: SSE stream sends an `error` event on failure — server never crashes

### Dashboard

- [ ] **DASH-01**: User sees an animated transition from activity feed to dashboard when analysis completes
- [ ] **DASH-02**: Dashboard shows a radar chart with 6 risk axes (market size, competition, timing, regulatory, execution, demand)
- [ ] **DASH-03**: Dashboard shows competitor cards with name, description, funding, founded year, and website for each competitor found
- [ ] **DASH-04**: Dashboard shows a verdict card (LAUNCH/VALIDATE/PIVOT/AVOID) with color coding and reason
- [ ] **DASH-05**: Dashboard shows a market snapshot (size, growth signal, timing assessment)
- [ ] **DASH-06**: Dashboard shows concrete first steps (minimum 3 actionable items)

### Sharing

- [ ] **SHARE-01**: After analysis completes, the URL updates to `/?r=<base64-encoded-result>` without a page reload
- [ ] **SHARE-02**: Loading the app with `?r=` param auto-decodes and renders the dashboard (no re-analysis)
- [ ] **SHARE-03**: Malformed or corrupt `?r=` param shows a graceful error, not a crash

### Safety

- [ ] **SAFE-01**: Server enforces a maximum of 3 concurrent analyses (returns 429 if exceeded)
- [ ] **SAFE-02**: Concurrent analysis counter is always decremented on completion OR error (no leaked slots)
- [ ] **SAFE-03**: Server sets a 90-second timeout on the Anthropic API connection (prevents stalled slots)

## v2 Requirements

### UX Polish

- **UX-01**: User sees toast notifications for key events (analysis started, copy link success, error)
- **UX-02**: Layout is responsive on mobile viewports
- **UX-03**: User can toggle between dark and light mode

### Localization

- **L10N-01**: UI supports both Spanish (LatAm) and English via language toggle
- **L10N-02**: Portuguese (Brazil) language option available

### Export

- **EXPORT-01**: User can download analysis as a formatted PDF
- **EXPORT-02**: User can copy results as markdown text

## Out of Scope

| Feature | Reason |
|---------|--------|
| User authentication / accounts | Stateless by design — no auth needed for the demo use case |
| Database / persistent storage | Results live in shareable URLs; database adds ops overhead with no demo benefit |
| Email reports | Different job-to-be-done; scope creep beyond 90-second validator |
| Lean Canvas generator | Competes on a different axis; pulls focus from the core verdict flow |
| Pitch deck builder | Extends the app beyond "fast validator" into "business planning tool" |
| Financial models | High hallucination risk; undermines Chispa's "real data" positioning |
| Multi-idea comparison | Stateless architecture makes this complex; deferred to post-v1 |
| Team / collaboration features | No accounts = no identity = no collaboration layer |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 1 | Pending |
| INFRA-02 | Phase 1 | Pending |
| INFRA-03 | Phase 4 | Pending |
| INFRA-04 | Phase 1 | Pending |
| ANLYS-01 | Phase 3 | Pending |
| ANLYS-02 | Phase 2 | Pending |
| ANLYS-03 | Phase 2 | Pending |
| ANLYS-04 | Phase 2 | Pending |
| ANLYS-05 | Phase 2 | Pending |
| STRM-01 | Phase 2 | Pending |
| STRM-02 | Phase 2 | Pending |
| STRM-03 | Phase 3 | Pending |
| STRM-04 | Phase 2 | Pending |
| STRM-05 | Phase 2 | Pending |
| DASH-01 | Phase 3 | Pending |
| DASH-02 | Phase 3 | Pending |
| DASH-03 | Phase 3 | Pending |
| DASH-04 | Phase 3 | Pending |
| DASH-05 | Phase 3 | Pending |
| DASH-06 | Phase 3 | Pending |
| SHARE-01 | Phase 4 | Pending |
| SHARE-02 | Phase 4 | Pending |
| SHARE-03 | Phase 4 | Pending |
| SAFE-01 | Phase 2 | Pending |
| SAFE-02 | Phase 2 | Pending |
| SAFE-03 | Phase 2 | Pending |

**Coverage:**
- v1 requirements: 26 total
- Mapped to phases: 26
- Unmapped: 0 ✓

---
*Requirements defined: 2026-05-26*
*Last updated: 2026-05-26 after initial definition*
