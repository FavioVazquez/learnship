---
description: Research + create + verify plans for a phase — spawns specialist subagents where supported
---

# Plan Phase

Create executable plans for a roadmap phase. Default flow: Research → Plan → Verify → Done.

On platforms with subagent support (Claude Code, OpenCode, Codex), each stage spawns a dedicated specialist agent with its own full context budget. On all other platforms, all stages run sequentially in the same context.

**Usage:** `plan-phase [N]` — optionally add `--skip-research` or `--skip-verify`

> **Platform note:** Read `parallelization` from `.planning/config.json`. When `true`, researcher/planner/checker each run as a spawned subagent. When `false` (default), all stages run inline using agent persona files.

## Step 1: Initialize

Read `.planning/ROADMAP.md` and find the requested phase. If no phase number provided, detect the next unplanned phase.

If phase not found: stop and show available phases.

Read config:
```bash
cat .planning/config.json
```

Create the phase directory if it doesn't exist:
```bash
mkdir -p ".planning/phases/[padded_phase]-[phase_slug]"
```

Check what already exists:
```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/" 2>/dev/null
```

## Step 1b: Load Decisions Register

If `.planning/DECISIONS.md` exists, read it:
```bash
cat .planning/DECISIONS.md 2>/dev/null
```

Surface any decisions relevant to this phase — the planner must not contradict active decisions without explicit user instruction.

## Step 2: Load CONTEXT.md

Check if a CONTEXT.md exists for this phase.

**If no CONTEXT.md:**
Ask: "No CONTEXT.md found for Phase [X]. Plans will use research and requirements only — your design preferences won't be included."
- **Continue without context** → proceed
- **Run discuss-phase first** → stop, suggest running `discuss-phase [X]` first

**If CONTEXT.md exists:** Load it and confirm: "Using phase context from: [path]"

## Step 3: Research Phase

**Skip if:** `--skip-research` flag, or `workflow.research` is `false` in config, or RESEARCH.md already exists (unless `--research` flag forces re-research).

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING PHASE [X]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `parallelization` is `true` (subagent mode):**

Spawn a dedicated researcher agent:
```
Task(
  subagent_type="learnship-phase-researcher",
  prompt="
    <objective>
    Research how to implement Phase [phase_number]: [phase_name].
    Answer: 'What do I need to know to PLAN this phase well?'
    Write RESEARCH.md to [phase_dir]/[padded_phase]-RESEARCH.md.
    </objective>

    <files_to_read>
    - [context_path] (user decisions, if exists)
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    </files_to_read>
  "
)
```

Wait for agent to complete, then verify RESEARCH.md was written.

**If `parallelization` is `false` (sequential mode):**

