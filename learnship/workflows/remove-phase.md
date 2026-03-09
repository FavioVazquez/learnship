---
description: Remove a planned (not yet executed) phase and renumber subsequent phases
---

# Remove Phase

Remove a future phase from the roadmap, delete its directory, and renumber subsequent phases to maintain a clean linear sequence.

**Usage:** `remove-phase [N]`

**Only future phases can be removed.** Completed phases (with SUMMARY.md files) require explicit confirmation. The git commit is the historical record of what was removed.

## Step 1: Parse and Validate

Extract the phase number from arguments. If missing:
```
Usage: remove-phase [N]
Example: remove-phase 7

[N] = phase number to remove (integer or decimal like 3.1)
```

Check roadmap exists:
```bash
test -f .planning/ROADMAP.md && echo "OK" || echo "MISSING"
```

## Step 2: Verify the Phase is Future

Read `.planning/STATE.md` to find the current phase number.

Read `.planning/ROADMAP.md` to confirm phase `[N]` exists.

If target phase ≤ current phase:
```
Cannot remove Phase [N].

Only future (unstarted) phases can be removed.
Current phase: [current]
Phase [N] is current or already completed.

To undo completed work: use git revert on the phase commits.
```

Stop.

## Step 3: Check for Executed Work

```bash
ls ".planning/phases/[NN]-[slug]/"*-SUMMARY.md 2>/dev/null
```

If SUMMARY.md files exist, the phase has partially executed content. Warn:
```
⚠️  Phase [N] has [M] executed plan(s) with SUMMARY.md files.
Removing it will delete this work from the roadmap (git history preserves the commits).

Are you sure?
- Yes, remove it anyway
- No, keep it
```

Wait for confirmation before proceeding.

## Step 4: Confirm Removal

Show what will happen:
```
Removing Phase [N]: [Name]

This will:
- Delete: .planning/phases/[NN]-[slug]/
- Renumber: Phases [N+1] through [max] → [N] through [max-1]
- Update: ROADMAP.md and STATE.md

Proceed? (yes/no)
```

Wait for explicit confirmation.

## Step 5: Execute Removal

**Delete the phase directory:**
```bash
rm -rf ".planning/phases/[NN]-[slug]/"
```

**Renumber subsequent phases:**

For each phase directory after `[N]` (in reverse order to avoid conflicts):
```bash
# Example: phase 08 → 07, 09 → 08, etc.
for dir in $(ls .planning/phases/ | grep -E "^[0-9]" | sort -rV); do
  # extract number, if > removed phase number, decrement and rename
done
```

Also rename files inside each renamed directory (PLAN.md, SUMMARY.md, etc. that start with the old phase number).

**Update ROADMAP.md:**
- Remove the phase `[N]` section entirely
- Update all subsequent phase numbers and any `Depends on` references

**Update STATE.md:**
- Decrement total phase count
- Add to Roadmap Evolution: `- Phase [N] ([name]) removed`

## Step 6: Commit

```bash
git add -A
git commit -m "chore(roadmap): remove phase [N] ([original-name])"
```

The commit message preserves the historical record.

## Step 7: Confirm

```
Phase [N] ([original-name]) removed.

Changes made:
- Deleted: .planning/phases/[NN]-[slug]/
- Renumbered: [M] phases
- Updated: ROADMAP.md, STATE.md

▶ Next: progress (to see updated roadmap)
```
