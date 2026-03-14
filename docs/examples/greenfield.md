---
title: Greenfield Project
description: End-to-end walkthrough of building a new project with learnship from scratch.
---

# Greenfield Project

A complete walkthrough of building a task manager API from scratch with learnship. Every command, every transition.

---

## Session 1 — Initialize

```
/new-project
```

**Questions asked:**

```
What are you building?
→ A REST API for a task manager with authentication and real-time updates

What problem does it solve?
→ Teams need a shared task registry synced in real time

Primary tech stack (or "help me decide")?
→ Node.js, PostgreSQL, WebSocket

Target environment?
→ Docker, AWS ECS
```

learnship researches the domain, then proposes:

```
Milestone: v1.0 — Task Manager API

Phase 1: Project foundation (auth, DB schema, migrations)
Phase 2: Core task endpoints (CRUD, filtering, pagination)
Phase 3: Real-time layer (WebSocket, event broadcasting)
Phase 4: Testing and hardening (integration tests, error handling)
```

Approve the roadmap → `AGENTS.md` + `.planning/` scaffolded, committed.

!!! tip "Learning moment"
    `@agentic-learning brainstorm authentication patterns` — talk through JWT vs sessions vs OAuth before Phase 1 planning locks anything in.

---

## Session 2 — Phase 1

```
/discuss-phase 1
```

Conversation covers: JWT vs sessions (chose JWT), Knex vs Prisma (chose Prisma), migration strategy (code-first). Written to `01-CONTEXT.md`.

```
/plan-phase 1
```

Planner creates three plans:
- `01-01-PLAN.md` — database schema + Prisma setup
- `01-02-PLAN.md` — JWT authentication middleware
- `01-03-PLAN.md` — user registration and login endpoints

!!! tip "Before executing"
    `@agentic-learning explain-first auth flow` — if you can explain the JWT flow before seeing code, the execution will go smoother.

```
/execute-phase 1
```

9 atomic commits. Each task is a self-contained unit of work. Output:

```
✓ 01-01: Database schema + Prisma client configured
✓ 01-02: JWT middleware with refresh token rotation
✓ 01-03: POST /auth/register, POST /auth/login, POST /auth/refresh
```

```
/verify-work 1
```

You test:
- `POST /auth/register` with valid payload → 201 ✓
- `POST /auth/login` with wrong password → 401 ✓
- `POST /auth/register` with duplicate email → **500** ✗

Report: `"Registration returns 500 on duplicate email instead of 409"`

Agent diagnoses: missing unique constraint error handler in the Prisma adapter. Creates a targeted fix plan. Execute + re-verify → clean.

```
✓ Phase 1 complete
```

---

## Sessions 3–5 — Phases 2 and 3

Same pattern repeats. By the end of Phase 3:

```
.planning/phases/
├── 01-foundation/     ✓ 3 plans, 3 summaries, UAT passed
├── 02-core-tasks/     ✓ 4 plans, 4 summaries, UAT passed
└── 03-realtime/       ✓ 3 plans, 3 summaries, UAT passed
```

`DECISIONS.md` has 8 entries. `AGENTS.md` reflects Phase 4 as current. The AI agent starts every session knowing exactly where the project is.

---

## Session 6 — Phase 4 + Release

```
/discuss-phase 4
/plan-phase 4
/execute-phase 4
/verify-work 4
```

All pass clean.

```
/audit-milestone
```

Output: `REQ-001 through REQ-014: all covered. No stubs detected. ✓`

```
/complete-milestone
```

Archives phases, creates tag `v1.0.0`, advances project state.

```
/milestone-retrospective
```

5-question retrospective. Key lesson logged: "Prisma error handling needs explicit middleware — don't rely on default error propagation."

```
@agentic-learning space
```

Schedules: Prisma error handling, JWT refresh pattern, WebSocket broadcast architecture for spaced review over the next 2 weeks.

---

## What you built

- A production-grade REST API with auth, CRUD, real-time updates
- 19 atomic commits across 4 phases
- Full decision register in `DECISIONS.md`
- Test coverage mapping in `VALIDATION.md` per phase
- A milestone retrospective with scheduled learning reviews
- **And you understand every decision made along the way**

---

## Key patterns to carry forward

- Always `/discuss-phase` before `/plan-phase` — the context file is the planner's primary input
- `/verify-work` is you doing real testing, not the agent running scripts
- Bugs found during UAT are learning moments — use `@agentic-learning learn [domain]`
- `/audit-milestone` before releasing — it catches what manual testing misses
