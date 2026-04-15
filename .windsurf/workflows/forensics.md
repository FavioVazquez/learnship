---
description: Post-mortem investigation for failed or stuck workflows — read-only diagnostic report
---

# Forensics

Post-mortem investigation for failed or stuck workflows. Analyzes git history, `.planning/` artifacts, and file system state to detect anomalies and generate a structured diagnostic report.

**Usage:** `forensics` or `forensics [problem description]`

**Principle:** This is a read-only investigation. Do not modify project files. Only write the forensic report.

## Step 1: Get Problem Description

If a description was provided as an argument, use it. Otherwise ask:

> "What went wrong? Describe the issue."

Record the problem description for the report.

## Step 2: Gather Evidence

Collect data from all available sources. Missing sources are fine — adapt to what exists.

### 2a. Git History

```bash
git log --oneline -30
git log --format="%H %ai %s" -30
git log --name-only --format="" -20 | sort | uniq -c | sort -rn | head -20
git status --short
git diff --stat
```

Record:
- Commit timeline (dates, messages, frequency)
- Most-edited files (potential stuck-loop indicator)
- Uncommitted changes (potential crash/interruption indicator)

### 2b. Planning State

Read these files if they exist:
- `.planning/STATE.md` — current milestone, phase, progress, blockers
- `.planning/ROADMAP.md` — phase list with status
- `.planning/config.json` — workflow configuration

### 2c. Phase Artifacts

```bash
ls .planning/phases/*/
```

For each phase, check which artifacts exist (PLAN, SUMMARY, VERIFICATION, CONTEXT, RESEARCH, UAT). Track which phases have complete artifact sets vs gaps.

## Step 3: Analyze Anomalies

| Pattern | Indicates | Severity |
|---------|-----------|----------|
| Same file edited 5+ times in 20 commits | Stuck execution loop | High |
| PLAN.md exists but no SUMMARY.md | Execution interrupted | Medium |
| Large time gap between consecutive commits | Session interrupted or context exhausted | Medium |
| VERIFICATION.md with `gaps_found` | Phase incomplete | Medium |
| STATE.md references non-existent phase dir | State/filesystem mismatch | High |
| Uncommitted changes + old timestamps | Abandoned session | Low |

## Step 4: Determine Root Cause

| Category | Description | Recovery |
|----------|-------------|----------|
| **Execution stuck** | Agent looped on same files/tests | Re-run with `--wave` or fix trigger |
| **Context exhaustion** | Agent ran out of context mid-phase | Break into smaller plans, re-run |
| **Session interrupted** | Human or system terminated mid-work | Resume with `/resume-work` |
| **State mismatch** | STATE.md doesn't match filesystem | Manual STATE.md correction |
| **Plan deficiency** | Plans were wrong | Re-plan with `plan-phase --gaps` |
| **External failure** | API, dependency, or environment issue | Fix external issue, re-run |

## Step 5: Write Forensic Report

```bash
node -e "require('fs').mkdirSync('.planning/reports',{recursive:true})"
```

Write `.planning/reports/FORENSIC-[YYYY-MM-DD].md` with: evidence summary, anomalies detected, root cause (category + explanation + confidence), recommended recovery steps, and prevention advice.

Commit:
```bash
git add .planning/reports/
git commit -m "docs: forensic report"
```

## Step 6: Present Findings

```
learnship > FORENSIC REPORT COMPLETE

Root Cause: [category] — [one-line explanation]
Confidence: [high/medium/low]

Recovery:
1. [action]
2. [action]

Report: .planning/reports/FORENSIC-[date].md
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:**

> **Learning moment:** Failures are high-signal learning opportunities:
>
> `@agentic-learning reflect` — What pattern caused this failure? What would you watch for next time? Structured reflection on failures builds diagnostic intuition.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning reflect` to extract lessons from this failure."*
