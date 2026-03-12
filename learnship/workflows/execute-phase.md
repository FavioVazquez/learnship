---
description: Execute all plans in a phase using wave-based ordered execution — spawns subagents per plan where the platform supports it
---

# Execute Phase

Execute all plans in a phase. Plans run in waves — ordered by dependencies. On platforms with subagent support (Claude Code, OpenCode, Codex), plans within a wave are dispatched to dedicated executor agents. On all other platforms, plans execute sequentially.

**Usage:** `execute-phase [N]`

**Core principle:** Orchestrate, don't implement directly. Describe each plan's objective clearly, execute each plan in sequence (or in parallel via subagents), collect results.

> **Platform note:** This workflow detects whether subagent spawning is available by reading `parallelization` from `.planning/config.json`. Set `"parallelization": true` to enable parallel agent spawning on supported platforms. Defaults to `false` (sequential — always safe).

## Step 1: Initialize

Read the phase directory:
```bash
ls .planning/phases/ | grep "^[0-9]" | sort
```

Find the phase matching `[N]`. If not found, stop and list available phases.

Read all PLAN.md files in the phase directory:
```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-PLAN.md 2>/dev/null
```

If no plans found: stop — run `plan-phase [N]` first.

Read `.planning/STATE.md` for project context.
Read `.planning/config.json` for settings.

## Step 2: Discover and Group Plans

Read each PLAN.md's frontmatter to extract:
- `wave` — which wave this plan belongs to
- `depends_on` — which plans must complete before this one
- `autonomous` — whether this plan requires human checkpoints
- `objective` — what this plan builds

Group plans into waves based on `wave` and `depends_on` values. Plans in the same wave have no cross-dependencies and can be executed in any order.

Report the execution plan:
```
## Execution Plan

**Phase [X]: [Name]** — [N] plans across [M] waves

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1    | 01, 02 | [objectives from plan frontmatter] |
| 2    | 03     | [objective] |
```

## Step 3: Execute Waves

Read `parallelization` from `.planning/config.json` (defaults to `false`).

For each wave, in sequence:

### Before each wave

Describe what's being built — read each plan's `<objective>`:

```
---
## Wave [N]

**Plan [ID]: [Name]**
[2-3 sentences: what this builds, technical approach, why it matters for the overall phase]

Executing [count] plan(s)...
---
```

### Execute the plans

**If `parallelization` is `true` (subagent mode — Claude Code, OpenCode, Codex):**

For each plan in the wave, spawn a dedicated executor subagent. Pass paths only — each executor reads files itself with a fresh context budget.

```
Task(
  subagent_type="learnship-executor",
  prompt="
    <objective>
    Execute plan [plan_id] of phase [phase_number]-[phase_name].
    Commit each task atomically. Create SUMMARY.md. Update STATE.md and ROADMAP.md.
    </objective>

    <files_to_read>
    Read these files at execution start using the Read tool:
    - [phase_dir]/[plan_file] (Plan)
    - .planning/STATE.md (State)
    - .planning/config.json (Config, if exists)
    - ./AGENTS.md or ./CLAUDE.md or ./GEMINI.md (Project context, whichever exists)
    </files_to_read>

    <success_criteria>
    - [ ] All tasks executed
    - [ ] Each task committed individually
    - [ ] SUMMARY.md created in plan directory
    - [ ] STATE.md updated
    </success_criteria>
  "
)
```

Spawn all plans in the wave before waiting. Wait for all agents to complete, then proceed to spot-checks.

**If `parallelization` is `false` (sequential mode — Windsurf, Gemini CLI, or user preference):**

For each plan in the wave, using `@./agents/executor.md` as your execution persona:

Read the full plan file. Execute each task in sequence:
1. Read the task's `<files>`, `<action>`, `<verify>`, and `<done>` fields
2. Implement exactly what the action describes
3. Verify using the verify criteria
4. Commit atomically after each task:

```bash
git add [files modified]
git commit -m "[type]([phase]-[plan]): [task description]"
```

Execute plans in the wave sequentially. Same-wave plans are independent so order within the wave doesn't matter.

### After each wave

