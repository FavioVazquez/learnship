---
description: Retroactive test coverage audit for a completed phase — fill validation gaps without modifying implementation
---

# Validate Phase

Retroactively audit and fill test coverage gaps for a completed phase. Useful after hotfixes, for phases executed before test infrastructure was set up, or when `audit-milestone` surfaces validation gaps.

**Usage:** `validate-phase [N]`

**Rule:** Never modifies implementation files — only writes test files and updates VALIDATION.md.

## Step 1: Check Config

Read `.planning/config.json`:
```bash
cat .planning/config.json | grep "nyquist_validation"
```

If `nyquist_validation: false`: stop — "Validation is disabled. Enable it in `/settings` to use this workflow."

## Step 2: Validate Phase

```bash
test -f .planning/ROADMAP.md && grep -E "Phase [N]:" .planning/ROADMAP.md
```

Determine the phase directory:
```bash
ls .planning/phases/ | grep -E "^0*[N]-"
PHASE_DIR=".planning/phases/[matched dir]"
```

## Step 3: Detect State

Check what exists:
```bash
ls "$PHASE_DIR"/*.md 2>/dev/null
```

- **State A** — VALIDATION.md exists: run audit on existing file, fill gaps
- **State B** — SUMMARY.md exists, no VALIDATION.md: build validation from execution artifacts
- **State C** — no SUMMARY.md: phase not executed yet — stop: "Run `execute-phase [N]` first."

## Step 4: Read Phase Artifacts

Read all PLAN.md and SUMMARY.md files for phase `[N]`:
```bash
cat "$PHASE_DIR"/*-PLAN.md
cat "$PHASE_DIR"/*-SUMMARY.md
```

Extract:
- Task names and `<verify>` commands
- Requirement IDs covered by each task
- Key files created or modified

## Step 5: Detect Test Infrastructure

```bash
find . \( -name "jest.config.*" -o -name "vitest.config.*" -o -name "pytest.ini" -o -name "pyproject.toml" \) -not -path "*/node_modules/*" 2>/dev/null

find . \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \) -not -path "*/node_modules/*" 2>/dev/null | head -20
```

Identify: test framework, how to run tests, existing test file patterns.

## Step 6: Map Requirements to Tests

For each requirement ID assigned to this phase:

1. Look for existing tests that cover this behavior (by filename, describe block, test name)
2. Classify:
   - **COVERED** — test exists, targets the behavior, runs green
   - **PARTIAL** — test exists but incomplete or failing
   - **MISSING** — no test found

If no gaps (all COVERED): proceed directly to step 8 with `nyquist_compliant: true`.

## Step 7: Present Gap Plan and Fill

Show gap table:
```
Phase [N] Validation Gaps

| Requirement | Status | Suggested test |
|-------------|--------|----------------|
| REQ-AUTH-01 | MISSING | src/__tests__/auth.test.ts |
| REQ-DASH-02 | PARTIAL | src/__tests__/dashboard.test.ts |

Options:
1. Fill all gaps — I'll write the missing tests
2. Mark as manual-only — skip automation, verify manually
3. Cancel
```

Wait for choice.

**If "Fill all gaps":** Write the missing test files. Rules:
- Never touch implementation files
- Match the existing test framework and style
- Write tests that actually run (import real modules, not mocks of the implementation)
- If a test reveals an implementation bug, log it as an escalation — don't fix the implementation

Run tests to verify they pass:
```bash
[test command for framework] [test file]
```

Up to 3 debug attempts if tests fail. If still failing after 3, move to manual-only and note why.

## Step 8: Write/Update VALIDATION.md

**State B (create new):**

Write `$PHASE_DIR/[padded_phase]-VALIDATION.md`:

```markdown
---
nyquist_compliant: true | false
wave_0_complete: true | false
phase: [N]
validated: [date]
---

# Phase [N] Validation

## Test Infrastructure
| Tool | Version | Run command |
|------|---------|-------------|
| [framework] | [version] | [command] |

## Per-Requirement Coverage

| Requirement | Task | Test file | Status |
|-------------|------|-----------|--------|
| REQ-XX-01 | [task name] | [test file path] | ✓ automated |

## Manual-Only Items
[Items that require a running app to verify]

## Audit Trail
Validated: [date] — [N] covered, [M] manual-only
```

**State A (update existing):**

Update the Per-Requirement Coverage table, add resolved gaps, move escalated items to Manual-Only. Append audit trail entry.

## Step 9: Commit

```bash
git add [test files]
git commit -m "test([padded_phase]): add validation tests"

git add "$PHASE_DIR/[padded_phase]-VALIDATION.md"
git commit -m "docs([padded_phase]): update validation strategy"
```

## Step 10: Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PHASE [N] VALIDATED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[N] requirements automated ✓
[M] requirements manual-only
[K] escalated (implementation bugs found — see VALIDATION.md)

Status: COMPLIANT | PARTIAL

▶ Next: audit-milestone
```
