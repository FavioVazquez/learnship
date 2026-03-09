---
description: Generate and add test coverage for a specific plan or phase post-execution
---

# Add Tests

Generate unit and E2E tests for a completed phase. Classifies each changed file into unit (TDD), browser (E2E), or skip categories, presents a test plan for approval, then writes tests following RED-GREEN conventions.

**Usage:** `add-tests [N]` or `add-tests [N] [additional instructions]`

## Step 1: Validate Phase

Phase number is required:
```
Usage: add-tests [N] [optional instructions]
Example: add-tests 3
Example: add-tests 3 focus on edge cases in the pricing module
```

Find the phase directory:
```bash
ls .planning/phases/ | grep -E "^0*[N]-" | head -1
PHASE_DIR=".planning/phases/[matched]"
```

Check that SUMMARY.md exists (phase must be executed):
```bash
ls "$PHASE_DIR"/*-SUMMARY.md 2>/dev/null
```

If no SUMMARY.md: stop — "Phase [N] hasn't been executed yet. Run `execute-phase [N]` first."

## Step 2: Read Phase Artifacts

Read in priority order:
1. All `*-SUMMARY.md` files — what was implemented, which files changed
2. `CONTEXT.md` — acceptance criteria and user decisions
3. `*-VERIFICATION.md` — user-verified scenarios (if UAT was done)

Extract the list of files modified by the phase from SUMMARY.md.

## Step 3: Detect Test Infrastructure

```bash
find . \( -name "jest.config.*" -o -name "vitest.config.*" -o -name "pytest.ini" -o -name "pyproject.toml" -o -name "playwright.config.*" \) -not -path "*/node_modules/*" 2>/dev/null

find . \( -name "*.test.*" -o -name "*.spec.*" -o -name "test_*.py" \) -not -path "*/node_modules/*" 2>/dev/null | head -10
```

Identify: test framework, E2E framework (if any), how to run tests, existing test file patterns and locations.

## Step 4: Classify Each File

For each file modified by the phase, classify into one of three categories:

**Unit (TDD)** — when the file contains:
- Business logic: calculations, pricing, tax, discounts
- Data transformations: mapping, filtering, aggregation, formatting
- Validators: input validation, schema validation, business rules
- State machines: status transitions, workflow steps
- Pure utilities: string manipulation, date handling, number formatting

**E2E (Browser)** — when the file produces:
- Keyboard shortcut behavior
- Navigation and routing
- Form interactions: submit, validation errors, focus
- Multi-step user flows
- Modal dialogs and overlays
- Data grids: sorting, filtering, inline editing

**Skip** — when the file is:
- UI layout/styling only (CSS, visual appearance)
- Configuration files, env vars, feature flags
- Glue code: DI setup, middleware registration, routing tables
- Database migrations or schema files
- Simple CRUD with no business logic
- Pure type definitions with no logic

Read each file to verify — don't classify by filename alone.

## Step 5: Present Classification

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► ADD TESTS — Phase [N]: [name]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Files classified for testing:

Unit Tests ([N] files):
- [file]: [reason — "contains pricing calculation logic"]
- [file]: [reason]

E2E Tests ([M] files):
- [file]: [reason — "login form with validation"]

Skipped ([K] files):
- [file]: [reason — "CSS-only, no logic"]

Proceed with this plan? (yes / adjust classification)
```

Wait for confirmation.

## Step 6: Generate Unit Tests

For each TDD file, write unit tests:

**File location:** Match the project's test file convention (e.g., `src/utils/__tests__/pricing.test.ts` or `tests/test_pricing.py`).

**Pattern:**
```
describe('[function/module name]', () => {
  it('[behavior description]', () => {
    // Arrange
    const input = [test input]
    // Act
    const result = [function call]
    // Assert
    expect(result).toBe([expected])
  })

  it('handles edge case: [edge case description]', () => {
    ...
  })
})
```

For each test file written:
- Cover the happy path
- Cover 2-3 edge cases (empty input, boundary values, error conditions)
- Apply any extra instructions provided

Run tests to verify they pass:
```bash
[test command] [test file path]
```

If tests fail: fix them (up to 3 attempts). If tests still fail after 3 attempts, note the blocker and skip that file.

## Step 7: Generate E2E Tests (if applicable)

If E2E framework exists (Playwright, Cypress, etc.), write E2E tests for classified files:

Match existing E2E test conventions in the project. Focus on user-visible behavior described in CONTEXT.md and VERIFICATION.md.

If no E2E framework exists: note it and skip E2E generation.

## Step 8: Commit Tests

Commit unit and E2E tests separately:

```bash
git add [unit test files]
git commit -m "test([padded_phase]): add unit tests for [brief description]"

git add [e2e test files]
git commit -m "test([padded_phase]): add E2E tests for [brief description]"
```

## Step 9: Report

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► TESTS ADDED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Unit tests: [N] files, [M] test cases
E2E tests: [K] files (or "none — no E2E framework detected")
Skipped: [J] files

[If any blockers:]
⚠️  [N] file(s) could not be tested: [reasons]

▶ Next: validate-phase [N] — map tests to requirements
        or: verify-work [N] — manual acceptance testing
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** Tests written. Test what you know about the behaviors you just covered:
>
> `@agentic-learning quiz [phase topic]` — Quiz yourself on the behaviors these tests encode. If you can't explain *why* each test case exists, the knowledge is fragile.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning quiz [topic]` to verify you understand what the tests are actually testing."*
