---
title: Your First Project
description: Walk through creating a new project with learnship from scratch — new-project through verify-work.
---

# Your First Project

This walkthrough takes you from zero to a verified, committed first phase. It uses a fictional "task manager API" as the example, but the steps are identical for any project.

## Step 1 — Start your AI agent and run `/ls`

```
/ls
```

Since no project exists yet, learnship will display a welcome message and offer to run `/new-project`. Accept it, or run it directly:

```
/new-project
```

## Step 2 — Answer the questions

`/new-project` asks a structured set of questions to understand what you're building. Be honest and direct — the more context you give, the better the agent's plans will be.

```
What are you building?
→ A REST API for a task manager with authentication and real-time updates

What problem does it solve?
→ Teams need a central task registry synced across devices in real time

What's your primary tech stack (or "help me decide")?
→ Node.js, PostgreSQL, WebSocket

What platforms or environments will this run on?
→ Docker containers, deployed to AWS ECS
```

After the questions, the agent:

1. **Researches the domain** — ecosystem, best practices, pitfalls, architectural options
2. **Writes project artifacts** — `AGENTS.md`, `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`
3. **Proposes a roadmap** — a list of phases with descriptions

Review the roadmap and approve it. If anything looks off, tell the agent to adjust before approving.

!!! tip "Learning moment"
    After `/new-project` completes, try `@agentic-learning brainstorm [your project topic]` to talk through the architecture before any code is written. Blind spots surfaced here don't become bugs later.

## Step 3 — Discuss Phase 1

```
/discuss-phase 1
```

This is a conversation, not a form. The agent reads `AGENTS.md` and your roadmap, then asks targeted questions about implementation preferences for this phase:

- What libraries do you prefer for the auth layer?
- Should database migrations be code-first or SQL-first?
- Any existing patterns to follow for error handling?

Your answers get written to `.planning/phases/01-*/01-CONTEXT.md` — a persistent file the planner reads before creating any plans.

## Step 4 — Plan Phase 1

```
/plan-phase 1
```

The planner:

1. Reads your `CONTEXT.md` and all prior decisions
2. Researches the specific technical domain for this phase
3. Creates 2-4 executable `PLAN.md` files, each scoped to one area
4. Runs a verification loop (up to 3 passes) to check plans are coherent

Each plan describes concrete tasks with enough detail that an executor agent can implement them without guessing.

!!! tip "Before you execute"
    `@agentic-learning explain-first [phase topic]` — explain the planned approach back in your own words before touching code. Gaps in the explanation are gaps in the plan.

## Step 5 — Execute Phase 1

```
/execute-phase 1
```

Plans run in wave order. Independent plans in the same wave run sequentially by default (or in parallel if `parallelization: true`). Each task gets an atomic commit.

Watch the output — the executor narrates what it's doing and surfaces questions if anything is ambiguous.

## Step 6 — Verify Phase 1

```
/verify-work 1
```

This is **you** doing manual user acceptance testing, with the agent as your diagnostic partner:

1. The agent shows you what was built and the acceptance criteria
2. You test it — run the app, try the endpoints, check the behavior
3. Report any issues: `"The /login endpoint returns 500 when email is missing"`
4. The agent diagnoses root causes and creates targeted fix plans
5. Execute the fixes, then re-verify

When everything passes:

```
✓ Phase 1 complete
```

## What you have now

```
.planning/
├── config.json
├── PROJECT.md              ← what you're building
├── REQUIREMENTS.md         ← REQ-001 … REQ-N
├── ROADMAP.md              ← phases with status
├── STATE.md                ← current position
└── phases/
    └── 01-foundation/
        ├── 01-CONTEXT.md   ← your preferences
        ├── 01-RESEARCH.md  ← domain research
        ├── 01-01-PLAN.md   ← executed
        ├── 01-01-SUMMARY.md
        └── 01-UAT.md       ← verified
AGENTS.md                   ← AI reads this every session
```

## Repeat for each phase

```
/discuss-phase 2
/plan-phase 2
/execute-phase 2
/verify-work 2
```

`/ls` at any time shows your current position and what to do next. When all phases are done:

```
/audit-milestone    # check coverage before releasing
/complete-milestone # archive, tag, done
```

See [Examples → Greenfield Project](../examples/greenfield.md) for a full end-to-end walkthrough with real output.
