---
description: Verify milestone met its definition of done — requirement coverage, integration check, stub detection
---

# Audit Milestone

Pre-release audit that aggregates phase verifications, checks cross-phase integration, validates requirement coverage, and detects stubs/placeholders. Run before `/complete-milestone`.

**Use when:** All phases are complete and you want to verify the milestone is actually done before archiving.

## Step 1: Determine Milestone Scope

Read `.planning/ROADMAP.md` and `.planning/REQUIREMENTS.md`.

Find all phases in the current milestone (all phases in ROADMAP.md that aren't in a completed milestone archive).

Display:
```
Auditing milestone: [VERSION] [Name]
Phases in scope: [list of phase numbers and names]
Requirements in scope: [N] requirements ([list of REQ-IDs])
```

## Step 2: Read All Phase Verifications

For each phase directory, read its VERIFICATION.md:
```bash
for phase_dir in .planning/phases/*/; do
  cat "${phase_dir}"*-VERIFICATION.md 2>/dev/null
done
```

From each VERIFICATION.md, extract:
- **Status:** `passed` | `gaps_found` | `human_needed`
- **Gaps:** any items that failed
- **Requirements coverage table:** which REQ-IDs were verified

**If any phase is missing VERIFICATION.md:** flag as `unverified` — this is a blocker.

## Step 3: Check Requirements Coverage

Cross-reference three sources for each requirement:

**Source A — REQUIREMENTS.md traceability:**
```bash
grep -E "^\|.*REQ-" .planning/REQUIREMENTS.md
```

**Source B — Phase VERIFICATION.md tables:**
Extract per-requirement status from each phase's verification file.

**Source C — Phase SUMMARY.md:**
Check each SUMMARY.md for requirements-completed notes.

For each REQ-ID, determine status:

| VERIFICATION status | SUMMARY mentions it | REQUIREMENTS checkbox | → Audit status |
|--------------------|--------------------|----------------------|----------------|
| passed | yes | `[x]` | **satisfied** |
| passed | yes | `[ ]` | **satisfied** (fix checkbox) |
| gaps_found | any | any | **unsatisfied** |
| missing | any | any | **unsatisfied** |

Any `unsatisfied` requirement = milestone audit `gaps_found`.

**Orphan detection:** Requirements in REQUIREMENTS.md that appear in no phase VERIFICATION.md → flag as `orphaned` (treated as unsatisfied).

## Step 4: Cross-Phase Integration Check

Using `@./agents/verifier.md` in integration mode, check cross-phase wiring:

Read all SUMMARY.md files to understand what each phase exported (APIs, components, utilities).

Check:
1. **Import chains:** Do modules that claim to export X actually export it? Do modules that import X use the correct path and signature?
2. **API contracts:** Do API routes match what the UI calls? Are response shapes consistent?
3. **E2E user flows:** Pick the 3-5 most important user journeys. Trace each through the codebase — does every step have a real implementation?
4. **Stub detection:** Scan for `// TODO`, `// FIXME`, placeholder strings, `return null`/`return undefined` in non-trivial functions, empty bodies.

```bash
grep -rn "TODO\|FIXME\|PLACEHOLDER\|return null\|return undefined" src/ --include="*.ts" --include="*.tsx" --include="*.js" 2>/dev/null | grep -v "node_modules\|\.test\." | head -30
```

## Step 5: Compile Audit Report

Write `.planning/[VERSION]-MILESTONE-AUDIT.md`:

```markdown
---
status: passed | gaps_found
milestone: [VERSION]
audited: [date]
gaps:
  requirements: [list of unsatisfied REQ-IDs]
  integration: [list of broken cross-phase connections]
  flows: [list of broken E2E flows]
  stubs: [list of stub locations]
---

# Milestone Audit: [VERSION] [Name]

## Requirements Coverage

| REQ-ID | Description | Phase | Status |
|--------|-------------|-------|--------|
| AUTH-01 | [description] | 02 | ✓ satisfied |
| DASH-01 | [description] | 03 | ✗ unsatisfied |

**Total:** [X]/[Y] requirements satisfied

## Phase Verification Summary

| Phase | Status | Notes |
|-------|--------|-------|
| 01 — [Name] | ✓ passed | |
| 02 — [Name] | ✗ gaps_found | [gap summary] |

## Integration Findings

### Cross-Phase Wiring
[What's connected correctly, what's broken]

### E2E Flows
[Which flows work, which are broken and where]

## Stubs Found

[List of TODO/FIXME/placeholder locations, or "None found"]

## Verdict

[PASSED — all requirements satisfied, no critical gaps]
OR
[GAPS FOUND — N requirements unsatisfied, M integration issues]
```

## Step 6: Present Audit Results

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► MILESTONE AUDIT [VERSION]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Requirements: [X]/[Y] satisfied
Integration: [passed | N issues found]
Stubs: [none | N found]

Status: [PASSED ✓ | GAPS FOUND ⚠️]
```

**If PASSED:**
```
Milestone [VERSION] is ready to ship.

▶ Next: complete-milestone
```

**If GAPS FOUND:**
```
[N] gap(s) require attention before release:

[List gaps]

▶ Next: plan-milestone-gaps — create fix phases for all gaps
    OR: complete-milestone — ship anyway (mark gaps as known issues)
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** Audit complete. Before planning fixes:
>
> `@agentic-learning reflect` — What were the gap patterns? Were they requirements misses, integration oversights, or execution stubs? Understanding *why* gaps happened improves the next milestone.
