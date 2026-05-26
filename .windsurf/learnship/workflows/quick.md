---
description: Execute an ad-hoc task with full agentic guarantees — atomic commits, state tracking, no full planning ceremony
---

# Quick Task

Execute small, ad-hoc tasks with full agentic guarantees: atomic commits, STATE.md tracking, optional discussion and verification.

**Usage:** `quick [description]`

**Flags:**
- `--discuss` — lightweight discussion phase before planning (surfaces gray areas)
- `--research` — spawns a focused research agent before planning (investigates approaches, libraries, pitfalls)
- `--validate` — enables plan-checking (max 2 iterations) and post-execution verification
- `--full` — enables all of the above: discussion + research + plan-checking + verification

**Composable:** Granular flags compose freely. `quick --discuss --research --validate` = `--full`.

## Step 1: Get Task Description

If a description was provided as an argument, use it. Otherwise ask:

"What do you want to do?"

Wait for response. Store as `DESCRIPTION`.

Display banner based on active flags:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► QUICK TASK [flags if any]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Step 2: Initialize

Check that a project exists:
```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning/PROJECT.md') ? 'OK' : 'MISSING')"
```

If PROJECT.md missing: stop — run `new-project` first. Quick tasks require an active project.

If PROJECT.md exists but ROADMAP.md is missing: continue — note in the SUMMARY.md that no roadmap phase could be linked, and skip STATE.md phase references.

Generate a slug from the description (lowercase, hyphens, max 40 chars).

Find the next task number:
```bash
ls .planning/quick/ 2>/dev/null | grep -E "^[0-9]+" | sort -n | tail -1
# PowerShell: Get-ChildItem .planning/quick/ -ErrorAction SilentlyContinue | Where-Object { $_.Name -match '^[0-9]+' } | Sort-Object Name | Select-Object -Last 1
```

Set `NEXT_NUM` to the next available number (001, 002, etc.).

Create task directory:
```bash
node -e "require('fs').mkdirSync('.planning/quick/${NEXT_NUM}-${SLUG}',{recursive:true})"
# PowerShell: New-Item -ItemType Directory -Force -Path ".planning/quick/${NEXT_NUM}-${SLUG}"
```

Report: "Creating quick task ${NEXT_NUM}: ${DESCRIPTION}"

## Step 3: Discussion Phase (only with `--discuss`)

