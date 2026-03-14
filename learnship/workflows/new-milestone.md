---
description: Start a new milestone cycle on an existing project after a prior milestone is complete
---

# New Milestone

Start the next version cycle for an existing project. Loads what shipped previously, gathers new goals, optionally researches new feature domains, defines scoped requirements, and creates a new phased roadmap.

**Use after:** `/complete-milestone` has archived the previous milestone.

## Step 1: Load Context

Read all prior project context:
```bash
cat .planning/PROJECT.md
cat .planning/STATE.md
cat .planning/milestones/
ls .planning/milestones/ 2>/dev/null
```

Display what shipped in the last milestone:
```
## Last milestone: [VERSION]
[2-3 sentences from the milestone archive summarizing what was built]

Pending todos carried forward:
- [Any todos from STATE.md]
```

## Step 2: Gather Milestone Goals

Ask openly: **"What do you want to build in this milestone?"**

If a milestone scope was already discussed (look for `.planning/MILESTONE-CONTEXT.md`), load it and confirm:
```
I found a milestone context file from a prior discussion:
[summary of scope]

Use this as the starting point?
```
- **Yes** → proceed with it
- **No / Start fresh** → ask from scratch

Follow the thread. When you have enough to write clear goals, ask for confirmation before continuing.

## Step 3: Determine Version

Read the last version from `.planning/milestones/`:
```bash
ls .planning/milestones/ | grep -E "^v[0-9]" | sort -V | tail -3
```

Propose the next version (e.g., `v1.0 → v1.1`, or `v2.0` for a major scope change). Confirm with user or let them specify.

## Step 4: Update PROJECT.md

Add or update the current milestone section:
```markdown
## Current Milestone: [VERSION] [Name]

**Goal:** [One sentence describing this milestone's focus]

**Target features:**
- [Feature 1]
- [Feature 2]
```

Update the Active requirements section and "Last updated" footer.

## Step 5: Update STATE.md

Reset current position:
```markdown
## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: [today] — Milestone [VERSION] started
```

Keep the Accumulated Context section (decisions, blockers from prior milestones carry forward).

## Step 6: Commit Initial State

```bash
git add .planning/PROJECT.md .planning/STATE.md
git commit -m "docs: start milestone [VERSION] [Name]"
```

If a MILESTONE-CONTEXT.md was consumed, delete it:
```bash
git rm .planning/MILESTONE-CONTEXT.md 2>/dev/null || true
```

## Step 7: Research Decision

Read `workflow.research` from `.planning/config.json`.

Ask: "Research the domain for the new features before defining requirements?"
- **Research first** (recommended) — investigate new capabilities' ecosystem
- **Skip research** — domain is familiar

Update config accordingly:
```bash
# Edit .planning/config.json: set workflow.research to true or false
```

**If Research first:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING NEW MILESTONE FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Using `@./agents/researcher.md` in project research mode, investigate the new feature domain:
- Focus ONLY on the new capabilities — not the existing codebase
- Write STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md to `.planning/research/`
- Synthesize into `.planning/research/SUMMARY.md`

## Step 8: Define Requirements

Read PROJECT.md, existing REQUIREMENTS traceability (in milestones archive), and research (if run).

Present feature categories for this milestone. For each, have the user select what's in scope (multi-select). Apply REQ-IDs continuing from the last milestone's numbering (or restarting per-domain).

Create `.planning/REQUIREMENTS.md` fresh for this milestone:
- v1 requirements with REQ-IDs
- v2 requirements (next milestone candidates)
- Out-of-scope items with reasoning

Present for confirmation. Iterate if needed.

```bash
git add .planning/REQUIREMENTS.md
git commit -m "docs: define [VERSION] requirements"
```

## Step 9: Create Roadmap

Using `@./agents/planner.md` as planning persona, read PROJECT.md, REQUIREMENTS.md, research (if exists).

Create a new `.planning/ROADMAP.md` with phases for this milestone only. Map every v1 requirement to exactly one phase.

Present the proposed roadmap for approval. Iterate if needed.

Update STATE.md to reflect the new phase count and first phase.

```bash
git add .planning/ROADMAP.md .planning/STATE.md
git commit -m "docs: create [VERSION] roadmap ([N] phases)"
```

## Step 10: Update AGENTS.md

If `AGENTS.md` exists at the project root, update:

1. **Current Phase block** — reset for new milestone:
```markdown
## Current Phase

**Milestone:** [VERSION] — [Milestone Name]
**Phase:** 1 — [Phase 1 Name from new ROADMAP.md]
**Status:** planning
**Last updated:** [today's date]
```

2. **Tech Stack** — update if the new milestone introduces new libraries or frameworks.

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md — milestone [VERSION] started"
```

## Step 11: Done

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► MILESTONE [VERSION] INITIALIZED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**[VERSION] — [Name]** — [N] phases, [X] requirements

▶ Next: discuss-phase 1 → plan-phase 1 → execute-phase 1
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** New milestone, new mental model. Before writing a line of code:
>
> `@agentic-learning brainstorm [milestone topic]` — Talk through the new features before committing to an approach. Surfaces blind spots before planning starts.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning brainstorm [milestone topic]` before planning starts to surface approach alternatives."*
