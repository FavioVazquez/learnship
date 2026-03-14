---
title: Milestone Workflows
description: Reference for milestone lifecycle workflows — new-milestone, audit, complete, and retrospective.
---

# Milestone Workflows

These workflows manage the full milestone lifecycle — from planning a new version to archiving it and learning from it.

![Milestone lifecycle](../assets/milestone-lifecycle.png)

---

## `/discuss-milestone "[version]"`

Captures goals, anti-goals, and constraints before committing to a roadmap.

**Run before `/new-milestone`.** The 10-minute discussion produces `MILESTONE-CONTEXT.md` which `/new-milestone` reads automatically — no re-asking.

See [Decision Intelligence → /discuss-milestone](decision-intelligence.md) for full details.

---

## `/new-milestone "[name]"`

Starts a new milestone version cycle with a fresh roadmap.

**What it does:**
1. Reads the previous milestone's summary and `MILESTONE-CONTEXT.md` (if present)
2. Asks about goals for the new milestone (or uses context from `/discuss-milestone`)
3. Proposes a phase-by-phase roadmap for your approval
4. Initializes `STATE.md` for the new cycle

**When to use:** After `/complete-milestone`. Run `/discuss-milestone` first for best results.

**Learning checkpoint:** `brainstorm [milestone topic]`

---

## `/audit-milestone`

Pre-release quality gate — checks everything before you tag a release.

**What it checks:**
- Every REQ-ID from `REQUIREMENTS.md` maps to implementation
- No stubs, placeholders, or `TODO` markers in production code
- Integration between phases is coherent
- Key decisions were honored in implementation

**Output:** A prioritized gap report. If gaps exist, use `/plan-milestone-gaps` to create fix phases.

**When to use:** Before `/complete-milestone`. Don't skip this — it's the difference between "shipped" and "shipped correctly".

---

## `/complete-milestone`

Archives the milestone, tags the release, and advances the project.

**What it does:**
1. Runs a final health check
2. Archives all phase artifacts to `.planning/milestones/[version]/`
3. Writes a milestone summary document
4. Creates a git tag for the version
5. Advances `AGENTS.md` and `STATE.md` to the next cycle

**When to use:** After all phases are verified and `/audit-milestone` passes clean.

---

## `/milestone-retrospective`

Structured 5-question retrospective after completing a milestone.

**The 5 questions:**
1. What did we set out to build, and did we build it?
2. What went well that we should repeat?
3. What was harder than expected, and why?
4. What decisions would we make differently?
5. What do we want to learn or improve before the next milestone?

**Output:** A `RETROSPECTIVE.md` in `.planning/milestones/[version]/`.

**Learning checkpoint:** `space` — schedule key concepts and lessons for spaced review.

---

## `/health`

Project health check — surfaces stale files, uncommitted changes, missing artifacts, and config drift.

```
/health
```

Use this any time you feel the project state might be inconsistent — after a long break, after a manual edit to planning files, or after a git conflict.

---

## Full milestone pattern

```bash
# Start of a milestone
/discuss-milestone v2.0      # capture goals + anti-goals
/new-milestone v2.0          # create roadmap

# Phase loop (repeats)
/discuss-phase N
/plan-phase N
/execute-phase N
/verify-work N

# End of milestone
/audit-milestone             # verify completeness
/plan-milestone-gaps         # if audit found gaps
/complete-milestone          # archive + tag + advance
/milestone-retrospective     # learn and schedule review
```