**Skip this step if `--discuss` flag is not present.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DISCUSSING: [DESCRIPTION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Analyze `DESCRIPTION` to identify 2-4 gray areas — implementation decisions that would change the outcome.

Present them for selection using a structured multi-select question:

```
ask_user_question([
  {
    header: "Gray Areas",
    question: "Which areas need clarification? (select all that apply)",
    multiSelect: true,
    options: [
      { label: "[Area 1]", description: "[Concrete decision point]" },
      { label: "[Area 2]", description: "[Concrete decision point]" },
      { label: "[Area 3]", description: "[Concrete decision point]" },
      { label: "All clear — skip discussion", description: "No gray areas need clarification" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

If "All clear" → skip to Step 4.

For each selected area, ask 1-2 focused questions with concrete options using structured questions. Max 2 questions per area — keep it lightweight.

Write `CONTEXT.md` to the task directory:

```markdown
# Quick Task [NEXT_NUM]: [DESCRIPTION] - Context

**Gathered:** [date]
**Status:** Ready for planning

<domain>
## Task Boundary

[DESCRIPTION]

</domain>

<decisions>
## Implementation Decisions

### [Area discussed]
- [Decision captured]

### Agent's Discretion
[Areas not discussed or "you decide" answers]

</decisions>

<specifics>
## Specific Ideas

[Any specific references or examples]

</specifics>
```

## Step 3b: Research Phase (only with `--research` or `--full`)

**Skip if neither `--research` nor `--full` flag is present.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING: [DESCRIPTION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

<persona_context>
You are now the **learnship researcher**. Your training data is stale — verify before asserting.
Use search_web for current best practices, read_url_content for official docs, codebase scan for existing patterns.
Tag confidence: HIGH/MEDIUM/LOW. Investigation, not confirmation.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[36m  learnship-researcher(Your training data is stale — verify before asserting)\033[0m\n\n"
> ```

Read `@./agents/researcher.md` for the full persona definition. Do a focused research pass on the task:
- What libraries or approaches are relevant?
- What pitfalls should the implementation avoid?
- Are there existing patterns in the codebase to follow?

Write a brief `${NEXT_NUM}-RESEARCH.md` (max 50 lines) to the task directory. This feeds into the planner.

## Step 4: Create Plan

<persona_context>
You are now the **learnship planner**. Create a focused implementation plan.
Single plan with 1-3 tasks. Each task must be completable in one context window. Include must_haves.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[32m  learnship-planner(Create a focused implementation plan)\033[0m\n\n"
> ```

Read `@./agents/planner.md` for the full persona definition. Read:
- `.planning/STATE.md`
- CONTEXT.md if it exists (from `--discuss`)
- The task description

Create a **single PLAN.md** with 1-3 focused tasks in `.planning/quick/${NEXT_NUM}-${SLUG}/${NEXT_NUM}-PLAN.md`.

Each task needs:
- `<files>` — exact files to create/modify
- `<action>` — specific implementation instructions
- `<verify>` — how to confirm it worked
- `<done>` — observable completion criteria

If `--validate` or `--full`: also include `must_haves` in plan frontmatter (truths, artifacts, key_links).
If `--research` or `--full`: also read the RESEARCH.md from step 3b.

Verify plan was created (substitute actual NEXT_NUM and SLUG values):
```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning/quick/NEXT_NUM-SLUG/NEXT_NUM-PLAN.md') ? 'OK' : 'MISSING')"
```

## Step 5: Plan Check (only with `--validate` or `--full`)

**Skip if neither `--validate` nor `--full` flag is present.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► CHECKING PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

<persona_context>
You are now the **learnship verifier**. Check the plan against the task description.
Flag gaps, missing coverage, and unrealistic scope.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[35m  learnship-verifier(Check the plan against the task description)\033[0m\n\n"
> ```

Read `@./agents/verifier.md` for the full persona definition. Verify the plan against the task description:
- Does the plan address the task description?
- Do tasks have files, action, verify, done fields?
- Is this appropriately sized for a quick task (1-3 tasks)?
- If `--discuss`: does the plan honor locked decisions from CONTEXT.md?

**Revision loop (max 2 iterations):** If issues found, revise and re-check.

If still failing after 2 iterations: present remaining issues and ask — **Force proceed** or **Abort**.

## Step 6: Execute

<persona_context>
You are now the **learnship executor**. Implement code from the plan, one task at a time.
Read task files, action, verify, and done fields. Commit atomically after each task.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[33m  learnship-executor(Implement code from the plan, one task at a time)\033[0m\n\n"
> ```

Read `@./agents/executor.md` for the full persona definition. Read the PLAN.md and execute each task:

1. Read the task's `<files>`, `<action>`, `<verify>`, `<done>` fields
2. Implement what the action describes
3. Verify using the verify criteria
4. Commit atomically:

```bash
git add [files modified]
git commit -m "feat(quick-${NEXT_NUM}): [task description]"
```

After all tasks complete, write `${NEXT_NUM}-SUMMARY.md`:

```markdown
# Quick Task [NEXT_NUM] Summary

**Task:** [DESCRIPTION]
**Completed:** [date]

## What was done
[2-3 sentences]

## Files changed
- [file]: [what changed]

## Commit
[commit hash]
```

## Step 7: Verify Results (only with `--validate` or `--full`)

**Skip if neither `--validate` nor `--full` flag is present.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► VERIFYING RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

<persona_context>
You are now the **learnship verifier**. Check must_haves from the plan against the actual codebase.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[35m  learnship-verifier(Check must_haves from the plan against the actual codebase)\033[0m\n\n"
> ```

Read `@./agents/verifier.md` for the full persona definition. Check `must_haves` from the plan against the actual codebase.

Write `${NEXT_NUM}-VERIFICATION.md`. Store status as `VERIFICATION_STATUS`.

## Step 8: Update STATE.md

Read `.planning/STATE.md` and append to the Quick Tasks table (create section if it doesn't exist):

```markdown
### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| [NEXT_NUM] | [DESCRIPTION] | [date] | [hash] | [path] |
```

Update "Last activity" line:
```
Last activity: [date] - Completed quick task [NEXT_NUM]: [DESCRIPTION]
```

## Step 9: Final Commit

```bash
git add ".planning/quick/${NEXT_NUM}-${SLUG}/" .planning/STATE.md
git commit -m "docs(quick-${NEXT_NUM}): ${DESCRIPTION}"
```

Display completion:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► QUICK TASK COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Quick Task [NEXT_NUM]: [DESCRIPTION]

Summary: .planning/quick/[NEXT_NUM]-[SLUG]/[NEXT_NUM]-SUMMARY.md
[If --validate/--full: Verification: [status]]
Commit: [hash]

💡 Solved something notable? `/compound` — capture the solution while context is fresh
💡 Ready to push? `/ship` — test → commit → push → PR

Ready for next task: quick
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer based on how the task went:

> 💡 **Learning moment:** Task done. Pick the action that matches what happened:
>
> `@agentic-learning struggle [task]` — If the task was tricky or used unfamiliar patterns: work through a similar problem from scratch with a hint ladder. Builds deeper intuition than just reading the solution.
>
> `@agentic-learning learn [task topic]` — If the task touched an unfamiliar domain: active retrieval while the context is fresh. You explain first, gaps get filled.
>
> `@agentic-learning either-or` — If you made a meaningful design decision during the task: log the choice and the alternatives considered.

**If `manual`:** No note for quick tasks (keep it fast).
