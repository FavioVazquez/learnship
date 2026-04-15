---
description: Safe git revert for phase or plan commits — preserves history, checks dependencies
---

# Undo

Safe git revert workflow. Rolls back phase or plan commits using git revert (NEVER git reset) to preserve history. Includes dependency checks and a confirmation gate.

**Usage:**
- `undo --last N` — show last N commits for interactive selection
- `undo --phase NN` — revert all commits for phase NN
- `undo --plan NN-MM` — revert all commits for plan NN-MM

## Step 1: Parse Arguments

Parse for the undo mode:

- `--last N` — MODE=last, COUNT=N (default 10 if N missing)
- `--phase NN` — MODE=phase, TARGET_PHASE=NN
- `--plan NN-MM` — MODE=plan, TARGET_PLAN=NN-MM

If no valid argument, display usage and exit.

## Step 2: Gather Commits

**MODE=last:**

```bash
git log --oneline --no-merges -${COUNT}
```

Filter for conventional commits matching `type(scope): message` pattern. Display numbered list. Ask user to select which commits to revert (numbers or "all").

**MODE=phase:**

```bash
git log --oneline --no-merges --all --grep="(${TARGET_PHASE})" | head -30
git log --oneline --no-merges --all --grep="phase-${TARGET_PHASE}" | head -30
```

Collect all commits whose scope references the target phase.

**MODE=plan:**

```bash
git log --oneline --no-merges --all --grep="(${TARGET_PLAN})" | head -20
```

Collect all commits whose scope references the target plan.

If no commits found: "No commits found for [target]. Check the phase/plan number."

## Step 3: Dependency Check

For each commit to be reverted, check if later commits depend on the files it modified:

```bash
for COMMIT in $COMMITS; do
  FILES=$(git diff-tree --no-commit-id --name-only -r $COMMIT)
  for FILE in $FILES; do
    LATER=$(git log --oneline ${COMMIT}..HEAD -- "$FILE" | head -5)
    if [ -n "$LATER" ]; then
      echo "WARNING: $FILE was modified in later commits:"
      echo "$LATER"
    fi
  done
done
```

If dependencies found, warn:
```
WARNING: These commits have downstream dependencies.
Reverting may break later work. Files affected:

- [file]: modified in [N] later commits

Proceed anyway? [Yes, revert] / [No, cancel]
```

## Step 4: Confirmation Gate

Display the revert plan:
```
Commits to revert ([N] total):

  [hash] [message]
  [hash] [message]

This will create [N] new revert commits preserving full history.

[Confirm revert] / [Cancel]
```

Wait for explicit confirmation.

## Step 5: Execute Revert

For each commit in reverse chronological order:

```bash
git revert --no-commit [hash]
```

After all reverts staged:

```bash
git commit -m "revert([scope]): undo [description]

Reverted commits:
- [hash]: [message]
- [hash]: [message]"
```

## Step 6: Update State

If `.planning/STATE.md` exists, add a note about the revert:

```markdown
### Revert Log
- [date]: Reverted [N] commits for [target] — [reason if provided]
```

```bash
git add .planning/STATE.md
git commit -m "docs(state): record revert"
```

## Step 7: Report

```
learnship > UNDO COMPLETE

Reverted [N] commits for [target].
New revert commit: [hash]

All original commits preserved in history.
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:**

> **Learning moment:** Needing to undo is a signal worth examining:
>
> `@agentic-learning either-or` — What led to needing the undo? Was it a plan deficiency, an execution error, or a changed requirement? Log the reasoning so the pattern is visible next time.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning either-or` to log why the undo was needed."*
