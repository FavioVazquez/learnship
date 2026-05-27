# ✦ Chispa

**Valida tu idea de startup. En segundos.**

Chispa is a startup idea validator powered by Claude. Describe your idea in plain language (Spanish or English) — Claude searches for real competitors, reads market reports, and delivers a full animated analysis in under 90 seconds.

Built live at [AI Week Summit Guatemala 2026](https://panamericanlatam.com/ai-week-summit-guatemala-2026/) using [learnship](https://github.com/FavioVazquez/learnship) — a demo of agentic engineering in action.

---

## How it works

```
You describe an idea
        ↓
Claude searches the web (real tool calls, streamed live)
        ↓
Animated dashboard appears:
  • Risk Radar (6 axes)
  • Competitor Map
  • Market Snapshot
  • Verdict: LANZA / VALIDA / PIVOTA / EVITA
  • First 30 days action plan
        ↓
Share the URL with anyone
```

No accounts. No database. Stateless by design.

---

## Quick Start

```bash
# 1. Clone
git clone https://github.com/FavioVazquez/chispa.git  # standalone repo — coming soon
cd chispa

# 2. Install
npm install
cd server && npm install && cd ..
cd client && npm install && cd ..

# 3. Set your API key
cp server/.env.example server/.env
# Edit server/.env → add your ANTHROPIC_API_KEY

# 4. Run
npm run dev
```

Open [http://localhost:5173](http://localhost:5173)

> **Note:** You need an [Anthropic API key](https://console.anthropic.com/). The app uses `claude-opus-4-7` with web search tool access.

---

## Production

```bash
npm run build    # Builds client → dist/, compiles server
npm start        # Serves everything on :3001
```

Open [http://localhost:3001](http://localhost:3001)

---

## Demo Script

1. Open the app in a browser
2. Type a startup idea in Spanish, e.g. *"Una app para conectar freelancers con PyMEs en Guatemala"*
3. Select country: Guatemala
4. Click **Analizar** — watch live tool-call activity feed (15–45 seconds)
5. Dashboard appears: verdict card, risk radar, competitor cards, market snapshot, first steps
6. Click **Copiar enlace** — share the URL with anyone; it loads the same dashboard instantly (no re-analysis)

---

## Architecture

```
chispa/
├── server/                   Node.js + Express + TypeScript
│   └── src/
│       ├── index.ts          Entry point, static serving
│       ├── routes/
│       │   └── analyze.ts    POST /api/analyze → SSE stream
│       ├── agent/
│       │   └── analyzer.ts   Claude agent with web_search tool
│       └── types/
│           └── analysis.ts   Shared types (AnalysisResult, SSEMessage)
│
├── client/                   React + Vite + TypeScript
│   └── src/
│       ├── App.tsx            Routing: form → stream → dashboard
│       ├── components/
│       │   ├── IdeaForm.tsx   Submission form
│       │   ├── ActivityFeed.tsx  Live Claude tool calls
│       │   ├── Dashboard.tsx  Full results view
│       │   ├── RiskRadarChart.tsx Recharts radar (6 risk axes)
│       │   ├── CompetitorCard.tsx
│       │   └── VerdictCard.tsx
│       └── hooks/
│           └── useAnalysis.ts SSE client hook
│
└── .planning/                learnship project management
    ├── config.json           Workflow configuration
    ├── PROJECT.md            Project context
    ├── REQUIREMENTS.md       Feature requirements
    ├── ROADMAP.md            Phase breakdown
    ├── STATE.md              Current milestone / phase status
    ├── SECURITY.md           STRIDE threat register
    ├── LEARNINGS.md          Engineering learnings from the build
    ├── IMPECCABLE-AUDIT.md   UI quality audit findings
    ├── research/             Domain research from new-project
    └── phases/               Per-phase plans, summaries, and verification
```

---

## SSE Protocol

The server streams JSON events line-by-line:

```typescript
// While Claude is working (source is the tool name, e.g. "web_search"):
{ "type": "step",   "text": "Buscando competidores directos...", "source": "web_search" }
{ "type": "step",   "text": "Analizando el mercado...",          "source": "web_search" }

// On completion:
{ "type": "result", "data": { ...AnalysisResult } }

// On error:
{ "type": "error",  "message": "Claude no pudo completar el análisis" }
```

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Backend | Node.js, Express, TypeScript |
| Frontend | React 18, Vite, TypeScript |
| Styling | Tailwind CSS, Framer Motion |
| Charts | Recharts |
| AI | Anthropic SDK, `claude-opus-4-7`, `web_search_20250305` |
| Real-time | Server-Sent Events (SSE) |

---

## Built with learnship

This project was built using [learnship](https://github.com/FavioVazquez/learnship) — an agentic engineering platform that runs research, planning, execution, review, and security phases as parallel subagents.

The `.planning/` folder contains all the artifacts learnship generated: requirements, roadmap, per-phase plans, and review findings. Open them to see what agentic engineering looks like from the inside.

```bash
cat .planning/PROJECT.md       # What we're building and why
cat .planning/ROADMAP.md       # Phase breakdown
cat .planning/REQUIREMENTS.md  # Full requirements spec
ls  .planning/phases/          # Per-phase plans and execution logs
```
