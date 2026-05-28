# Workshop Demo Guide
## "From Vibe Coding to Agentic Engineering"
### AI Week Summit Guatemala 2026 — 45 minutes

> **v1.1 update:** The finished app now uses Space Grotesk + Plus Jakarta Sans typography, a deeper dark color system, and per-component design polish for conference-scale legibility. No functional changes — the demo script below is unchanged.

---

## The Story Arc

You have the **finished Chispa app already running**. The live demo is not about finishing in 45 minutes — it's about *showing the process* that produced it. You demonstrate building Phase 1 from scratch with learnship, then reveal the full app as "this is where that process takes you."

**The punchline:** "I used agentic engineering to build a tool that uses agentic engineering to evaluate ideas."

---

## Timeline

| Min | What you do | What the audience sees |
|-----|-------------|------------------------|
| 0–3 | Open the finished Chispa app, submit a real idea live | "Wow, this is what we're building" |
| 3–6 | Show the vibe-coded version (single file, no structure) | "This is how most people start" |
| 6–7 | Install learnship in a fresh folder | The scaffolding moment |
| 7–17 | Run `/learnship:new-project` | Questioning ceremony, research, roadmap |
| 17–22 | Run `/learnship:discuss-phase 1` | Decision capture before planning |
| 22–32 | Run `/learnship:plan-phase 1` | Parallel subagents planning live |
| 32–44 | Run `/learnship:execute-phase 1` | Wave execution, actual code appearing |
| 44–45 | Open the working Phase 1 app | "In 45 minutes, we have a running foundation" |

---

## Pre-Demo Setup (do this before the session)

### 1. Have two terminal windows ready

**Terminal A** — the fresh workshop project (this is what you build live):
```bash
mkdir ~/chispa-live && cd ~/chispa-live
```

**Terminal B** — the finished Chispa (already running, for the opening demo):
```bash
cd /path/to/finished/chispa
cp server/.env.example server/.env
# Edit server/.env — set ANTHROPIC_API_KEY=sk-ant-...
npm start
# The server validates the key on boot and exits with a clear error if it's missing.
# Verify: open http://localhost:3001
```

### 2. Install learnship globally
```bash
npx learnship --claude --global
```

### 2b. Set up vibe.py
```bash
pip install -r requirements.txt
cp .env.example .env
# Edit .env — add your ANTHROPIC_API_KEY
```
Requires Python 3.8+ and pip. `vibe.py` reads the key from `.env` via python-dotenv.

### 3. Test Claude Code is authenticated
```bash
claude --version
# Should return version number, not an auth error
```

### 4. Prepare your browser
- Tab 1: finished Chispa at `http://localhost:3001`
- Tab 2: will open `http://localhost:5173` after the live build
- Tab 3: `.planning/` folder in your file explorer or VS Code

### 5. Decide: localhost or deployed?

