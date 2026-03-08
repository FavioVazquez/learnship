---
description: Automatically determine and run the correct next workflow — true auto-pilot for the phase loop
---

# Next — Auto-Pilot

Reads project state and runs the right next workflow automatically. No need to remember command names — just type `/next` and go.

**Usage:** `/next`

---

## Step 1: Check for Project

```bash
test -f .planning/PROJECT.md && echo "EXISTS" || echo "MISSING"
```

**If MISSING:**

```
No project found. Starting /new-project...
```

Immediately run the `new-project` workflow. Stop here.

---

## Step 2: Load State

Read:

```bash
cat .planning/STATE.md
cat .planning/ROADMAP.md
```

Check for handoff:

```bash
find .planning/phases -name ".continue-here.md" 2>/dev/null
```

For current phase, count plans vs summaries:

```bash
ls ".planning/phases/[current_phase_dir]/"*-PLAN.md 2>/dev/null | wc -l
ls ".planning/phases/[current_phase_dir]/"*-SUMMARY.md 2>/dev/null | wc -l
```

Check for diagnosed UAT gaps:

```bash
grep -l "status: diagnosed" .planning/phases/[current_phase_dir]/*-UAT.md 2>/dev/null
```

---

## Step 3: Determine Next Action

Evaluate in order:

| Condition | Next workflow |
|-----------|---------------|
| `.continue-here.md` exists | `resume-work` |
| UAT gaps with `status: diagnosed` | `plan-phase [X]` (gap closure) |
| Plans exist, summaries < plans | `execute-phase [X]` |
| Plans = 0, CONTEXT.md exists | `plan-phase [X]` |
| Plans = 0, no CONTEXT.md | `discuss-phase [X]` |
| All summaries complete, more phases remain | `discuss-phase [X+1]` |
| All phases complete | `audit-milestone` |

---

## Step 4: Confirm and Run

Display one line explaining what you're about to do:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► NEXT
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[Project Name] — Phase [N]: [phase-name]
▶ About to run: [workflow-name] [args]
  Reason: [one sentence — e.g. "Plans are ready but 2 of 3 haven't been executed yet"]

Proceed? (yes / no)
```

If yes — run the workflow immediately.
If no — show `/ls` output so the user can choose manually.

---

## Notes

- `/next` always confirms before acting (never fully silent).
- For status-only with manual choice, use `/ls` instead.
- To see all available commands: `/help`
