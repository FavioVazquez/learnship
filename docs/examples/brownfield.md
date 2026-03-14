---
title: Brownfield Project
description: Adding features to an existing codebase with learnship — map-codebase first, then the normal phase loop.
---

# Brownfield Project

Adding learnship to an existing codebase takes one extra step: `/map-codebase` before `/new-project`. This gives the agent a grounded understanding of what already exists so it doesn't contradict the architecture.

---

## The pattern

```bash
/map-codebase             # understand the existing code
/new-project              # questions focus on what you're ADDING
# normal phase loop from here
```

---

## Step 1 — Map the codebase

```
/map-codebase
```

The agent analyzes your existing codebase and produces `.planning/codebase/`:

```
.planning/codebase/
├── STACK.md         # tech stack, frameworks, key dependencies
├── ARCHITECTURE.md  # structural patterns, module relationships
├── CONVENTIONS.md   # naming, file organization, coding style in use
└── CONCERNS.md      # identified tech debt, risks, areas to avoid
```

**Example `CONCERNS.md` output:**

```markdown
## CONCERNS

1. Auth module — mixed synchronous and async patterns, no consistent error handling
2. Database layer — raw SQL mixed with Knex queries in the same files
3. No test coverage for the payment module (0%)
4. `utils/helpers.js` is a 1200-line catch-all — high coupling risk
```

This file is read by every subsequent planner — it shapes which areas get touched and which are avoided.

!!! tip
    Be honest in your `/map-codebase` session. The agent will find the concerns anyway — better to surface them explicitly than have the planner stumble into them mid-execution.

---

## Step 2 — Initialize the project

```
/new-project
```

With `CODEBASE/` artifacts present, the questions shift:

```
What are you ADDING to this codebase?
→ A notification system — email + in-app — triggered by task events

What should this milestone NOT change?
→ Auth system (active users), payment module (undergoing audit), public API shape

What existing patterns should the new code follow?
→ Async/await throughout, Knex for DB queries, Jest for testing
```

The roadmap is scoped to the new feature only — it won't touch the auth system or payment module because those are explicitly off-limits.

---

## Step 3 — Normal phase loop

From here the workflow is identical to greenfield:

```
/discuss-phase 1        # align on notification architecture decisions
/plan-phase 1           # research + create plans that fit the existing stack
/execute-phase 1        # build following existing conventions
/verify-work 1          # UAT against acceptance criteria
```

The planner reads `CONVENTIONS.md` and follows them. It reads `CONCERNS.md` and avoids the flagged areas. Nothing is guessed.

---

## Discovery when entering unfamiliar code

If a phase touches an area you haven't worked in before:

```
/discovery-phase N
```

Produces `N-DISCOVERY.md` — a focused map of the specific code area the phase will touch. More targeted than `/map-codebase` (which is the whole codebase).

```
/list-phase-assumptions N
```

Shows what the agent intends to do before creating any plans. Redirect early if the approach looks wrong.

---

## Key differences from greenfield

| | Greenfield | Brownfield |
|---|---|---|
| First step | `/new-project` | `/map-codebase` → `/new-project` |
| Questions focus | What are you building? | What are you ADDING? What's off-limits? |
| Planner context | Domain research only | Codebase map + domain research |
| Anti-goals | Optional | Essential — scope what must not change |
| Per-phase prep | `/discuss-phase` | `/discuss-phase` + optionally `/discovery-phase` |
