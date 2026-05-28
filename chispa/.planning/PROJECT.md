# Chispa

> "Valida tu idea de startup. En segundos."

## What This Is

Chispa is a web platform that gives entrepreneurs a data-backed startup idea validation in under 90 seconds. A user submits their idea (and optional target country); Claude uses real web search to find actual competitors, market size data, and regulatory risks; then delivers a beautiful animated dashboard with a verdict — LAUNCH / VALIDATE / PIVOT / AVOID — plus concrete first steps. No accounts, no database, stateless by design.

## Core Value

When a user submits an idea, they get a real, research-backed competitive landscape and verdict in under 90 seconds — not hallucinated guesses, but actual web-searched data surfaced live.

## Current Milestone: v1.1 — Impeccable UI

**Goal:** Transform the functionally correct v1.0 UI into a polished, visually
distinctive interface that commands attention on a conference projection screen.

**Target features:**
- Distinctive display typography (Space Grotesk) for brand header and verdict moments
- Proper typographic hierarchy throughout — not all `text-sm`
- Redesigned App header as a genuine brand moment
- Improved color system: clear surface/background differentiation, more visible borders
- ActivityFeed visual redesign — the "wow" SSE moment needs visual energy
- VerdictCard more commanding: larger, better-proportioned, display font
- IdeaForm: select chevron, better input styling, stronger CTA
- Dashboard section differentiation — not all identical gray cards
- CompetitorCard, MarketSnapshot, RiskRadarChart, FirstSteps all polished
- ShareButton with proper icon and polished copy state

## Requirements

### Validated (v1.0 — shipped 2026-05-27)

- [x] Idea submission form (textarea + optional country field)
- [x] Live SSE activity feed showing each Claude tool call in real-time
- [x] Claude agent uses `web_search_20250305` to find REAL competitors
- [x] Structured JSON output with AnalysisResult shape
- [x] Animated dashboard: radar chart, competitor cards, verdict card, market snapshot
- [x] Shareable URL via lz-string compression
- [x] Error handling: graceful SSE error events, never crash server
- [x] Rate limiting: max 3 concurrent analyses
- [x] Single-command dev: `npm run dev`

### Active (v1.1)

See REQUIREMENTS.md for the full v1.1 requirement list.

### Out of Scope

- User authentication — stateless by design
- Database / persistent storage
- Email reports
- Dark/light mode toggle — dark theme only
- Mobile-responsive layout — desktop-first for demo

## Context

**Target event:** AI Week Summit Guatemala 2026 — a 45-minute live presentation demo. The app must be impressive in a conference room projected on a screen.

**Primary users:**
1. Entrepreneurs in LatAm wanting fast idea validation before investing time/money
2. CTOs evaluating whether to greenlight a new product line
3. Product teams stress-testing assumptions before sprint commitment

**Problem being solved:** Getting a structured reality-check on a startup idea historically required expensive consultants or months of independent research. Chispa compresses this to 90 seconds using Claude as an autonomous research agent — not just a text generator, but an agent that actually searches the web and reads sources.

**Key differentiator:** The live SSE activity feed showing Claude's tool calls in real-time is the "wow factor" for the demo — audience sees Claude thinking and working, not just a spinner.

**Tech environment:** Full TypeScript stack. Backend is Express + Node.js. Frontend is React + Vite. Claude SDK via `@anthropic-ai/sdk` with `web_search_20250305` tool enabled. Real-time via Server-Sent Events (not WebSockets — simpler, fits Claude's streaming API).

## Constraints

- **Stateless**: No user accounts, no database — results encoded in shareable URLs (base64 JSON)
- **Single command**: `npm run dev` must start both Express server AND Vite dev server (concurrently)
- **Performance**: Analysis must complete in under 120 seconds
- **Security**: ANTHROPIC_API_KEY never exposed to client — all Claude calls happen server-side
- **Demo**: Works on localhost:3001; `npm start` runs production build
- **Rate limiting**: Max 3 concurrent analyses to prevent API abuse and demo server overload
- **Design**: Dark theme — #0a0a0f background, #7c3aed purple accent; Tailwind CSS + Framer Motion

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| SSE over WebSockets | Simpler protocol, works perfectly with Claude's streaming API, no socket.io needed | — Pending |
| Claude as research agent (not just generator) | `web_search_20250305` tool makes Claude actually search the web — real data, not hallucinations | — Pending |
| Base64-encoded shareable URLs | No database needed; results portable; fits constraint of stateless architecture | — Pending |
| React + Vite frontend | Fast HMR, TypeScript native, pairs well with Express backend via concurrently proxy | — Pending |
| Recharts for radar chart | Good TypeScript support, animatable, works well with dark themes | — Pending |
| Framer Motion for animations | Best-in-class React animation library; critical for demo wow factor | — Pending |

---
*Last updated: 2026-05-27 — v1.1 milestone started*
