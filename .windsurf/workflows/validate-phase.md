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
cat .planning/config.json | grep "validation"
```

If `validation: false`: stop — "Validation is disabled. Enable it in `/settings` to use this workflow."

## Step 2: Validate Phase

```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning/ROADMAP.md') ? 'OK' : 'MISSING')"
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
# PowerShell: Get-ChildItem -Recurse | Where-Object { $_.Name -match '\.test\.|spec\.|^test_.*\.py' -and $_.FullName -notmatch 'node_modules' } | Select-Object -First 20
```

Identify: test framework, how to run tests, existing test file patterns.

## Step 6: Map Requirements to Tests

For each requirement ID assigned to this phase:

1. Look for existing tests that cover this behavior (by filename, describe block, test name)
2. Classify:
   - **COVERED** — test exists, targets the behavior, runs green
   - **PARTIAL** — test exists but incomplete or failing
   - **MISSING** — no test found

If no gaps (all COVERED): proceed directly to step 8 with `compliant: true`.

## Step 7: Present Gap Plan and Fill

Show the gap table, then present a structured question:

```
ask_user_question([
  {
    header: "Validation Gaps",
    question: "[N] gap(s) found. How do you want to handle them?",
    multiSelect: false,
    options: [
      { label: "Fill all gaps", description: "I'll write the missing tests automatically" },
      { label: "Manual-only", description: "Skip automation, verify these manually" },
      { label: "Cancel", description: "Stop validation — no changes" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

**If "Fill all gaps":**

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization.enabled` is `true` (subagent mode):**
```
Task(
  subagent_type="learnship-verifier",
  description="Fill validation gaps phase [N]",
  prompt="
    <agent_definition>
    You are a learnship verifier. Write test files that cover validation gaps — never modify implementation files.
    Match existing test framework and style. Write tests that actually run (import real modules, not mocks).
    If a test reveals an implementation bug, log it as an escalation — don't fix the implementation.
    Up to 3 debug attempts if tests fail.
    </agent_definition>

    <objective>
    Write missing test files for phase [N] validation gaps.
    Read VALIDATION.md gaps and write tests that cover each MISSING or PARTIAL requirement.
    Never modify implementation files — only write test files.
    Run tests to verify they pass. Up to 3 debug attempts if tests fail.
    </objective>

    <files_to_read>
    - [VALIDATION.md path]
    </files_to_read>
  "
)
```

**If `parallelization.enabled` is `false` (sequential mode):**

<persona_context>
You are now the **learnship verifier**. Write missing test files to close validation gaps.
Tests must be observable and runnable. Cover the must_haves from each plan. Don't weaken existing tests.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[35m  learnship-verifier(Write missing test files to close validation gaps)\033[0m\n\n"
> ```

Read `@./agents/verifier.md` for the full persona definition. Write the missing test files. Rules:
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
compliant: true | false
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