Using `@./agents/researcher.md` as your research persona, investigate how to implement this phase. Read:
- The CONTEXT.md (user decisions)
- `.planning/REQUIREMENTS.md` (which requirements this phase covers)
- `.planning/STATE.md` (project history and decisions)
- Existing codebase for relevant patterns

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-RESEARCH.md` with two key sections:
- **Don't Hand-Roll** — problems with good existing solutions ("Don't build your own JWT — use jose")
- **Common Pitfalls** — what goes wrong, why, how to avoid it

## Step 4: Check Existing Plans

```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-PLAN.md 2>/dev/null
```

If plans already exist, ask: "Phase [X] already has [N] plan(s)."
- **Add more plans** → continue to planning
- **View existing** → show plans, then ask
- **Replan from scratch** → delete existing plans, continue

## Step 5: Create Plans

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PLANNING PHASE [X]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `parallelization` is `true` (subagent mode):**

Spawn a dedicated planner agent:
```
Task(
  subagent_type="learnship-planner",
  prompt="
    <objective>
    Create 2-4 executable PLAN.md files for Phase [phase_number]: [phase_name].
    Write plans to [phase_dir]/[padded_phase]-NN-PLAN.md.
    </objective>

    <files_to_read>
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - [context_path] (if exists)
    - [research_path] (if exists)
    - $LEARNSHIP_DIR/templates/plan.md
    </files_to_read>
  "
)
```

Wait for agent to complete, then verify PLAN.md files were written.

**If `parallelization` is `false` (sequential mode):**

Using `@./agents/planner.md` as your planning persona, read all available context:
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- CONTEXT.md (if exists)
- RESEARCH.md (if exists)

Create 2-4 PLAN.md files in the phase directory. Each plan:
- Covers a single logical unit of work executable in one context window
- Has YAML frontmatter: `wave`, `depends_on`, `files_modified`, `autonomous`
- Contains tasks in XML format (see `$LEARNSHIP_DIR/templates/plan.md`)
- Has `must_haves` section with observable verification criteria

**Wave assignment:**
- Plans with no dependencies → Wave 1 (independent, execute in any order)
- Plans depending on Wave 1 → Wave 2
- Plans with cross-plan file conflicts → same wave or sequential

**Name plans:** `[padded_phase]-01-PLAN.md`, `[padded_phase]-02-PLAN.md`, etc.

## Step 6: Verify Plans

**Skip if:** `--skip-verify` flag, or `workflow.plan_check` is `false` in config.

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► VERIFYING PLANS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `parallelization` is `true` (subagent mode):**

Spawn a plan-checker agent:
```
Task(
  subagent_type="learnship-plan-checker",
  prompt="
    <objective>
    Verify all PLAN.md files in [phase_dir] for Phase [phase_number]: [phase_name].
    Check: phase goal coverage, requirement IDs, CONTEXT.md decisions, task completeness, wave correctness.
    Return: PASS or list of specific issues per plan.
    </objective>

    <files_to_read>
    - [phase_dir]/*-PLAN.md (all plans)
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - [context_path] (if exists)
    </files_to_read>
  "
)
```

If issues returned: revise affected plans, re-spawn checker. Max 3 iterations.
If still failing after 3 iterations: present issues and ask — **Force proceed** / **Provide guidance and retry** / **Abandon**.

**If `parallelization` is `false` (sequential mode):**

Using `@./agents/verifier.md` as your verification persona, check the plans against:
- The phase goal from ROADMAP.md
- All requirement IDs assigned to this phase
- CONTEXT.md decisions (are they honored?)
- Task completeness (files, action, verify, done fields)
- Wave/dependency correctness

**Verification loop (max 3 iterations):**

If issues found:
1. List the issues clearly
2. Revise the affected plans to fix them
3. Re-verify
4. If still failing after 3 iterations: present remaining issues and ask — **Force proceed** / **Provide guidance and retry** / **Abandon**

If verification passes: proceed.

## Step 7: Commit Plans

```bash
git add ".planning/phases/[padded_phase]-[phase_slug]/"
git commit -m "docs([padded_phase]): create phase plans"
```

## Step 7b: Update AGENTS.md

If `AGENTS.md` exists at the project root, update the `## Current Phase` block:

```markdown
## Current Phase

**Milestone:** [VERSION from STATE.md]
**Phase:** [N] — [Phase Name]
**Status:** planning
**Last updated:** [today's date]
```

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md — planning phase [N]"
```

## Step 8: Present Status

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PHASE [X] PLANNED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Phase [X]: [Name]** — [N] plan(s) in [M] wave(s)

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1    | 01, 02 | [objectives] |
| 2    | 03     | [objective]  |

Research: [Completed | Used existing | Skipped]
Verification: [Passed | Passed with override | Skipped]

▶ Next: execute-phase [X]
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer based on context:

> 💡 **Learning moment:** Plans are ready. Before you execute, make sure the domain is solid:
>
> `@agentic-learning explain-first [phase topic]` — Explain the approach back in your own words before touching code. Gaps in the explanation reveal gaps in the mental model — before they become bugs.
>
> `@agentic-learning cognitive-load [topic]` — If the scope feels overwhelming, decompose it into working-memory-sized steps first.
>
> `@agentic-learning quiz [phase topic]` — Quick active recall on the domain concepts this phase covers. Especially useful if the research surfaced unfamiliar territory.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning explain-first [topic]` to validate your mental model before executing."*
