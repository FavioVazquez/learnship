---
description: Restore full project context and continue from where you left off — use when returning after a break, or when you say "continue", "where were we", "pick up where we left off", or "what were we doing"
---

# Resume Work

Instantly restore full project context. Use when starting a new session, returning after time away, or when you said "continue" or "where were we."

## Step 1: Check Planning Structure

```bash
test -f .planning/STATE.md && echo "HAS_STATE" || echo "NO_STATE"
test -f .planning/PROJECT.md && echo "HAS_PROJECT" || echo "NO_PROJECT"
test -f .planning/ROADMAP.md && echo "HAS_ROADMAP" || echo "NO_ROADMAP"
```

If nothing exists: stop — run `new-project` to start a project.

If STATE.md missing but PROJECT.md + ROADMAP.md exist: reconstruct STATE.md (see Reconstruction section below).

## Step 2: Load State

```bash
cat .planning/STATE.md
cat .planning/PROJECT.md
```

Extract:
- **What we're building:** core value and current focus from PROJECT.md
- **Current position:** Phase X of Y, Plan A of B, status
- **Recent decisions:** key decisions affecting current work
- **Blockers/concerns:** issues carried forward
- **Last activity:** when and what

## Step 3: Check for Incomplete Work

```bash
# Check for continue-here handoff files
find .planning/phases -name ".continue-here.md" -type f 2>/dev/null

# Check for plans without matching summaries (incomplete execution)
for plan in .planning/phases/*/*-PLAN.md; do
  base="${plan%-PLAN.md}"
  summary="${base}-SUMMARY.md"
  [ ! -f "$summary" ] && echo "Incomplete: $plan"
done 2>/dev/null
```

## Step 4: Present Status

```
╔══════════════════════════════════════════════════════════════╗
║  PROJECT STATUS                                               ║
╠══════════════════════════════════════════════════════════════╣
║  Building: [one-liner from PROJECT.md]                        ║
║                                                               ║
║  Phase: [X] of [Y] — [Phase name]                            ║
║  Plan:  [A] of [B] — [Status]                                 ║
║  Progress: [████████░░] [N]%                                 ║
║                                                               ║
║  Last activity: [date] — [what happened]                     ║
╚══════════════════════════════════════════════════════════════╝
```

If `.continue-here.md` found:
```
⚠️  Mid-plan handoff detected:
    File: .planning/phases/[phase]/.continue-here.md
    Task: [X] of [Y]
    [brief description of where we left off]
```

If incomplete plan (PLAN without SUMMARY):
```
⚠️  Incomplete execution:
    Plan: [plan file]
    Execution started but no SUMMARY found.
```

If blockers exist:
```
⚠️  Carried concerns:
    - [blocker]
```

## Step 5: Determine Next Action

**Priority order:**

1. **`.continue-here.md` exists** → read it fully, resume from `<next_action>`
   - Display: "Resuming from: [next_action from file]"
   - Delete the continue file after loading: `rm .planning/phases/[phase]/.continue-here.md`
   - Commit the deletion: `git add -A && git commit -m "chore: consume resume handoff"`

2. **Incomplete plan (PLAN without SUMMARY)** → offer to continue execution
   - Primary: `execute-phase [X]`
   - Secondary: Review the plan first

3. **Current phase ready to execute (plans exist)** → `execute-phase [X]`

4. **Current phase needs planning** → check for CONTEXT.md
   - CONTEXT.md exists: `plan-phase [X]`
   - No CONTEXT.md: `discuss-phase [X]` (recommended)

5. **Current phase done, next phase up** → `discuss-phase [X+1]`

6. **All phases done** → `complete-milestone`

Present the primary recommended action clearly:
```
▶ Recommended next step: [workflow name] [phase number if applicable]

Also available:
- progress — full status overview
- [other relevant options]
```

## Step 6: Update Session Continuity

Update STATE.md session section:
```markdown
## Session Continuity

Last session: [now]
Stopped at: Session resumed
```

```bash
git add .planning/STATE.md
git commit -m "docs(state): session resumed"
```

---

## Reconstruction (when STATE.md is missing)

If STATE.md is missing but other artifacts exist:

"STATE.md missing. Reconstructing from artifacts..."

1. Read `PROJECT.md` → extract "What This Is" and Core Value
2. Read `ROADMAP.md` → find all phases, identify current position (last phase with incomplete work)
3. Scan `*-SUMMARY.md` files → extract decisions and concerns
4. Check for `.continue-here.md` files → session continuity

Write a reconstructed `.planning/STATE.md` and proceed normally.

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto` and time since last session is more than 1 day (check `Last session` in STATE.md):**

> 💡 **Back after a break:** Before diving in, warm up the mental model:
>
> `@agentic-learning quiz [current phase topic]` — Quick active recall on what was being built. Surfaces what’s faded since the last session before it shows up as a bug.
>
> `@agentic-learning space` — If `docs/revisit.md` exists, review what was scheduled for today.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning quiz [topic]` to warm up before resuming."*
