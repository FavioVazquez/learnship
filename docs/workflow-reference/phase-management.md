---
title: Phase Management
description: Reference for scope management workflows — add, insert, remove phases, research, and assumptions.
---

# Phase Management

These workflows handle scope changes and phase-level research after the initial roadmap is created.

---

## `/add-phase`

Appends a new phase to the end of the current roadmap.

**When to use:** Scope grows after planning — you realize a new capability needs to be built that wasn't in the original roadmap.

**What it does:** Asks what the new phase should accomplish, appends it to `ROADMAP.md` with the next available phase number, updates `STATE.md`.

---

## `/insert-phase [N]`

Inserts a new phase between existing phases N and N+1, renumbering subsequent phases.

**When to use:** Urgent work discovered mid-milestone that must happen before a planned phase. For example, a security issue discovered in Phase 3 that must be fixed before Phase 4.

```
/insert-phase 3    # inserts between phases 3 and 4; old phase 4 becomes 5
```

---

## `/remove-phase [N]`

Removes a planned (not yet executed) phase and renumbers subsequent ones.

**When to use:** Descoping a feature that's not needed for this milestone.

!!! warning "Only for future phases"
    `/remove-phase` only works on phases that haven't been executed yet. You can't remove a phase that has `SUMMARY.md` files — those represent committed work.

---

## `/research-phase [N]`

Deep-dive domain research for phase N without creating plans yet.

**When to use:** The phase covers an unfamiliar domain and you want to understand the landscape before committing to any implementation decisions.

**What it produces:** `.planning/phases/N-*/N-RESEARCH.md` — a comprehensive domain briefing that `/discuss-phase` and `/plan-phase` will read.

**Learning checkpoint:** `learn` · `explain-first` · `quiz` — lock in domain knowledge while it's fresh.

---

## `/discovery-phase [N]`

Maps an unfamiliar area of the **existing codebase** before planning work in that area.

**When to use:** Phase N touches code you didn't write or haven't worked in recently. Prevents plans that contradict existing architecture.

**What it produces:** `.planning/phases/N-*/N-DISCOVERY.md` — a codebase area map with entry points, patterns, and concerns.

---

## `/list-phase-assumptions [N]`

Surfaces the agent's intended approach for phase N before planning starts.

**When to use:** After `/discuss-phase` but before `/plan-phase` — lets you validate the direction before plans are created. Much cheaper to correct a misalignment here than after planning.

```
/list-phase-assumptions 2
→ Agent shows: intended architecture, library choices, patterns, scope boundaries
→ You confirm or redirect before planning begins
```

---

## `/plan-milestone-gaps`

Creates fix phases for all gaps found by `/audit-milestone`.

**When to use:** After `/audit-milestone` reports uncovered requirements or quality gaps. Creates targeted fix phases rather than re-running full phases.

---

## Common scope change patterns

```bash
# Realized you need more work
/add-phase                   # appends to roadmap

# Urgent fix needed now
/insert-phase N              # inserts before planned phase N+1

# Feature not needed this cycle
/remove-phase N              # descopes and renumbers

# Pre-release gaps found
/audit-milestone
/plan-milestone-gaps         # creates fix phases for each gap
/execute-phase N             # execute the gap fix phases
```
