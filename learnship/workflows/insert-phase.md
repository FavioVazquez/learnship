---
description: Insert a new phase between existing phases for urgent work discovered mid-milestone
---

# Insert Phase

Insert a decimal phase for urgent work discovered mid-milestone. Uses decimal numbering (e.g., `3.1`) to preserve the logical sequence of planned phases without renumbering everything.

**Usage:** `insert-phase [N] [description]`

**When to use:** Urgent bug fix, critical dependency discovered, security patch — work that must happen between two existing phases without waiting.

**Not for:** Regular scope additions → use `add-phase` for those.

## Step 1: Parse Arguments

Extract from arguments:
- First token: the integer phase number to insert **after** (e.g., `3`)
- Remaining text: phase description

If either is missing:
```
Usage: insert-phase [N] [description]
Example: insert-phase 3 Fix critical auth vulnerability

[N] = phase to insert after (must be an existing phase)
```

Validate that the after-phase number is an integer.

## Step 2: Validate

```bash
test -f .planning/ROADMAP.md && echo "OK" || echo "MISSING"
```

Check that phase `[N]` exists in ROADMAP.md:
```bash
grep -E "^## Phase [N]:" .planning/ROADMAP.md
```

If phase not found, list available phases and stop.

## Step 3: Calculate Decimal Number

Find existing decimal phases after phase `[N]`:
```bash
ls .planning/phases/ 2>/dev/null | grep -E "^[N]\." | sort -V
```

If none exist → new phase is `[N].1`
If `[N].1` exists → new phase is `[N].2`, etc.

Generate slug from description (lowercase, hyphens, max 40 chars).

## Step 4: Create Phase Directory

```bash
mkdir -p ".planning/phases/[N].[M]-[SLUG]"
```

## Step 5: Update ROADMAP.md

Insert the decimal phase entry immediately after Phase `[N]` in ROADMAP.md:

```markdown
## Phase [N].[M]: [Description] *(INSERTED — urgent)*

**Goal:** [One sentence — what this urgent work delivers]
**Status:** [ ] Not started
**Depends on:** Phase [N]
**Note:** Inserted between Phase [N] and Phase [N+1]

### Plans
*Not yet planned — run `plan-phase [N].[M]`*
```

## Step 6: Update STATE.md

Add to Roadmap Evolution section:
```markdown
- Phase [N].[M] inserted after Phase [N]: [description] (URGENT)
```

Note: Check if Phase [N+1] dependencies are still valid — the inserted phase may need to complete before [N+1] can run.

## Step 7: Commit

```bash
git add .planning/ROADMAP.md .planning/STATE.md ".planning/phases/[N].[M]-[SLUG]/"
git commit -m "chore(roadmap): insert urgent phase [N].[M] — [description]"
```

## Step 8: Confirm

```
Phase [N].[M] inserted after Phase [N]:

Description: [description]
Directory: .planning/phases/[N].[M]-[slug]/
Status: Not planned yet (URGENT)

⚠️  Check Phase [N+1] dependencies — does it still make sense to run after [N].[M]?

▶ Next: plan-phase [N].[M]
```
