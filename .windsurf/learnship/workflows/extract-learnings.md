---
description: Extract structured learnings from completed phase artifacts — decisions, lessons, patterns, surprises
---

# Extract Learnings

Extract decisions, lessons learned, patterns discovered, and surprises encountered from completed phase artifacts into a structured LEARNINGS.md file. Captures institutional knowledge that would otherwise be lost between phases.

**Usage:** `extract-learnings [N]` — extract from phase N

**Complements `/compound`:** compound captures reusable solutions, extract-learnings captures meta-knowledge (why things worked, what surprised you, what patterns emerged).

## Step 1: Initialize

Find the phase directory:
```bash
ls ".planning/phases/" | grep "^[0-9]" | sort
```

Find the phase matching `[N]`. If not found, stop and list available phases.

Verify required artifacts exist:
```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-PLAN.md 2>/dev/null
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-SUMMARY.md 2>/dev/null
```

If PLAN.md or SUMMARY.md files are missing: "Required artifacts missing. PLAN.md and SUMMARY.md are required for learning extraction."

## Step 2: Collect Artifacts

**Required (must exist):**
- All `*-PLAN.md` files for the phase
- All `*-SUMMARY.md` files for the phase

**Optional (read if available, skip if not):**
- `*-VERIFICATION.md` — verification results
- `*-UAT.md` — user acceptance test results
- `*-SECURITY.md` — security verification
- `.planning/STATE.md` — project state with decisions and blockers

Track which optional artifacts are missing for the frontmatter.

## Step 3: Extract Learnings

Analyze all collected artifacts and extract learnings into 4 categories:

### 1. Decisions
Technical and architectural decisions made during the phase:
- Explicit decisions documented in PLAN.md or SUMMARY.md
- Technology choices and their rationale
- Trade-offs that were evaluated

Each entry: **What** was decided, **Why** (rationale), **Source** (which artifact).

### 2. Lessons
What worked well and what didn't:
- Approaches that succeeded or failed
- Time estimates vs actual (if observable from git timestamps)
- Unexpected complexity or simplicity

Each entry: **What happened**, **Why it matters**, **Source**.

### 3. Patterns
Reusable patterns that emerged:
- Code patterns used across multiple tasks
- Process patterns that worked well
- Integration patterns between components

Each entry: **Pattern name**, **When to use**, **Source**.

### 4. Surprises
Things that didn't go as expected:
- Unexpected bugs or behaviors
- Assumptions that were wrong
- External factors that affected the work

Each entry: **What was surprising**, **Impact**, **Source**.

## Step 4: Write LEARNINGS.md

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-LEARNINGS.md`:

```markdown
---
phase: [N]
phase_name: [name]
extracted: [date]
plan_count: [N]
summary_count: [N]
missing_artifacts: [list or "none"]
---

# Phase [N]: [Name] — Learnings

## Decisions

### D1: [Decision title]
**What:** [what was decided]
**Why:** [rationale]
**Source:** [artifact file]

## Lessons

### L1: [Lesson title]
**What happened:** [description]
**Why it matters:** [impact on future work]
**Source:** [artifact file]

## Patterns

### P1: [Pattern name]
**When to use:** [conditions]
**Source:** [artifact file]

## Surprises

### S1: [Surprise title]
**What was surprising:** [description]
**Impact:** [how it affected the work]
**Source:** [artifact file]

---

*Extracted from Phase [N] artifacts on [date]*
```

## Step 5: Commit and Report

```bash
git add ".planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-LEARNINGS.md"
git commit -m "docs([padded_phase]): extract phase learnings"
```

```
learnship > LEARNINGS EXTRACTED

Phase [N]: [Name]
Decisions: [N]  |  Lessons: [N]  |  Patterns: [N]  |  Surprises: [N]

Report: [path to LEARNINGS.md]

These learnings feed into future planning — the planner will reference them
when working on related phases.
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:**

> **Learning moment:** You just extracted meta-knowledge from a phase. Make it stick:
>
> `@agentic-learning space` — Schedule the key patterns and lessons for spaced review. The extraction just identified WHAT you learned — spacing ensures you RETAIN it.
>
> `@agentic-learning interleave [phase topic]` — Mix these learnings with concepts from earlier phases to strengthen cross-cutting understanding.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning space` to schedule these learnings for spaced review."*
