---
description: Batch-diagnose multiple UAT issues after verify-work — groups by root cause, proposes fix plan
---

# Diagnose Issues

Batch-diagnose all open UAT issues after `verify-work`. Groups issues by root cause, identifies shared fixes, and proposes a structured fix plan — more efficient than debugging issues one at a time.

**Usage:** `diagnose-issues [phase]`

**Run after:** `verify-work [N]` has logged issues in a UAT file.

## Step 1: Load Issues

Find the UAT file for the phase:
```bash
ls ".planning/phases/"*[N]*"/"*-UAT.md 2>/dev/null | head -1
```

If no UAT file found: stop — "Run `verify-work [N]` first to log issues."

Read the UAT file. Extract all open issues (status: open).

If no open issues:
```
No open issues in Phase [N] UAT. All issues are resolved or deferred.
```
Stop.

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DIAGNOSE ISSUES — Phase [N]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[N] open issue(s) to diagnose:
[list of issue titles and severities]
```

## Step 2: Read Phase Context

Read all PLAN.md and SUMMARY.md files for the phase to understand what was built and how:
```bash
cat ".planning/phases/[phase-dir]/"*-PLAN.md
cat ".planning/phases/[phase-dir]/"*-SUMMARY.md
```

Also read `.planning/DECISIONS.md` if it exists — prior decisions often explain why an issue occurred.

## Step 3: Diagnose Each Issue

For each open issue, using `@./agents/debugger.md` in diagnosis mode (read-only — no implementation changes):

1. **Trace the symptom** — follow the user-reported behavior inward through the codebase
2. **Find the divergence point** — the specific file:line where behavior diverges from expected
3. **Classify root cause:**
   - `implementation_bug` — code exists but is wrong
   - `missing_implementation` — code simply wasn't written
   - `integration_gap` — two components don't connect properly
   - `requirements_mismatch` — built correctly but wrong spec
   - `environment` — works in code but breaks in specific environment

Record for each issue:
```
Issue: [title]
Root cause type: [type]
Location: [file:line]
Cause: [one sentence]
Confidence: high | medium | low
```

## Step 4: Group by Root Cause

Look for shared root causes across issues — frequently multiple UAT issues trace back to the same source:

```
Root Cause Groups:

Group A: [common cause] → affects issues: [1, 3, 5]
  One fix here resolves all three.

Group B: [cause] → affects issue: [2]
  Standalone fix needed.

Group C: [cause] → affects issues: [4, 6]
  Shared component needs updating.
```

## Step 5: Propose Fix Plan

For each group, propose a minimal fix approach:

```
Proposed Fix Plan

**Fix 1: [group A description]**
Closes: Issues [1, 3, 5]
Approach: [1-2 sentences]
Files: [list]
Effort: small | medium | large

**Fix 2: [group B description]**
Closes: Issue [2]
Approach: [1-2 sentences]
Files: [list]
Effort: small | medium | large
```

Ask: "Does this diagnosis look right? Proceed with creating fix plans?"

## Step 6: Create Fix Plans

For each fix group, write a PLAN.md in the phase directory:

```bash
ls ".planning/phases/[phase-dir]/"*-PLAN.md | wc -l
# Next plan ID = existing count + 1
```

Write `[padded_phase]-[next-id]-FIX-PLAN.md` using the standard plan template format.

Update the UAT file — for each issue being addressed, add:
```yaml
fix_plan: [padded_phase]-[plan-id]-FIX-PLAN.md
```

## Step 7: Commit and Report

```bash
git add ".planning/phases/[phase-dir]/"
git commit -m "docs([padded_phase]): add fix plans for [N] UAT issues"
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DIAGNOSIS COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Issues diagnosed: [N]
Root cause groups: [M]
Fix plans created: [K]

▶ Next: execute-plan [phase] [plan-id]  (for each fix plan)
        or: execute-phase [phase]  (runs all remaining plans including fixes)
```
