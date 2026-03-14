---
title: Debugging
description: Reference for debugging and brownfield workflows — debug, diagnose-issues, map-codebase, discovery-phase.
---

# Debugging

These workflows handle systematic debugging, brownfield analysis, and targeted code fixes.

---

## `/debug "[description]"`

Systematic root-cause debugging: triage → diagnose → fix → verify.

```bash
/debug "Login flow fails after password reset"
/debug "Search returns 500 when query contains special characters"
```

**What it does:**
1. **Triage** — reproduces the issue, narrows the search space
2. **Diagnose** — root cause analysis (hypothesis testing, bisect, tracing)
3. **Plan fix** — creates a targeted fix plan, no unnecessary changes
4. **Execute** — implements the fix with atomic commits
5. **Verify** — confirms the bug is gone and no regressions introduced

Maintains a persistent debug session in `.planning/debug/` so context isn't lost across steps.

**Learning checkpoint:** `learn [bug domain]` · `struggle [the problem]` · `either-or` — bugs are the highest-signal learning moments. Don't just fix and move on.

---

## `/diagnose-issues [N]`

Batch-diagnoses multiple UAT issues after `/verify-work` finds several problems.

**When to use:** After `/verify-work N` finds 3+ issues — groups them by root cause, identifies shared underlying problems, and proposes a consolidated fix plan. More efficient than running `/debug` on each issue separately.

**Output:** A structured diagnosis grouping issues by root cause, with a prioritized fix plan.

---

## `/map-codebase`

Structured analysis of an existing codebase before starting work on it.

**When to use:** Before `/new-project` when you're adding features to existing code (brownfield). Gives the agent a grounded understanding of the architecture before it makes any plans.

**What it produces:** `.planning/codebase/` with:
- `STACK.md` — tech stack and dependencies
- `ARCHITECTURE.md` — structural patterns and key relationships
- `CONVENTIONS.md` — naming, style, patterns in use
- `CONCERNS.md` — identified risks, technical debt, areas to avoid

---

## `/execute-plan [N] [plan-id]`

Runs a single plan in isolation — useful for re-running a failed plan without re-executing the whole phase.

```bash
/execute-plan 2 01    # re-run plan 01 of phase 2
/execute-plan 3 02    # run plan 02 of phase 3
```

**When to use:**
- A specific plan failed during `/execute-phase` and needs to be re-run after a fix
- You want to test a single plan before running the full phase

---

## `/add-todo "[description]"`

Captures an idea or task mid-session without breaking your current flow.

```bash
/add-todo "Add rate limiting to the auth endpoint"
/add-todo "Consider migrating from REST to GraphQL in phase 5"
```

Saves to `.planning/todos/pending/`. Review and act with `/check-todos`.

---

## `/check-todos`

Reviews all captured todos and lets you decide what to do with each:
- Convert to a quick task → `/quick`
- Convert to a new phase → `/add-phase`
- Add to the decision register → `/decision-log`
- Dismiss as resolved or out of scope

---

## `/add-tests`

Generates test coverage for a specific plan or phase post-execution.

**When to use:** After executing a phase that didn't have test coverage in the plans, or when retroactively adding tests to existing code.

---

## `/validate-phase [N]`

Retroactive test coverage audit for a completed phase.

**When to use:** After hotfixes or legacy phases where test coverage is uncertain. Checks what's tested vs. what should be, and creates a coverage gap report.

---

## Debugging patterns

```bash
# Single bug
/debug "Description of what's broken"

# Multiple bugs from UAT
/verify-work N
/diagnose-issues N          # group and plan fixes for all issues

# Brownfield setup
/map-codebase               # understand the existing code first
/new-project                # then initialize (questions focus on what you're adding)

# Re-run a failed plan
/execute-plan [N] [id]      # without re-running the whole phase
```
