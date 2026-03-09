---
description: Execute an ad-hoc task with full agentic guarantees — atomic commits, state tracking, no full planning ceremony
---

# Quick Task

Execute small, ad-hoc tasks with full agentic guarantees: atomic commits, STATE.md tracking, optional discussion and verification.

**Usage:** `quick [description]`

**Flags:**
- `--discuss` — lightweight discussion phase before planning (surfaces gray areas)
- `--full` — adds plan-checking and post-execution verification

**Composable:** `quick --discuss --full "add dark mode toggle"` gives discussion + plan-checking + verification.

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
test -f .planning/ROADMAP.md && echo "OK" || echo "MISSING"
```

If ROADMAP.md missing: stop — run `new-project` first. Quick tasks require an active project.

Generate a slug from the description (lowercase, hyphens, max 40 chars).

Find the next task number:
```bash
ls .planning/quick/ 2>/dev/null | grep -E "^[0-9]+" | sort -n | tail -1
```

Set `NEXT_NUM` to the next available number (001, 002, etc.).

Create task directory:
```bash
mkdir -p ".planning/quick/${NEXT_NUM}-${SLUG}"
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

Present them for selection (multi-select):
- Each area is a concrete decision point (not generic)
- Include an "All clear — skip discussion" option

If "All clear" → skip to Step 4.

For each selected area, ask 1-2 focused questions with concrete options. Max 2 questions per area — keep it lightweight.

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

### Claude's Discretion
[Areas not discussed or "you decide" answers]

</decisions>

<specifics>
## Specific Ideas

[Any specific references or examples]

</specifics>
```

## Step 4: Create Plan

Using `@./agents/planner.md` as your planning persona, read:
- `.planning/STATE.md`
- CONTEXT.md if it exists (from `--discuss`)
- The task description

Create a **single PLAN.md** with 1-3 focused tasks in `.planning/quick/${NEXT_NUM}-${SLUG}/${NEXT_NUM}-PLAN.md`.

Each task needs:
- `<files>` — exact files to create/modify
- `<action>` — specific implementation instructions
- `<verify>` — how to confirm it worked
- `<done>` — observable completion criteria

If `--full`: also include `must_haves` in plan frontmatter (truths, artifacts, key_links).

Verify plan was created:
```bash
test -f ".planning/quick/${NEXT_NUM}-${SLUG}/${NEXT_NUM}-PLAN.md" && echo "OK"
```

## Step 5: Plan Check (only with `--full`)

**Skip if `--full` flag is not present.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► CHECKING PLAN
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Using `@./agents/verifier.md`, verify the plan against the task description:
- Does the plan address the task description?
- Do tasks have files, action, verify, done fields?
- Is this appropriately sized for a quick task (1-3 tasks)?
- If `--discuss`: does the plan honor locked decisions from CONTEXT.md?

**Revision loop (max 2 iterations):** If issues found, revise and re-check.

If still failing after 2 iterations: present remaining issues and ask — **Force proceed** or **Abort**.

## Step 6: Execute

Using `@./agents/executor.md` as your execution persona, read the PLAN.md and execute each task:

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

## Step 7: Verify Results (only with `--full`)

**Skip if `--full` flag is not present.**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► VERIFYING RESULTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Using `@./agents/verifier.md`, check `must_haves` from the plan against the actual codebase.

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
[If --full: Verification: [status]]
Commit: [hash]

Ready for next task: quick
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto` and task was technically complex (involved unfamiliar patterns, a tricky bug, or a new library):**

> 💡 **Learning moment:** That looked challenging. Want to try it again from scratch?
>
> `@agentic-learning struggle [task]` — Work through a similar problem with a hint ladder. The re-implementation builds deeper understanding than just reading the solution.

**If `manual`:** No note for quick tasks (keep it fast).