> **⚠️ IMPORTANT — Read before the conference:**
> The `?r=` shareable URLs contain the full analysis as compressed data client-side. They work across devices **only if the app is deployed to a public URL**. On localhost, only your machine can open them.
>
> - **Safest for demo:** Deploy to Railway/Render/Fly.io (~15 min). Set `ANTHROPIC_API_KEY` as an env var. Change the narration at minute 0–3 to share the public URL.
> - **Localhost only:** Fine for showing the UX — just don't say "share with anyone." Adjust the closing line accordingly.
>
> Also: set a **spend limit** in [console.anthropic.com](https://console.anthropic.com) before the session. Each analysis costs ~$0.05–0.15. If you deploy and the URL gets circulated in the room, 100 people × $0.10 = $10 per wave. A $5–10 limit prevents surprises.

### 6. Have these ready to paste (see "Copy-Paste Prompts" below)

---

## Minute-by-Minute Script

### [0–3 min] Open with the finished product

Open Terminal B, which has the finished app running.

**Say:**
> "This is Chispa — a startup idea validator. Watch what happens when I submit a real idea."

Type an idea into the form. Something the audience will recognize:
```
"Una plataforma de pagos digitales para mercados rurales en Guatemala
donde el acceso bancario es limitado pero los teléfonos Android son comunes."
```

Let Claude research live — the activity feed will show tool calls appearing. When the dashboard loads:

> "Real competitors. Real market data. A verdict with reasoning. And I can share this URL — the result is encoded right in the link, no server needed."

> *(Note to presenter: the ?r= URL contains the full analysis as compressed data. Audience can load it in their own browser **if the app is deployed**. On localhost, the URL only works on your machine — see Pre-Demo Setup step 5.)*

Point out the activity feed:
> "This is not a black box. You can see every tool call Claude made. That transparency is what agentic engineering looks like."

---

### [3–6 min] The vibe-coded equivalent

Open `vibe.py` from the repo root (it's committed — copy it to your demo machine beforehand):

```python
# vibe.py — "quick validation tool" (vibe coded)
import anthropic
import os
import sys
from dotenv import load_dotenv

load_dotenv()

if not os.environ.get('ANTHROPIC_API_KEY'):
    print("Error: ANTHROPIC_API_KEY not set.")
    print("  cp .env.example .env  # then fill in your key")
    sys.exit(1)

client = anthropic.Anthropic()

idea = " ".join(sys.argv[1:])
if not idea:
    print("Usage: python vibe.py <your startup idea>")
    sys.exit(1)

response = client.messages.create(
    model="claude-sonnet-4-6",
    max_tokens=1000,
    messages=[{"role": "user", "content": f"Analyze this startup idea: {idea}"}]
)
print(response.content[0].text)
```

First time only:
```bash
pip install -r requirements.txt
cp .env.example .env
# Edit .env — add your ANTHROPIC_API_KEY
```

Run it:
```bash
python vibe.py "una plataforma de pagos para Guatemala"
```

**Say:**
> "This works. You get something back. But there are no real web searches, no competitor data, no structure, no UI, no error handling, no tests, no security review, no shareable URL, no way to maintain this. This is vibe coding. It gets you started, but it doesn't get you to production. Let me show you the difference."

---

### [6–7 min] Install learnship

Switch to Terminal A (the empty `~/chispa-live` folder).

```bash
npx learnship --claude --global
```

**Say:**
> "learnship is an agentic engineering platform — 57 workflows, 17 specialist AI agents, all running in parallel. It's how we go from vibe to production. Let's start."

---

### [7–17 min] `/learnship:new-project`

In Claude Code (open it if not already):
```
/learnship:new-project
```

**Answer the questions like this:**

When asked Setup Mode:
> Click **"Quick — use recommended defaults"**

When asked about the project — type this (have it ready to paste):

```
Chispa — startup idea validator web platform.

Users submit a startup idea in Spanish or English. Claude uses web search
to find real competitors, market size data, and risks. Results stream live
to the browser via Server-Sent Events. A beautiful animated dashboard
reveals the analysis: radar chart, competitor cards, verdict card
(LAUNCH / VALIDATE / PIVOT / AVOID), and a 30-day action plan.

Tech stack: Node.js + Express + TypeScript backend, React + Vite frontend,
Tailwind CSS, Framer Motion animations, Recharts for the radar chart,
Anthropic SDK with web_search_20250305 tool.

No user accounts. No database. Stateless — shareable URLs via base64 encoding.
```

**While learnship researches (it will do web searches for 2-3 min):**
> "Right now, learnship is doing domain research — looking at how other startup validation tools work, what the Claude Agent SDK can do, how to structure SSE streaming. This is the 'research' step that most people skip when vibe coding. It makes every subsequent decision better."

When the roadmap appears, show it to the audience.
> "Four phases. Each one is a vertical slice that delivers something working. This is how agentic engineering thinks — not a big bang, but incremental deliverables."

---

### [17–22 min] `/learnship:discuss-phase 1`

```
/learnship:discuss-phase 1
```

**Paste these answers when asked:**

```
Phase 1 is about the foundation: Express server, React app,
TypeScript configuration, and verifying the Claude SDK is wired up.
The deliverable is a health endpoint that returns 200 and a placeholder
frontend. Nothing fancy — just confirming the plumbing works.

Key decisions:
- Port 3001 for server, 5173 for Vite dev server
- Server proxies /api from the client in dev
- ESM modules throughout (not CommonJS)
- Shared types in server/src/types/analysis.ts — client imports the same types
```

**Say:**
> "This is the discuss-phase workflow. Before any planning happens, learnship captures the decisions and constraints for this phase. It creates a CONTEXT.md that planners read. This is how you avoid the classic AI coding trap — getting code that works locally but ignores your actual requirements."

---

### [22–32 min] `/learnship:plan-phase 1`

```
/learnship:plan-phase 1
```

**Say while it runs:**
> "Watch what happens now. learnship spawns three parallel agents: a researcher, a planner, and a plan-checker. They each get a fresh 200k context window. They work simultaneously."

Point to the terminal:
> "The researcher is looking at Express + Vite monorepo patterns. The planner is writing the task breakdown. The plan-checker will verify the plan actually achieves the phase goal before we execute a single line of code."

When PLAN.md appears:
> "This is a wave-ordered execution plan. Wave 1 runs in parallel — server scaffolding and client scaffolding happen simultaneously. Wave 2 depends on Wave 1. This is how learnship gets speed without chaos."

Show the PLAN.md to the audience.

---

### [32–44 min] `/learnship:execute-phase 1`

```
/learnship:execute-phase 1
```

**Say while it runs:**
> "Now execution. Each plan in the wave gets its own agent — a fresh context budget, no accumulated noise from previous work. Watch the files appear."

Open VS Code or your file explorer side-by-side with the terminal. The audience can watch files being created in real time.

After Wave 1 completes:
> "Server and client scaffolded simultaneously. Now Wave 2 — the integration work that needs both to exist first."

When execution finishes, run the verification:
```bash
curl http://localhost:3001/api/health
```

Show the result:
```json
{"status":"ok","model":"claude-sonnet-4-6","version":"1.0.0","timestamp":"...","uptime":12.34}
```

> "Working foundation. TypeScript compiles. Health endpoint responds. In 15 minutes of execution, we have the same thing that would take a developer half a day to set up manually — and every file has proper error handling, the types are correct, the configuration follows best practices."

---

### [44–45 min] Reveal and close

Point to the finished Chispa running in Tab 1.

> "This is where Phase 1 takes you, after Phase 2 (the Claude agent), Phase 3 (the full UI), and Phase 4 (polish and deployment). Four phases, four execute-phase runs, four rounds of review and security checks. The full app took about 45 minutes of learnship execution — and I have the git history, the PLAN.md files, the review findings, and the security audit to prove every decision was intentional."

Open `.planning/phases/` in VS Code:
> "This is the difference between vibe coding and agentic engineering. Not just the code — the artifacts, the decisions, the audit trail."

Final line:
> "Chispa is now live. The source code is on GitHub — you can run it with your own API key in 5 minutes." *(If you deployed before the talk, replace with: "The URL is on the screen — try it on your phone.")*

---

## Copy-Paste Prompts

### For `/learnship:new-project`

Project description prompt (paste when asked):
```
Chispa — startup idea validator web platform.

Users submit a startup idea in Spanish or English. Claude uses the
web_search_20250305 tool to find real competitors, market size data,
funding activity, and risks. Each tool call streams live to the browser
via Server-Sent Events so users watch Claude research in real time.
A beautiful animated dashboard reveals the complete analysis:
risk radar chart (6 axes), competitor cards, verdict card
(LAUNCH / VALIDATE / PIVOT / AVOID), market snapshot, and a
30-day action plan.

Tech stack:
- Backend: Node.js + Express + TypeScript, port 3001
- Frontend: React + Vite + TypeScript, port 5173 (dev)
- Styling: Tailwind CSS, dark theme (#0a0a0f background, #7c3aed accent)
- Animations: Framer Motion
- Charts: Recharts (RadarChart)
- AI: @anthropic-ai/sdk, claude-sonnet-4-6, web_search_20250305 tool
- Real-time: Server-Sent Events (SSE), text/event-stream

Constraints:
- No user accounts, no database, stateless design
- Shareable URLs via base64-encoded result in query param (?r=...)
- ANTHROPIC_API_KEY in server .env, never exposed to client
- Rate limit: max 3 concurrent analyses
- Single command: npm run dev starts both server and client

Phases: Foundation → Analysis Engine → Web Frontend → Polish & Demo Prep
```

---

### For `/learnship:discuss-phase 1`

```
Phase 1 is the foundation. Goal: a running Express + React monorepo
where the health endpoint returns 200 and TypeScript compiles clean.

Key decisions:
- Monorepo: server/ and client/ as separate npm workspaces with a root package.json
- Server: port 3001, ESM modules, tsx for dev (nodemon), tsc for production
- Client: Vite dev server on 5173, proxies /api to localhost:3001
- Shared types: server/src/types/analysis.ts defines AnalysisResult and SSEMessage
- Client copies the same types to client/src/types/analysis.ts
- Production: client builds to dist/, Express serves it as static files
- Claude SDK installed on server only — never imported in client code

No analysis engine in Phase 1. POST /api/analyze returns 501.
Just confirm: npm run dev works, health endpoint returns 200, tsc passes.
```

---

### For `/learnship:discuss-phase 2`

```
Phase 2 is the analysis engine — the core Claude agent.

Key decisions:
- Route: POST /api/analyze with body { idea: string, country?: string }
- Validate: idea must be 20–500 chars, return 400 otherwise
- SSE: set headers immediately (Content-Type: text/event-stream, Cache-Control: no-cache)
- Claude loop: use streaming messages API with web_search_20250305 tool
- On each tool call: emit { type: "step", text, source? } where source is the tool name (e.g. "web_search")
- On final message: parse assistant text as JSON, emit { type: "result", data: AnalysisResult }
- Error handling: any thrown error emits { type: "error", message } then closes stream
- Rate limiting: in-memory counter, max 3 concurrent, return 429 if exceeded
- System prompt: instructs Claude to return ONLY valid JSON in the exact AnalysisResult shape

AnalysisResult shape:
{
  competitors: [{ name, description, funding?, founded?, website? }],
  marketSize: string,
  marketGrowth: string,
  marketTiming: "too_early" | "right_time" | "too_late",
  risks: [{ title, severity: "high"|"medium"|"low", mitigation, category: "Mercado"|"Competencia"|"Técnico"|"Regulatorio"|"Timing"|"Capital" }],
  verdict: "LAUNCH" | "VALIDATE" | "PIVOT" | "AVOID",
  verdictReason: string,
  firstSteps: string[] (5 items, only for LAUNCH or VALIDATE)
  searchedAt: ISO timestamp
}
```

---

### For `/learnship:discuss-phase 3`

```
Phase 3 is the full web frontend. Every UI component, complete flow.

Key decisions:
- App state machine: "idle" → "streaming" → "complete" | "error"
- IdeaForm: textarea (min 20, max 500 chars, live counter), optional country select,
  submit button shows spinner during streaming
- ActivityFeed: list of SSE step events, each animates in with Framer Motion,
  shows source badge (domain) when present, scrolls automatically
- Dashboard reveal: when type="result" received, slide up with staggered card animation
- RadarChart: 6 axes — Mercado, Competencia, Técnico, Regulatorio, Timing, Capital
  Each risk maps to an axis via the `category` field; severity high=90, medium=60, low=30 (0–100 scale); animate on mount
- VerdictCard: LANZA (green), VALIDA (amber), PIVOTA (orange), EVITA (red)
  Large font, flip-in animation, 2-3 sentence reasoning below
- CompetitorCard: favicon from https://www.google.com/s2/favicons?domain=X, name, description,
  funding badge if present
- MarketSnapshot: TAM string, growth string, timing badge
- FirstSteps: numbered list, only rendered for LANZA or VALIDA
- ShareButton: encodes result as base64 JSON → appends /?r=<encoded> → copies to clipboard
  Shows "¡Copiado!" toast for 2 seconds
- URL loading: on mount, check for ?r= param, decode and load dashboard directly

Color system: bg-[#0a0a0f], surface-[#13131a], border-[#1f1f2e], primary-[#7c3aed]
```

---

### For `/learnship:discuss-phase 4`

```
Phase 4 is polish, error states, and production readiness.

Key decisions:
- Error states: network failure shows retry button, Claude timeout (>120s) shows specific message,
  JSON parse error falls back to showing raw text with "analysis incomplete" warning
- Loading skeleton: while streaming, show pulsing placeholder cards where dashboard will appear
- Production build: client builds to client/dist/, server always serves it via express.static
  (no NODE_ENV conditional — simpler and more reliable)
- npm run build: cd client && npm run build, then cd server && npm run build (tsc)
- npm start: node dist/index.js (production)
- .env.example: ANTHROPIC_API_KEY=your_key_here, PORT=3001, CORS_ORIGIN (optional, for cross-domain production)
- server/src/index.ts: validate ANTHROPIC_API_KEY at startup — process.exit(1) with a clear message if missing
- README: setup instructions, architecture diagram, how to get API key, demo instructions
- Final impeccable pass: spacing, mobile responsiveness, loading states, empty states
- /api/health enhancement: include uptime, model name, version
```

---

## Audience Q&A — Expected Questions

**"How much does this cost to run?"**
> Each analysis uses roughly 2,000–5,000 tokens for web search + reasoning. At claude-sonnet-4-6 pricing, that's about $0.05–0.15 per analysis. You could add a free tier of 5 analyses/day, then charge for more.

**"Can I deploy this publicly?"**
> Yes — it's a standard Node.js app. Vercel for the frontend, Railway or Render for the backend, or a single VPS running `npm start`. Add rate limiting and you're good.

**"Does it work for ideas in Spanish?"**
> Yes. Claude handles both natively. The web search results come back in English but Claude summarizes in context. You could force Spanish output by adding a language instruction to the system prompt.

**"Can I use this with my team's Claude subscription instead of an API key?"**
> For server-side use, you need an API key from console.anthropic.com. The `@anthropic-ai/sdk` package is the official SDK — the same one used in this project.

**"What if Claude hallucinates competitors that don't exist?"**
> Web search grounding reduces this significantly — Claude reads actual URLs and reports what it finds. You'll still want a disclaimer: "Validation is a starting point, not a substitute for market research." The transparency (showing sources in the activity feed) helps users evaluate the output.

**"How long did it take to build?"**
> The full app took 4 learnship phases — roughly 2 hours of agent execution time. The planning artifacts, review findings, and security audit are all in `.planning/`. That's the answer to "how long" AND "how do I know it's good?"

---

## If Something Goes Wrong During the Demo

**Claude Code hangs or takes too long:**
> "This is one of those moments where the AI is thinking hard. learnship has a context monitor that warns when you're approaching the limit — you'd normally see that warning appear and know it's time to break this into a smaller task."

**The execute-phase takes longer than expected:**
> "Wave execution is running. Each agent has a fresh context — no accumulated noise. This is why it's more thorough than a single sequential run. While we wait, let me show you what the PLAN.md looks like — this is what the agents are executing against."

**Something doesn't compile:**
> "learnship runs the plan-checker before execution for exactly this reason. But even with verification, real code sometimes needs a fix. Let me show you `/learnship:debug` — it spawns a dedicated debugging agent that traces from the symptom to the root cause."

---

## Resources to Share with the Audience

- **learnship**: `npx learnship --claude --global`
- **Chispa source**: github.com/FavioVazquez/chispa  *(standalone repo — publish before the talk)*
- **Anthropic API key**: console.anthropic.com
- **Claude Code**: code.claude.com
