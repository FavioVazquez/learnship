---
title: Recovery
description: "When things go wrong: forensics post-mortem and safe undo."
---

# Recovery

When workflows fail, execution gets stuck, or commits need reverting — these workflows provide structured recovery without losing work.

![Recovery workflows](../assets/recovery-workflows.png)

**New in v2.1.0.**

---

## `/forensics`

Post-mortem investigation for failed or stuck workflows. Read-only — never modifies project files.

```bash
/forensics                          # interactive — asks what went wrong
/forensics "phase 3 got stuck"      # with problem description
```

**What it does:**

1. Gathers evidence from git history, `.planning/` artifacts, and file system state
2. Analyzes anomalies (stuck loops, missing summaries, state mismatches)
3. Determines root cause (execution stuck, context exhaustion, plan deficiency, etc.)
4. Writes a structured forensic report to `.planning/reports/`

**Root cause categories:**

| Category | Description | Recovery |
|----------|-------------|----------|
| Execution stuck | Agent looped on same files | Re-run with `--wave` or fix trigger |
| Context exhaustion | Agent ran out of context | Break into smaller plans |
| Session interrupted | Human/system terminated | `/resume-work` |
| State mismatch | STATE.md doesn't match filesystem | Manual correction |
| Plan deficiency | Plans were wrong | `plan-phase --gaps` |
| External failure | API/dependency issue | Fix external, re-run |

**Output:** `.planning/reports/FORENSIC-[date].md`

**Learning checkpoint:** `reflect`

---

## `/undo`

Safe git revert for phase or plan commits. Uses `git revert` (NEVER `git reset`) to preserve history.

```bash
/undo --last 5              # show last 5 commits, select which to revert
/undo --phase 03            # revert all commits for phase 03
/undo --plan 03-02          # revert all commits for plan 03-02
```

**What it does:**

1. Gathers candidate commits based on mode
2. Checks for downstream dependencies (warns if later commits touch the same files)
3. Shows confirmation gate with revert plan
4. Executes `git revert --no-commit` for each commit
5. Creates a single revert commit preserving full history

**Safety features:**

- Dependency checking before reverting
- Confirmation gate — never auto-reverts
- Preserves git history — reverts are traceable
- Updates STATE.md with revert log

**Learning checkpoint:** `either-or` — what led to needing the undo?
