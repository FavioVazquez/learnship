# learnship

![learnship banner](assets/banner.png)

<p align="center">
  <a href="https://github.com/FavioVazquez/learnship/actions/workflows/ci.yml"><img src="https://github.com/FavioVazquez/learnship/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI"></a>
  <a href="https://github.com/FavioVazquez/learnship/releases/latest"><img src="https://img.shields.io/github/v/release/FavioVazquez/learnship?color=3b82f6&label=release" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-22c55e.svg" alt="License: MIT"></a>
  <a href="https://github.com/FavioVazquez/learnship/stargazers"><img src="https://img.shields.io/github/stars/FavioVazquez/learnship?style=flat&color=f59e0b" alt="Stars"></a>
  <img src="https://img.shields.io/badge/platforms-5-0ea5e9" alt="5 platforms">
  <img src="https://img.shields.io/badge/workflows-42-3b82f6" alt="42 workflows">
</p>

<p align="center">
  <strong>Agentic engineering done right.</strong><br>
  <a href="#-get-started-in-30-seconds">Get Started</a> ·
  <a href="#-how-it-works">How it works</a> ·
  <a href="#-the-phase-loop">Phase Loop</a> ·
  <a href="#-workflow-reference--advanced">All Workflows</a> ·
  <a href="#-configuration">Configuration</a> ·
  <a href="CONTRIBUTING.md">Contributing</a> ·
  <a href="CHANGELOG.md">Changelog</a>
</p>

---

## ⚡ Get Started in 30 Seconds

### 1. Install

![Install learnship](assets/install.png)

```bash
# Recommended — runs directly from GitHub, no clone needed
npx github:FavioVazquez/learnship
```

The installer auto-detects your platform. Choose **global** (all projects) or **local** (current project only):

```bash
npx github:FavioVazquez/learnship --global   # all projects
npx github:FavioVazquez/learnship --local    # this project only
```

