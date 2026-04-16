---
description: Execute all plans in a phase using wave-based ordered execution — spawns subagents per plan where the platform supports it
---

# Execute Phase

Execute all plans in a phase. Plans run in waves — ordered by dependencies. On platforms with subagent support (Claude Code, OpenCode, Codex), plans within a wave are dispatched to dedicated executor agents. On all other platforms, plans execute sequentially.

**Usage:** `execute-phase [N]` or `execute-phase [N] --wave [W]`

**Core principle:** Orchestrate, don't implement directly. Describe each plan's objective clearly, execute each plan in sequence (or in parallel via subagents), collect results.

> **Platform note:** This workflow detects whether subagent spawning is available by reading `parallelization.enabled` from `.planning/config.json`. Set `"parallelization": { "enabled": true }` to enable parallel agent spawning on supported platforms. Defaults to `false` (sequential — always safe). The legacy flat `"parallelization": true` is also honored for backward compatibility.

<runtime_compatibility>
**Subagent spawning is runtime-specific:**
- **Claude Code:** Uses `Task(subagent_type=..., ...)` — blocks until complete, returns result
- **OpenCode / Codex:** Subagent spawning supported with platform-native dispatch
- **Windsurf / Cursor:** No subagent spawning — always use sequential inline execution
- **Gemini CLI:** Subagents exist but parallel execution limited — default to sequential

**Fallback rule:** If a spawned agent completes its work (commits visible, SUMMARY.md exists) but the orchestrator never receives the completion signal, treat it as successful based on spot-checks and continue to the next wave/plan. Never block indefinitely.
</runtime_compatibility>

## Step 1: Parse Arguments

Parse `$ARGUMENTS` for:
- First positional token → `PHASE_ARG` (phase number)
- Optional `--wave N` → `WAVE_FILTER` (execute only wave N)
- Optional `--gaps-only` → execute only gap-closure plans

If `--wave` is absent, execute all incomplete waves in the phase.

## Step 1b: Initialize

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

**Context window scaling:** Check for `context_window` in config (default: 200000). At < 500000 tokens: read only frontmatter from prior phase SUMMARYs. At >= 500000: full body reads permitted for direct-dependency phases. See `@./references/context-budget.md` for the complete table.

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

## Step 2b: UI Detection

Before executing, scan all PLAN.md files for UI/frontend work:

Look for any of these signals in plan objectives, task descriptions, or file paths:
- UI keywords: `component`, `page`, `layout`, `form`, `modal`, `nav`, `dashboard`, `landing`, `design`, `style`, `css`, `tailwind`, `theme`, `color`, `typography`, `animation`, `responsive`
- Frontend file patterns: `.tsx`, `.jsx`, `.vue`, `.svelte`, `styles/`, `components/`, `pages/`, `app/`

**If UI work is detected:**

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► UI PHASE DETECTED — applying impeccable standards
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Activate `@impeccable frontend-design` as your design foundation for this entire phase. This means:

