---
description: Append a new phase to the current milestone roadmap when scope grows after initial planning
---

# Add Phase

Append a new integer phase to the end of the current milestone. Use when scope grows after initial planning — a new feature, an unplanned integration, or a discovered dependency.

**Usage:** `add-phase [description]`

## Step 1: Validate

Check that a roadmap exists:
```bash
test -f .planning/ROADMAP.md && echo "OK" || echo "MISSING"
```

If missing: stop — run `new-project` first.

If no description was provided as an argument, ask: "What does this new phase deliver?"

## Step 2: Find Next Phase Number

Read `.planning/ROADMAP.md` and find the highest existing integer phase number:
```bash
grep -E "^## Phase [0-9]+" .planning/ROADMAP.md | tail -1
```

Also scan the phases directory for any directories that may not be in the roadmap:
```bash
ls .planning/phases/ 2>/dev/null | grep -E "^[0-9]+" | sort -n | tail -3
```

Set `NEXT_NUM` = highest found + 1. Pad to 2 digits (01, 02, ..., 10, 11, ...).

Generate a slug from the description (lowercase, hyphens, max 40 chars).

## Step 3: Create Phase Directory

```bash
mkdir -p ".planning/phases/${NEXT_NUM}-${SLUG}"
```

## Step 4: Update ROADMAP.md

Append the new phase entry to ROADMAP.md:

```markdown
## Phase [N]: [Description]

**Goal:** [One sentence — what user can do after this phase]
**Status:** [ ] Not started
**Depends on:** Phase [N-1]

### Plans
*Not yet planned — run `plan-phase [N]`*
```

## Step 5: Update STATE.md

Add to the "Roadmap Evolution" section under Accumulated Context (create if missing):
```markdown
### Roadmap Evolution
- Phase [N] added: [description]
```

## Step 6: Commit

```bash
git add .planning/ROADMAP.md .planning/STATE.md
git commit -m "chore(roadmap): add phase [N] — [description]"
```

## Step 7: Confirm

```
Phase [N] added: [description]

Directory: .planning/phases/[NN]-[slug]/
Status: Not planned yet
Roadmap: .planning/ROADMAP.md updated

▶ Next: plan-phase [N]
```
