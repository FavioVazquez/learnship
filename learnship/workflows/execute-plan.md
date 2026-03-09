---
description: Run a single PLAN.md file in isolation — useful for re-running a failed plan without re-executing the whole phase
---

# Execute Plan

Execute a single PLAN.md file in isolation. Useful when one plan in a phase failed, when you want to re-run a specific plan after a fix, or when testing a plan independently before running the full phase.

**Usage:** `execute-plan [phase] [plan-id]` — e.g., `execute-plan 3 02`

## Step 1: Locate the Plan

Find the phase directory:
```bash
ls .planning/phases/ | grep -E "^0*[phase]-" | head -1
PHASE_DIR=".planning/phases/[matched]"
```

Find the specific plan file:
```bash
ls "$PHASE_DIR"/*-[plan-id]-PLAN.md 2>/dev/null
```

If not found, list available plans:
```bash
ls "$PHASE_DIR"/*-PLAN.md 2>/dev/null
```

If still not found: stop — "No plan file found. Check phase and plan ID."

## Step 2: Check for Existing Summary

```bash
ls "${PLAN_FILE%-PLAN.md}-SUMMARY.md" 2>/dev/null
```

If SUMMARY.md already exists:
```
Plan [phase]-[plan-id] already has a SUMMARY.md — it appears to have been executed.

Options:
1. Re-execute anyway (overwrites SUMMARY.md)
2. View the existing summary
3. Cancel
```

Wait for choice.

## Step 3: Load Context

Read the full plan file. Read project context:
```bash
cat .planning/STATE.md
cat .planning/ROADMAP.md
```

Read any existing SUMMARY.md files from other plans in the same phase — they contain important context about what was already built.

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► EXECUTE PLAN [phase]-[plan-id]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Plan: [plan file name]
Objective: [from plan frontmatter]
Wave: [wave number]
Depends on: [depends_on from frontmatter, or "none"]
```

## Step 4: Check Dependencies

If the plan has `depends_on` entries in its frontmatter, check that those plans have SUMMARY.md files:

```bash
for dep in [depends_on list]; do
  ls "$PHASE_DIR"/*${dep}*-SUMMARY.md 2>/dev/null || echo "MISSING: $dep"
done
```

If any dependency is missing:
```
⚠️  This plan depends on [plan-id] which has not been executed yet.

Options:
1. Execute [plan-id] first (recommended)
2. Proceed anyway (may fail if dependent files don't exist)
```

## Step 5: Execute

Using `@./agents/executor.md` as execution persona, execute each task in the plan sequentially:

1. Read the task's `<files>`, `<action>`, `<verify>`, and `<done>` fields
2. Implement exactly what the action describes
3. Verify using the verify criteria
4. Commit atomically after each task:

```bash
git add [files modified]
git commit -m "[type]([phase]-[plan-id]): [task description]"
```

For checkpoint plans (`autonomous: false`), pause for human verification:
```
╔══════════════════════════════════════════════════════════════╗
║  CHECKPOINT: Human Action Required                           ║
╚══════════════════════════════════════════════════════════════╝

[What needs to be done / verified]

→ Reply "done" when complete, or describe any issues found
```

## Step 6: Write SUMMARY.md

Write `${PLAN_FILE%-PLAN.md}-SUMMARY.md`:

```markdown
# Plan [plan-id] Summary

**Completed:** [date]
**Executed via:** execute-plan (isolated run)

## What was built
[2-4 sentences]

## Key files
- [file]: [what it does]

## Decisions made
- [Any implementation choices]

## Notes for downstream
- [Anything the next plan or phase should know]
```

## Step 7: Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PLAN [phase]-[plan-id] COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Summary of what was built]

▶ If this was the last missing plan: execute-phase [phase] will skip already-done plans
  and run the verifier to check the full phase goal.
```