- **Typography:** Avoid overused fonts (Inter, Roboto, Arial). Use a modular type scale with clear visual hierarchy.
- **Color:** Avoid the AI palette (cyan-on-dark, purple-to-blue gradients, neon on dark). Tint neutrals toward the brand hue. No pure black (#000) or pure white (#fff).
- **Layout:** Create rhythm through varied spacing. Not everything needs a card. Never nest cards inside cards.
- **Components:** Avoid large rounded icons above every heading. Resist generic "AI-built" patterns.
- **Differentiation:** Every UI phase must have one intentional, memorable design decision — commit to it.

Check if `@impeccable teach-impeccable` has been run for this project (look for a `.planning/impeccable-context.md` or references to impeccable in DECISIONS.md). If not, add a note at the end of execution suggesting it be run before the next UI phase.

Carry these principles through every task in every wave of this phase.

## Step 2c: TDD Mode Check

Read `test_first` from `.planning/config.json` (defaults to `false`).

If `test_first` is `true`:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► TDD MODE ACTIVE — red-green-refactor per task
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

In TDD mode, each executor uses the red-green-refactor cycle:
1. **Red** — write the failing test first
2. **Verify red** — confirm the test fails
3. **Green** — write minimum code to pass
4. **Verify green** — confirm the test passes
5. **Refactor** — clean up without changing behavior
6. **Commit** — atomic commit (test + implementation together)

Both inline (`@./agents/executor.md`) and subagent (`learnship-executor`) executors honor this setting.

## Step 3: Execute Waves

Read `parallelization` from `.planning/config.json`. Supports both:
- New format: `parallelization.enabled` (boolean)
- Legacy format: `parallelization` (flat boolean)

Defaults to `false` if not found.

If `WAVE_FILTER` is set, skip all waves except the specified one.

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

**If parallelization is enabled (subagent mode — Claude Code, OpenCode, Codex):**

For each plan in the wave, spawn a dedicated executor subagent. Pass paths only — each executor reads files itself with a fresh context budget.

```
Task(
  subagent_type="learnship-executor",
  description="Execute plan [plan_id]",
  prompt="
    <agent_definition>
    You are a learnship executor. Execute plan tasks one at a time, commit atomically after each.
    Read the plan file, follow each task's action field exactly. Verify using the verify field.
    Mark tasks done. Create SUMMARY.md when complete. Update STATE.md.
    Never skip tasks. Never batch commits. One task = one commit.
    </agent_definition>

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

**If parallelization is disabled (sequential mode — Windsurf, Cursor, Gemini CLI, or user preference):**

<persona_context>
You are now the **learnship executor**. Implement code from plans, one task at a time.
Read task files, action, verify, and done fields. Implement exactly what the action describes.
Commit atomically after each task. Never skip verification. Never modify code outside the task scope.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[33m  learnship-executor(Implement code from plans, one task at a time)\033[0m\n\n"
> ```

Read `@./agents/executor.md` for the full persona definition. For each plan in the wave:

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

<persona_context>
You are now the **learnship verifier**. Check implementation against plan requirements.
Every must_have from the plan must be met. Success criteria must be observable and testable.
Flag gaps, missing coverage, and broken tests.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[35m  learnship-verifier(Check implementation against plan requirements)\033[0m\n\n"
> ```

Read `@./agents/verifier.md` for the full persona definition. Check:
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

**Post-update verification (cross-platform):**

```bash
node -e "const fs=require('fs');if(!fs.existsSync('AGENTS.md')){process.exit(0);}const f=fs.readFileSync('AGENTS.md','utf8');const required=['Soul','Principles','Request Routing Protocol','Platform Context','Current Phase','Project Structure','Tech Stack','Skills','Regressions'];const missing=required.filter(s=>!f.includes('## '+s));if(missing.length){console.log('AGENTS.md sections lost during update:\\n'+missing.map(s=>'  ## '+s).join('\\n'));process.exit(1);}console.log('AGENTS.md sections intact');"
```

> If verification fails, restore the missing sections from `@./templates/agents.md` before committing.

**Sync platform-native copies (if they exist):**

```bash
node -e "const fs=require('fs');const copies=[['CLAUDE.md','Claude Code'],['GEMINI.md','Gemini CLI']];if(!fs.existsSync('AGENTS.md'))process.exit(0);copies.forEach(([f,p])=>{if(fs.existsSync(f)){fs.copyFileSync('AGENTS.md',f);console.log('Synced AGENTS.md → '+f+' ('+p+')');}});"
```

```bash
git add AGENTS.md CLAUDE.md GEMINI.md 2>/dev/null
git commit -m "docs: update AGENTS.md — phase [X] complete"
```

## Step 8: Done

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PHASE [X] COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Phase [X]: [Name]** — all plans complete, goals verified.

▶ Next: verify-work [X]  (manual UAT)
   Then: /review → /ship → /compound
   Then: discuss-phase [X+1] → plan-phase [X+1]

💡 Security: `/secure-phase [X]` — run STRIDE threat verification on this phase
💡 Learnings: `/extract-learnings [X]` — capture decisions, lessons, patterns while fresh
💡 Working on sensitive files? Run `/guard [scope]` to enable safety mode.
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer all three — pick the one that fits:

> 💡 **Learning moment:** Phase [X] is done. Three ways to make this stick:
>
> `@agentic-learning reflect` — Structured 3-part reflection: what was built, what was the goal, what gaps remain. Takes 5 minutes, pays off for weeks.
>
> `@agentic-learning quiz [phase topic]` — Active recall on what was just implemented. Surfaces gaps in understanding before they become bugs in the next phase.
>
> `@agentic-learning interleave [phase topic]` — Mix this phase's concepts with older ones to strengthen long-term retention. Especially useful if this phase touched a domain you've worked in before.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning reflect` · `@agentic-learning quiz [topic]` · `@agentic-learning interleave [topic]` — pick one to consolidate this phase."*