Or specify your platform explicitly — see [Platform Support](#-platform-support) below.

### 2. Start your AI agent and type

```
/ls
```

(or the platform equivalent — see the table below). `/ls` detects whether you have a project, walks you through starting one if not, or tells you exactly where you are and what to do next.

---

## 🌐 Platform Support

learnship works on **5 platforms**. Pick your tool:

| Platform | Install command | Invoke commands as |
|----------|----------------|-------------------|
| **Windsurf** | `npx github:FavioVazquez/learnship --windsurf --global` | `/ls`, `/new-project` |
| **Claude Code** | `npx github:FavioVazquez/learnship --claude --global` | `/learnship:ls`, `/learnship:new-project` |
| **OpenCode** | `npx github:FavioVazquez/learnship --opencode --global` | `/learnship-ls`, `/learnship-new-project` |
| **Gemini CLI** | `npx github:FavioVazquez/learnship --gemini --global` | `/learnship:ls`, `/learnship:new-project` |
| **Codex CLI** | `npx github:FavioVazquez/learnship --codex --global` | `$learnship-ls`, `$learnship-new-project` |

```bash
# All platforms at once
npx github:FavioVazquez/learnship --all --global
```

### 🤖 Platform capabilities

Each platform gets the best experience it supports:

| Feature | Windsurf | Claude Code | OpenCode | Gemini CLI | Codex CLI |
|---------|----------|-------------|----------|------------|-----------|
| Slash commands | ✓ | ✓ | ✓ | ✓ | `$skills` |
| Real parallel subagents | — | ✓ | ✓ | ✓ | ✓ |
| Parallel wave execution | — | ✓ opt-in | ✓ opt-in | ✓ | ✓ opt-in |
| Specialist agent pool | — | ✓ | ✓ | ✓ | ✓ |
| Skills (native `@invoke`) | ✓ | — | — | — | — |
| Skills (context files) | ✓ | ✓ | ✓ | ✓ | ✓ |

**What "parallel subagents" means:** On Claude Code, OpenCode, and Codex, `execute-phase` can spawn a dedicated executor agent per plan within a wave — each with its own full 200k context budget. Plans in the same wave run in parallel. Enable with `"parallelization": true` in `.planning/config.json`. All platforms default to sequential (always safe).

---

## 🗺️ The 5 Commands You Actually Need

![5 commands diagram](assets/quick-start-flow.png)

learnship has 42 workflows. You don't need to know them all. Start with these five — everything else surfaces naturally from `/ls`.

| Command | What it does | When to use |
|---------|-------------|-------------|
| `/ls` | Show status, recent work, and next step — offer to run it | **Start every session here** |
| `/next` | Read state and immediately run the right next workflow | When you just want to keep moving |
| `/new-project` | Full init: questions → research → requirements → roadmap | Starting a new project |
| `/quick "..."` | One-off task with atomic commits, no planning ceremony | Small fixes, experiments |
| `/help` | All 42 workflows organized by category | Discovering capabilities |

> **Tip:** `/ls` works for both new and returning users. New user with no project? It explains learnship and offers to run `/new-project`. Returning user? It shows your progress and suggests exactly what to do next.

---

## 🔄 The Phase Loop

![Phase loop](assets/phase-loop.png)

Once you have a project, every feature ships through the same four-step loop:

```mermaid
flowchart LR
    DP["/discuss-phase N<br/>Capture decisions"]
    PP["/plan-phase N<br/>Research + plans"]
    EP["/execute-phase N<br/>Build + commit"]
    VW["/verify-work N<br/>UAT + diagnose"]

    DP --> PP --> EP --> VW
    VW -->|"next phase"| DP
    VW -->|"all done"| DONE["✓ /complete-milestone"]
```

| Step | Command | What happens |
|------|---------|-------------|
| **1. Discuss** | `/discuss-phase N` | You and the agent align on implementation decisions before any code |
| **2. Plan** | `/plan-phase N` | Agent researches the domain, creates executable plans, verifies them |
| **3. Execute** | `/execute-phase N` | Plans run in dependency order — atomic commit per task |
| **4. Verify** | `/verify-work N` | You do UAT; agent diagnoses any gaps and creates fix plans |

**Just starting?** `/ls` or `/next` will route you into the right step automatically.

---

## 🏗️ How It Works

![How it works](assets/how-it-works.png)

Three integrated layers that reinforce each other:

| Layer | What it does |
|-------|-------------|
| **Workflow Engine** | Spec-driven phases → context-engineered plans → wave-ordered execution → verified delivery |
| **Learning Partner** | Neuroscience-backed checkpoints at every phase transition — retrieval, reflection, spacing, struggle |
| **Design System** | 17 impeccable steering commands for production-grade UI — `/audit`, `/critique`, `/polish`, and more |

```mermaid
graph LR
    WE["Workflow Engine<br/>Spec-driven phases<br/>Context-engineered plans<br/>Atomic execution"] --> LP["Learning Partner<br/>Neuroscience-backed<br/>Woven into workflows<br/>Builds real understanding"]
    WE --> DS["Design System<br/>Production-grade UI<br/>Impeccable aesthetics<br/>Anti-AI-slop standards"]
    LP --> DS
    DS --> LP
```

---

## 🆚 Agentic Engineering vs Vibe Coding

![Vibe coding vs Agentic engineering](assets/vibe-vs-agentic.png)

| | Vibe coding | Agentic engineering |
|-|------------|--------------------|
| **Context** | Resets every session | Engineered into every agent call |
| **Decisions** | Implicit, forgotten | Tracked in `DECISIONS.md`, honored by the agent |
| **Plans** | Ad-hoc prompts | Spec-driven, verifiable, wave-ordered |
| **Outcome** | Code you shipped | Code you shipped **and understand** |

---

## 🧠 Context Engineering

![Context engineering](assets/context-engineering.png)

Every agent invocation in learnship is loaded with structured context — nothing is guessed:

```mermaid
flowchart LR
    subgraph CONTEXT["Loaded into every agent call"]
        A["AGENTS.md<br/>Project soul + current phase"]
        B["REQUIREMENTS.md<br/>What we're building"]
        C["DECISIONS.md<br/>Every architectural choice"]
        D["Phase CONTEXT.md<br/>Implementation preferences"]
    end
    CONTEXT --> AGENT["AI Agent"]
    AGENT --> P["Executable PLAN.md"]
    AGENT --> S["Commits + SUMMARY.md"]
```

---

## 🗂️ AGENTS.md — Persistent Project Memory

![AGENTS.md](assets/agents-md.png)

`/new-project` generates an `AGENTS.md` at your project root. Your AI agent reads it as a persistent system rule for every conversation — so it always knows where the project stands without you repeating yourself.

```
AGENTS.md                   ← your AI agent reads this every conversation
├── Soul & Principles        # Pair-programmer framing, 10 working principles
├── Platform Context         # Points to .planning/, explains the phase loop
├── Current Phase            # Updated automatically by workflows
├── Project Structure        # Filled during new-project from your answers
├── Tech Stack               # Filled from research results
└── Regressions              # Updated by /debug when bugs are fixed
```

---

## 📖 Workflow Reference — Advanced

> These are all 42 workflows. Most users discover them naturally from `/ls`. Scan this when you want to know if a specific capability exists.

### Core Workflow

| Workflow | Purpose | When to use |
|----------|---------|-------------|
| `/new-project` | Full init: questions → research → requirements → roadmap | Start of any new project |
| `/discuss-phase [N]` | Capture implementation decisions before planning | Before every phase |
| `/plan-phase [N]` | Research + create + verify plans | After discussing a phase |
| `/execute-phase [N]` | Wave-ordered execution of all plans | After planning |
| `/verify-work [N]` | Manual UAT with auto-diagnosis and fix planning | After execution |
| `/complete-milestone` | Archive milestone, tag release, prepare next | All phases verified |
| `/audit-milestone` | Pre-release: requirement coverage, stub detection | Before completing milestone |
| `/new-milestone [name]` | Start next version cycle | After completing a milestone |

### Navigation

| Workflow | Purpose | When to use |
|----------|---------|-------------|
| `/ls` | Status + next step + offer to run it | Start every session here |
| `/next` | Auto-pilot: reads state and runs the right workflow | When you just want to keep moving |
| `/progress` | Same as `/ls` — status overview + smart routing | "Where am I?" |
| `/resume-work` | Restore full context from last session | Starting a new session |
| `/pause-work` | Save handoff file mid-phase | Stopping mid-phase |
| `/quick [description]` | Ad-hoc task with full guarantees | Bug fixes, small features |
| `/help` | Show all available workflows | Quick command reference |

### Phase Management

| Workflow | Purpose | When to use |
|----------|---------|-------------|
| `/add-phase` | Append new phase to roadmap | Scope grows after planning |
| `/insert-phase [N]` | Insert urgent work between phases | Urgent fix mid-milestone |
| `/remove-phase [N]` | Remove future phase and renumber | Descoping a feature |
| `/research-phase [N]` | Deep research only, no plans yet | Complex/unfamiliar domain |
| `/list-phase-assumptions [N]` | Preview intended approach before planning | Validate direction |
| `/plan-milestone-gaps` | Create phases for audit gaps | After audit finds missing items |

### Brownfield, Discovery & Debugging

| Workflow | Purpose | When to use |
|----------|---------|-------------|
| `/map-codebase` | Analyze existing codebase | Before `/new-project` on existing code |
| `/discovery-phase [N]` | Map unfamiliar code area before planning | Entering complex/unfamiliar territory |
| `/debug [description]` | Systematic triage → diagnose → fix | When something breaks |
| `/diagnose-issues [N]` | Batch-diagnose all UAT issues — groups by root cause | After verify-work finds multiple issues |
| `/execute-plan [N] [id]` | Run a single plan in isolation | Re-running a failed plan |
| `/add-todo [description]` | Capture an idea without breaking flow | Think of something mid-session |
| `/check-todos` | Review and act on captured todos | Reviewing accumulated ideas |
| `/add-tests` | Generate test coverage post-execution | After executing a phase |
| `/validate-phase [N]` | Retroactive test coverage audit | After hotfixes or legacy phases |

### Decision Intelligence

| Workflow | Purpose | When to use |
|----------|---------|-------------|
| `/decision-log [description]` | Capture decision with context and alternatives | After any significant architectural choice |
| `/knowledge-base` | Aggregate all decisions and lessons into one file | Before starting a new milestone |
| `/knowledge-base search [query]` | Search the project knowledge base | When you need to recall why something was built a certain way |

### Milestone Intelligence

| Workflow | Purpose | When to use |
|----------|---------|-------------|
| `/discuss-milestone [version]` | Capture goals, anti-goals before planning | Before `/new-milestone` |
| `/milestone-retrospective` | 5-question retrospective + spaced review | After `/complete-milestone` |
| `/transition` | Write full handoff document for new session/collaborator | Before handing off or long break |

### Maintenance

| Workflow | Purpose | When to use |
|----------|---------|-------------|
| `/settings` | Interactive config editor | Change mode, toggle agents |
| `/set-profile [quality\|balanced\|budget]` | One-step model profile switch | Quick cost/quality adjustment |
| `/health` | Project health check | Stale files, missing artifacts |
| `/cleanup` | Archive old artifacts | End of milestone |
| `/update` | Update the platform itself | Check for new workflows |
| `/reapply-patches` | Restore local edits after update | After `/update` if you had local changes |

---

## ⚙️ Configuration

Project settings live in `.planning/config.json`. Set during `/new-project` or edit with `/settings`.

### Full Schema

```json
{
  "mode": "yolo",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "planning": {
    "commit_docs": true,
    "search_gitignored": false
  },
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "nyquist_validation": true
  },
  "git": {
    "branching_strategy": "none",
    "phase_branch_template": "phase-{phase}-{slug}",
    "milestone_branch_template": "{milestone}-{slug}"
  }
}
```

### Core Settings

| Setting | Options | Default | What it controls |
|---------|---------|---------|-----------------|
| `mode` | `yolo`, `interactive` | `yolo` | `yolo` auto-approves steps; `interactive` confirms at each decision |
| `granularity` | `coarse`, `standard`, `fine` | `standard` | Phase size: 3-5 / 5-8 / 8-12 phases |
| `model_profile` | `quality`, `balanced`, `budget` | `balanced` | Agent model tier (see table below) |
| `learning_mode` | `auto`, `manual` | `auto` | `auto` offers learning at checkpoints; `manual` requires explicit invocation |

### Workflow Toggles

| Setting | Default | What it controls |
|---------|---------|-----------------|
| `workflow.research` | `true` | Domain research before planning each phase |
| `workflow.plan_check` | `true` | Plan verification loop (up to 3 iterations) |
| `workflow.verifier` | `true` | Post-execution verification against phase goals |
| `workflow.nyquist_validation` | `true` | Test coverage mapping during plan-phase |

### Git Branching

| `branching_strategy` | Creates branch | Best for |
|---------------------|---------------|---------|
| `none` | Never | Solo dev, simple projects |
| `phase` | At each `execute-phase` | Code review per phase |
| `milestone` | At first `execute-phase` | Release branches, PR per version |

### Model Profiles

| Agent | `quality` | `balanced` | `budget` |
|-------|-----------|------------|----------|
| Planner | large | large | medium |
| Executor | large | medium | medium |
| Phase Researcher | large | medium | small |
| Project Researcher | large | medium | small |
| Verifier | medium | medium | small |
| Plan Checker | medium | medium | small |
| Debugger | large | medium | medium |
| Codebase Mapper | medium | small | small |

> **Platform note:** `large` = Claude Opus / Gemini 2.5 Pro / GPT-4o, `medium` = Claude Sonnet / Gemini 2.0 Flash, `small` = Claude Haiku / Gemini Flash Lite. Exact model used depends on your platform.

### Speed vs. Quality Presets

| Scenario | `mode` | `granularity` | `model_profile` | Research | Plan Check | Verifier |
|----------|--------|--------------|----------------|----------|------------|---------|
| Prototyping | `yolo` | `coarse` | `budget` | off | off | off |
| Normal dev | `yolo` | `standard` | `balanced` | on | on | on |
| Production | `interactive` | `fine` | `quality` | on | on | on |

---

## 🧩 Learning Partner

The learning partner is woven into the platform, not bolted on. It fires at natural workflow transitions to build genuine understanding — not just fluent answers.

### How it fires

```
learning_mode: "auto"    → offered automatically at checkpoints (default)
learning_mode: "manual"  → only when you explicitly invoke @agentic-learning
```

### All 11 actions

| Action | Trigger | What it does |
|--------|---------|-------------|
| `@agentic-learning learn [topic]` | Any time | Active retrieval — explain before seeing, then fill gaps |
| `@agentic-learning quiz [topic]` | Any time | 3-5 questions, one at a time, formative feedback |
| `@agentic-learning reflect` | After `execute-phase` | Three-question structured reflection: learned / goal / gaps |
| `@agentic-learning space` | After `verify-work` | Schedule concepts for spaced review → writes `docs/revisit.md` |
| `@agentic-learning brainstorm [topic]` | After `new-project` | Collaborative design dialogue before any code |
| `@agentic-learning struggle [topic]` | During `quick` | Hint ladder — try first, reveal only when needed |
| `@agentic-learning either-or` | After `discuss-phase` | Decision journal — paths considered, choice, rationale |
| `@agentic-learning explain-first` | Any time | Oracy exercise — you explain, agent gives structured feedback |
| `@agentic-learning explain [topic]` | Any time | Project comprehension log → writes `docs/project-knowledge.md` |
| `@agentic-learning interleave` | Any time | Mixed retrieval across multiple topics |
| `@agentic-learning cognitive-load [topic]` | After `plan-phase` | Decompose overwhelming scope into working-memory steps |

**Core principle:** Fluent answers from an AI are not the same as learning. Every action makes you do the cognitive work — with support, not shortcuts.

### Skills across platforms

| Platform | How `agentic-learning` works |
|----------|-----------------------------|
| **Windsurf** | Native skill — invoke with `@agentic-learning learn`, `@agentic-learning quiz`, etc. |
| **Claude Code, OpenCode, Gemini CLI, Codex CLI** | Installed as a context file in `learnship/skills/agentic-learning/`. The AI reads and applies the techniques automatically — reference it explicitly with `use the agentic-learning skill` or just work normally and it activates at checkpoints. |

---

## 🎨 Design System

The **impeccable** skill suite is always active as project context for any UI work. It provides design direction, anti-patterns, and 17 steering commands that prevent generic AI aesthetics. Based on [@pbakaus/impeccable](https://github.com/pbakaus/impeccable).

### Commands

| Command | What it does |
|---------|-------------|
| `/teach-impeccable` | One-time setup — gathers project design context and saves persistent guidelines |
| `/audit` | Comprehensive audit: accessibility, performance, theming, responsive design |
| `/critique` | UX critique: visual hierarchy, information architecture, emotional resonance |
| `/polish` | Final quality pass — alignment, spacing, consistency before shipping |
| `/normalize` | Normalize design to match your design system for consistency |
| `/colorize` | Add strategic color to monochromatic or flat interfaces |
| `/animate` | Add purposeful animations and micro-interactions |
| `/bolder` | Amplify safe or boring designs — more visual impact |
| `/quieter` | Tone down overly aggressive designs — reduce intensity, gain refinement |
| `/distill` | Strip to essence — remove complexity, clarify what matters |
| `/clarify` | Improve UX copy, error messages, microcopy, labels |
| `/optimize` | Performance: loading speed, rendering, animations, bundle size |
| `/harden` | Resilience: error handling, i18n, text overflow, edge cases |
| `/delight` | Add moments of joy and personality that make interfaces memorable |
| `/extract` | Extract reusable components and design tokens into your design system |
| `/adapt` | Adapt designs across screen sizes, devices, and contexts |
| `/onboard` | Design onboarding flows, empty states, first-time user experiences |

**The AI Slop Test:** If you showed the interface to someone and said "AI made this" — would they believe you immediately? If yes, that's the problem. Use `/critique` to find out.

### Skills across platforms

| Platform | How `impeccable` works |
|----------|-----------------------|
| **Windsurf** | Native skills — invoke each command directly: `/audit`, `/polish`, `/critique`, etc. |
| **Claude Code, OpenCode, Gemini CLI, Codex CLI** | Installed as context files in `learnship/skills/impeccable/`. The AI reads the design principles and anti-patterns automatically. Reference commands explicitly: `run the /audit impeccable skill` or just ask for UI work and it applies the standards. |

---

## 💡 Usage Examples

### New greenfield project

```
/new-project              # Answer questions, configure, approve roadmap
/discuss-phase 1          # Lock in your implementation preferences
/plan-phase 1             # Research + plan + verify
/execute-phase 1          # Wave-ordered execution
/verify-work 1            # Manual UAT
                          # Repeat for each phase
/audit-milestone          # Check everything shipped
/complete-milestone       # Archive, tag, done
```

### Existing codebase (brownfield)

```
/map-codebase             # Structured codebase analysis
/new-project              # Questions focus on what you're ADDING
# Normal phase workflow from here
```

### Quick bug fix

```
/quick "Fix login button not responding on mobile Safari"
```

### Quick with discussion + verification

```
/quick --discuss --full "Add dark mode toggle"
```

### Resuming after a break

```
/ls                       # See where you left off — offers to run next step
# or
/next                     # Just pick up and go — auto-pilot
# or
/resume-work              # Full context restoration
```

### Scope change mid-milestone

```
/add-phase                # Append new phase to roadmap
/insert-phase 3           # Insert urgent work between phases 3 and 4
/remove-phase 7           # Descope phase 7 and renumber
```

### Preparing for release

```
/audit-milestone          # Check requirement coverage, detect stubs
/plan-milestone-gaps      # If audit found gaps, create phases to close them
/complete-milestone       # Archive, tag, done
```

### Debugging something broken

```
/debug "Login flow fails after password reset"
```

---

## 🧭 Decision Intelligence

Every project accumulates decisions — architecture choices, library picks, scope trade-offs. The platform tracks them in a structured register so future sessions understand *why* the project is built the way it is.

**`.planning/DECISIONS.md`** — the decision register:
```markdown
## DEC-001: Use Zustand over Redux
Date: 2026-03-01 | Phase: 2 | Type: library
Context: Needed client-side state for dashboard filters
Options: Zustand (simple, no boilerplate), Redux (complex, overkill for scope)
Choice: Zustand
Rationale: 3x less boilerplate, sufficient for current data flow complexity
Consequences: Locks React as UI framework; migration would require state rewrite
Status: active
```

**Populated automatically by:**
- `discuss-phase` — surfaces prior decisions before each phase discussion
- `plan-phase` — planner reads decisions before creating plans (never contradicts active ones)
- `debug` — architectural lessons from bugs go into the register
- `decision-log` — manual capture of any decision from any conversation

**Queried by:**
- `audit-milestone` — checks decisions were honored in implementation
- `knowledge-base` — aggregates all decisions into a searchable `KNOWLEDGE.md`

---

## 📁 Planning Artifacts

Every project creates a structured `.planning/` directory:

```
.planning/
├── config.json               # Workflow settings
├── PROJECT.md                # Vision, requirements, key decisions
├── REQUIREMENTS.md           # v1 requirements with REQ-IDs
├── ROADMAP.md                # Phase breakdown with status tracking
├── STATE.md                  # Current position, decisions, blockers
├── DECISIONS.md              # Cross-phase decision register
├── KNOWLEDGE.md              # Aggregated lessons (from knowledge-base)
├── research/                 # Domain research from new-project
│   ├── STACK.md
│   ├── FEATURES.md
│   ├── ARCHITECTURE.md
│   ├── PITFALLS.md
│   └── SUMMARY.md
├── codebase/                 # Brownfield mapping (from map-codebase)
│   ├── STACK.md
│   ├── ARCHITECTURE.md
│   ├── CONVENTIONS.md
│   └── CONCERNS.md
├── todos/
│   ├── pending/              # Captured ideas awaiting work
│   └── done/                 # Completed todos
├── debug/                    # Active debug sessions
│   └── resolved/             # Archived debug sessions
├── quick/
│   └── 001-slug/             # Quick task artifacts
│       ├── 001-PLAN.md
│       ├── 001-SUMMARY.md
│       └── 001-VERIFICATION.md (if --full)
└── phases/
    └── 01-phase-name/
        ├── 01-CONTEXT.md     # Your implementation preferences
        ├── 01-DISCOVERY.md   # Unfamiliar area mapping (from discovery-phase)
        ├── 01-RESEARCH.md    # Ecosystem research findings
        ├── 01-VALIDATION.md  # Test coverage contract (Nyquist)
        ├── 01-01-PLAN.md     # Executable plan (wave 1)
        ├── 01-02-PLAN.md     # Executable plan (wave 1, independent)
        ├── 01-01-SUMMARY.md  # Execution outcomes
        ├── 01-UAT.md         # User acceptance test results
        └── 01-VERIFICATION.md # Post-execution verification
```

---

## 🔧 Troubleshooting

### "Project already initialized"
`/new-project` found `.planning/PROJECT.md` already exists. If you want to start over, delete `.planning/` first. To continue, use `/progress` or `/resume-work`.

### Context degradation during long sessions
Start each major workflow with a fresh context. The platform is designed around fresh context windows — every agent gets a clean slate. Use `/resume-work` or `/progress` to restore state after clearing.

### Plans seem wrong or misaligned
Run `/discuss-phase [N]` before planning. Most plan quality issues come from unresolved gray areas. Run `/list-phase-assumptions [N]` to see the intended approach before committing to a plan.

### Execution produces stubs or incomplete code
Plans with more than 3 tasks are too large for reliable single-context execution. Re-plan with smaller scope: `/plan-phase [N]` with finer granularity.

### Lost track of where you are
Run `/ls`. It reads all state files, shows your progress, and offers to run the next step.

### Need to change something after execution
Use `/quick` for targeted fixes, or `/verify-work` to systematically identify and fix issues through UAT. Do not re-run `/execute-phase` on a phase that already has summaries.

### Costs running too high
Switch to budget profile via `/settings`. Disable research and plan-check for familiar domains. Use `granularity: "coarse"` for fewer, broader phases.

### Working on a private/sensitive project
Set `commit_docs: false` during `/new-project` or via `/settings`. Add `.planning/` to `.gitignore`. Planning artifacts stay local.

### Something broke and I don't know why
Run `/debug "description of what's broken"`. It runs triage → root cause diagnosis → fix planning with a persistent debug session.

### Phase passed UAT but has known gaps
Run `/audit-milestone` to surface all gaps, then `/plan-milestone-gaps` to create fix phases before release.

---

## 🚑 Recovery Quick Reference

| Problem | Solution |
|---------|----------|
| Lost context / new session | `/ls` or `/next` |
| Phase went wrong | `git revert` the phase commits, re-plan |
| Need to change scope | `/add-phase`, `/insert-phase`, or `/remove-phase` |
| Milestone audit found gaps | `/plan-milestone-gaps` |
| Something broke | `/debug "description"` |
| Quick targeted fix | `/quick` |
| Plans don't match your vision | `/discuss-phase [N]` then re-plan |
| Costs running high | `/settings` → budget profile, toggle agents off |

---

## 📂 Repository Structure

```
learnship/
├── .windsurf/
│   ├── workflows/          # 42 workflows as Windsurf slash commands
│   └── skills/
│       ├── agentic-learning/   # Learning partner (SKILL.md + references) — native on Windsurf
│       └── impeccable/         # Design suite: 17 skills — native on Windsurf
│           ├── frontend-design/ #   Base skill + 7 reference files (typography, color, motion…)
│           ├── audit/           #   /audit
│           ├── critique/        #   /critique
│           ├── polish/          #   /polish
│           └── …14 more/        #   /colorize /animate /bolder /quieter /distill /clarify…
│                               # → on non-Windsurf: both skills copied to learnship/skills/ as context files
├── commands/               # 42 Claude Code-style slash command wrappers
│   └── learnship/          # /learnship:ls, /learnship:new-project, etc.
├── learnship/              # Payload — installed into the target platform config dir
│   ├── workflows/          # 42 workflow markdown files (the actual instructions)
│   ├── references/         # Reference docs (questioning, verification, git, design, learning)
│   └── templates/          # Document templates for .planning/ + AGENTS.md template
├── agents/                 # 6 agent personas (planner, researcher, executor, verifier, debugger, plan-checker)
├── assets/                 # Brand images (banner, explainers, diagrams)
├── bin/
│   └── install.js          # Multi-platform installer (Claude Code, OpenCode, Gemini CLI, Codex CLI, Windsurf)
├── tests/
│   └── validate_multiplatform.sh  # 94-check test suite
├── SKILL.md                # Meta-skill: platform context loaded by Cascade / AI agents
├── install.sh              # Shell installer wrapper
├── package.json            # npm package (npx learnship)
├── CHANGELOG.md            # Version history
└── CONTRIBUTING.md         # How to extend the platform
```

---

## 🙏 Inspiration & Credits

**learnship** was built on top of ideas and work from three open-source projects:

- **[get-shit-done](https://github.com/davila7/get-shit-done)** — the spec-driven, context-engineered workflow system that inspired the phase lifecycle, planning artifacts, and agent coordination patterns
- **[agentic-learn](https://github.com/faviovazquez/agentic-learn)** — the learning partner skill whose neuroscience-backed techniques (retrieval, spacing, generation, reflection) power the Learning Partner layer
- **[impeccable](https://github.com/pbakaus/impeccable)** — the frontend design skill that raised the bar on UI quality standards and powers the Design System layer

learnship adapts, combines, and extends these into a unified, multi-platform system. All three are used as inspiration — learnship is original work built on their shoulders.

---

## License

MIT © [Favio Vazquez](https://github.com/FavioVazquez)
