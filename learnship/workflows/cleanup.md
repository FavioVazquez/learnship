---
description: Archive completed milestone phase directories to keep .planning/phases/ clean
---

# Cleanup

Archive phase directories from completed milestones into `.planning/milestones/[version]-phases/`. Keeps `.planning/phases/` focused on the current milestone only.

**Usage:** `cleanup`

## Step 1: Find Completed Milestones

```bash
cat .planning/milestones/MILESTONES.md 2>/dev/null || ls .planning/milestones/ 2>/dev/null
```

Read `.planning/MILESTONES.md` (or list `.planning/milestones/`) to identify completed milestones and their versions.

Extract each milestone version (e.g., `v1.0`, `v1.1`, `v2.0`).

Check which milestone archive directories already exist:
```bash
ls -d .planning/milestones/v*-phases 2>/dev/null
```

Filter to milestones that do NOT already have a `-phases` archive directory. These are the ones needing cleanup.

If all milestones already have phase archives:
```
All completed milestones already have phase directories archived.
Nothing to clean up.
```
Stop.

## Step 2: Determine Phase Membership

For each completed milestone without a `-phases` archive, find which phases belong to it.

Read the archived ROADMAP snapshot for that milestone:
```bash
cat ".planning/milestones/[version]-ROADMAP.md" 2>/dev/null
```

Extract phase numbers and names from the archived roadmap.

Check which of those phase directories still exist in `.planning/phases/`:
```bash
ls -d .planning/phases/*/ 2>/dev/null
```

Match phase directories to milestone membership. Only include directories that still exist.

## Step 3: Show Dry-Run Summary

```
Cleanup Summary

v[X.Y] — [Milestone Name]
Phase directories to archive:
- 01-foundation/
- 02-auth/
- 03-core-features/
Destination: .planning/milestones/v[X.Y]-phases/

v[X.Z] — [Milestone Name]
Phase directories to archive:
- 04-security/
- 05-hardening/
Destination: .planning/milestones/v[X.Z]-phases/

---

Proceed with archiving? (yes/no)
```

Wait for confirmation. If "no": stop.

## Step 4: Archive Phase Directories

For each milestone and its phase directories:

```bash
mkdir -p ".planning/milestones/v[X.Y]-phases"
mv ".planning/phases/[phase-dir]/" ".planning/milestones/v[X.Y]-phases/"
```

Repeat for all milestones in the cleanup set.

## Step 5: Commit

```bash
git add .planning/milestones/ .planning/phases/
git commit -m "chore: archive phase dirs from completed milestones"
```

## Step 6: Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► CLEANUP COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Archived:
- v[X.Y]: [N] phase directories → .planning/milestones/v[X.Y]-phases/

.planning/phases/ now contains only current milestone phases.
```
