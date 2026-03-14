---
title: Quick Tasks
description: Using /quick for one-off fixes, experiments, and small features — patterns and flags.
---

# Quick Tasks

`/quick` is for self-contained work that doesn't warrant a full phase: bug fixes, small features, experiments, refactors. It gives you atomic commits and optional verification with no planning ceremony.

---

## Basic usage

```bash
/quick "Fix the login button not responding on mobile Safari"
/quick "Add input validation to the registration form"
/quick "Update the API rate limit from 100 to 500 req/min"
```

Each produces:
- A minimal plan stored in `.planning/quick/001-slug/001-PLAN.md`
- Atomic commits with a clear commit message
- A summary in `001-SUMMARY.md`

---

## Flags

### `--discuss` — brief decision conversation first

```bash
/quick --discuss "Add dark mode toggle to the settings page"
```

Before executing, the agent asks 2–3 clarifying questions:
- Where should the toggle live in the UI?
- Should dark mode persist across sessions (localStorage)?
- Which components need dark mode variants?

Use this when you have a clear goal but want to align on approach before any code is written.

### `--full` — full plan + execution + verification

```bash
/quick --full "Refactor the auth middleware to support OAuth"
```

Adds a full verification pass after execution — the agent checks that the refactor didn't break existing functionality and that the OAuth integration works end-to-end.

Use this for tasks that are small in scope but high in impact — where you want the same guarantees as a full phase without the overhead.

---

## When to use `/quick` vs the full phase loop

| Scenario | Use |
|----------|-----|
| Bug fix, < 1 hour of work | `/quick` |
| Small feature addition, well-understood domain | `/quick --discuss` |
| Significant refactor touching multiple areas | `/quick --full` |
| New feature requiring research and multiple changes | Full phase loop |
| Anything touching > 3 files in non-trivial ways | Full phase loop |

???+ tip "The rule of thumb"
    If you'd describe it as "a fix" or "a tweak", use `/quick`. If you'd describe it as "a feature" or "a system", use the phase loop.

---

## Combining quick tasks with the phase loop

Quick tasks run independently of the phase loop — they don't advance phase status. You can run a `/quick` in the middle of a phase for an urgent bug without disrupting your phase progress:

```bash
# Mid-phase urgent fix
/quick "Fix production crash in payment endpoint"

# Then continue the phase
/execute-phase 3   # picks up where it left off
```

---

## Learning after quick tasks

The learning checkpoint on `/quick` matches the action to what happened:

```
@agentic-learning struggle [task]    # if it was tricky — re-solve with a hint ladder
@agentic-learning learn [domain]     # if it touched an unfamiliar area
@agentic-learning either-or          # if you made a meaningful design choice
```

Even small tasks are opportunities. A bug you fixed in 20 minutes contains a pattern worth learning.

---

## Reviewing accumulated quick tasks

```
/check-todos
```

After many quick tasks, you may have patterns worth capturing as decisions or promoting to a formal phase. `/check-todos` helps you review all quick task summaries and todos and decide what to do with each.
