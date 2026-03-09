---
description: Show project progress, current position, and what to do next
---

# Progress

Check where you are in the project, what's been done, and what comes next.

## Step 1: Check for Planning Structure

```bash
test -f .planning/PROJECT.md && echo "EXISTS" || echo "MISSING"
```

If `.planning/` doesn't exist: stop — run `new-project` to initialize.

## Step 2: Load Context

Read the key state files:
```bash
cat .planning/STATE.md
cat .planning/ROADMAP.md
```

Find the 2-3 most recent SUMMARY.md files:
```bash
find .planning -name "*-SUMMARY.md" -type f 2>/dev/null | xargs ls -t 2>/dev/null | head -3
```

Read each to extract what was recently accomplished (one-liner per plan).

## Step 3: Analyze Phase Status

For the current phase directory, count:
```bash
ls ".planning/phases/[current_phase_dir]/"*-PLAN.md 2>/dev/null | wc -l
ls ".planning/phases/[current_phase_dir]/"*-SUMMARY.md 2>/dev/null | wc -l
ls ".planning/phases/[current_phase_dir]/"*-UAT.md 2>/dev/null | wc -l
```

Check for UAT files with gaps (issues found during testing):
```bash
grep -l "status: diagnosed" .planning/phases/[current_phase_dir]/*-UAT.md 2>/dev/null
```

Check for a `.continue-here.md` handoff file:
```bash
find .planning/phases -name ".continue-here.md" 2>/dev/null
```

## Step 4: Report Status

Calculate overall progress: count completed phases / total phases.

Display:
```
# [Project Name]

**Progress:** [████████░░] [X]% — Phase [N] of [total]

## Recent Work
- [Phase, Plan]: [what was accomplished — 1 line]
- [Phase, Plan]: [what was accomplished — 1 line]

## Current Position
Phase [N] of [total]: [phase-name]
Status: [planned | in-progress | complete]
Context: [✓ CONTEXT.md exists | — not yet]

## Key Decisions
- [Key decision from STATE.md]

## Blockers / Concerns
- [Any blockers from STATE.md, or "None"]
```

## Step 5: Route to Next Action

**Check conditions in order:**

1. **`.continue-here.md` exists** → mid-plan handoff found
   ```
   ⚠️  Handoff detected: .planning/phases/[phase]/.continue-here.md
   ▶ Next: resume-work
   ```

2. **UAT gaps exist (status: diagnosed)** → fix plans needed
   ```
   ⚠️  UAT Gaps Found in Phase [X]
   ▶ Next: plan-phase [X] (gap closure mode)
   ```

3. **Plans exist but summaries < plans** → unfinished execution
   ```
   ## ▶ Next Up
   **Phase [X]-[plan]: [Plan Name]** — [objective]
   ▶ Next: execute-phase [X]
   ```

4. **Plans = 0** → phase not yet planned
   - If CONTEXT.md exists: `▶ Next: plan-phase [X]`
   - If no CONTEXT.md: `▶ Next: discuss-phase [X]` (recommended) or `plan-phase [X]`

5. **Summaries = plans AND plans > 0** → phase complete
   - If more phases remain: `▶ Next: discuss-phase [X+1]`
   - If all phases done: `▶ Next: audit-milestone`

After presenting the recommended next step, ask:

```
▶ Next: [workflow-name] [args if any]

  Run it now? Type "yes" to proceed, or just keep chatting.
```

If the user responds with "yes", "go", "do it", "run it", or "proceed" — immediately invoke that workflow.

For full auto-pilot with no prompt, use `/next` instead.