Spot-check completion for each plan:
- Does the SUMMARY.md exist?
- Do the key created/modified files exist on disk?
- Does git log show commits for this plan?

If spot-check fails: report which plan failed, ask "Retry plan?" or "Continue with remaining waves?"

Report wave completion:
```
---
## Wave [N] Complete

**[Plan ID]: [Plan Name]**
[What was built — from SUMMARY.md]
[Notable deviations, if any]

[If more waves: what this enables for next wave]
---
```

### Checkpoint plans (`autonomous: false`)

When a plan requires human verification before continuing:

```
╔══════════════════════════════════════════════════════════════╗
║  CHECKPOINT: Human Action Required                           ║
╚══════════════════════════════════════════════════════════════╝

**Plan [ID]: [Name]**
Progress: [N] of [M] tasks complete

[What needs to be done / verified by the human]

→ Reply "done" when complete, or describe any issues found
```

Wait for user response before continuing.

## Step 4: Write SUMMARY.md per Plan

After each plan completes, write `[plan_file_base]-SUMMARY.md` in the same directory:

```markdown
# Plan [ID] Summary

**Completed:** [date]

## What was built
[2-4 sentences describing what was implemented]

## Key files
- [file]: [what it does]

## Decisions made
- [Any implementation choices made during execution]

## Notes for downstream
- [Anything the next plan or phase should know]
```

## Step 5: Aggregate Results

After all waves complete:

```
## Phase [X]: [Name] — Execution Complete

**Waves:** [N] | **Plans:** [M] complete

| Wave | Plans | Status |
|------|-------|--------|
| 1    | 01, 02 | ✓ Complete |
| 2    | 03    | ✓ Complete |

### Summary
[Brief description of what was built across all plans]
```

## Step 6: Verify Phase Goal

Read `workflow.verifier` from `.planning/config.json`.

**If verifier is enabled:**

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► VERIFYING PHASE GOAL
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Using `@./agents/verifier.md` as your verification persona, check:
- Do the `must_haves` from each plan's frontmatter match reality in the codebase?
- Are all requirement IDs for this phase accounted for?
- Do files exist, have substance, and export what they claim?
- Are the key integration links wired correctly?

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-VERIFICATION.md` with status: `passed`, `human_needed`, or `gaps_found`.

**If `human_needed`:**
```
## ✓ Phase [X]: [Name] — Human Verification Required

All automated checks passed. [N] items need human testing:

[List of items requiring manual verification]

→ Reply "approved" to continue, or describe any issues found
```

**If `gaps_found`:**
```
## ⚠ Phase [X]: [Name] — Gaps Found

**Score:** [N]/[M] must-haves verified

### What's Missing
[Gap summaries]

▶ Next: plan-phase [X] --gaps
```

If gaps found, stop here. User should run `plan-phase [X]` with gaps flag to create fix plans.

## Step 7: Update Roadmap

Mark phase complete in ROADMAP.md (update status to `✓ Complete` with date).
Update STATE.md to point to next phase.
Update REQUIREMENTS.md traceability section.

```bash
git add .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md
git commit -m "docs(phase-[X]): complete phase execution"
```

## Step 7b: Update AGENTS.md

If `AGENTS.md` exists at the project root, update the `## Current Phase` block to reflect execution complete and the next phase:

```markdown
## Current Phase

**Milestone:** [VERSION from STATE.md]
**Phase:** [X] — [Phase Name] ✓ complete → Phase [X+1] — [Next Phase Name]
**Status:** verifying
**Last updated:** [today's date]
```

Also append any newly created key files or modules to the `## Project Structure` tree if significant new directories were created during this phase.

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md — phase [X] complete"
```

## Step 8: Done

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PHASE [X] COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Phase [X]: [Name]** — all plans complete, goals verified.

▶ Next: verify-work [X]  (manual UAT)
   Then: discuss-phase [X+1] → plan-phase [X+1]
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** Phase [X] is done. This is a great time to consolidate what was built and what you learned.
>
> `@agentic-learning reflect` — Structured 3-part reflection: what was built, what was the goal, what gaps remain. Takes 5 minutes, pays off for weeks.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning reflect` to consolidate learning from this phase."*
