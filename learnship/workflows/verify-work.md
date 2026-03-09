---
description: Manual user acceptance testing — walk through what was built, log issues, create fix plans
---

# Verify Work

Validate built features through conversational testing. Walk through each deliverable one at a time. You present what SHOULD happen — user confirms or describes what's different.

**Usage:** `verify-work [N]`

**Philosophy:** Show expected, ask if reality matches. No pass/fail buttons. No severity questions. Just: "Here's what should happen. Does it?"

## Step 1: Initialize

Check for existing UAT sessions:
```bash
find .planning/phases -name "*-UAT.md" -type f 2>/dev/null
```

**If active sessions exist and no phase number given:**

Read each file's frontmatter (status, phase) and current test.

Display:
```
## Active UAT Sessions

| # | Phase | Status | Current Test | Progress |
|---|-------|--------|--------------|----------|
| 1 | [phase] | testing | [test name] | [N/M] |

Reply with a number to resume, or provide a phase number to start new.
```

Wait for response. If number → resume that session. If phase number → start new session.

**If no sessions and no phase given:**
```
No active UAT sessions.

Provide a phase number to start testing (e.g., verify-work 4)
```

## Step 2: Find Deliverables

Read all SUMMARY.md files for the phase:
```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-SUMMARY.md 2>/dev/null
```

Extract testable deliverables from each SUMMARY.md — focus on **user-observable outcomes**, not implementation details:
- What features/functionality was added?
- What UI changes are visible?
- What workflows can a user now do?

Skip internal changes (refactors, type changes, test additions).

**Cold-start smoke test:** If any SUMMARY.md mentions server entry points, database files, migrations, or docker files — prepend a "Cold Start Smoke Test" as the first test:
```
Expected: Kill any running server. Clear ephemeral state. Start from scratch.
Server boots without errors, any seed/migration completes, primary query returns live data.
```

## Step 3: Create UAT File

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-UAT.md`:

```markdown
---
status: testing
phase: [padded_phase]-[phase_slug]
source: [list of SUMMARY.md files]
started: [ISO timestamp]
updated: [ISO timestamp]
---

## Current Test
number: 1
name: [first test name]
expected: |
  [what user should observe]
awaiting: user response

## Tests

### 1. [Test Name]
expected: [observable behavior]
result: pending

### 2. [Test Name]
expected: [observable behavior]
result: pending

...

## Summary

total: [N]
passed: 0
issues: 0
pending: [N]
skipped: 0

## Gaps

[none yet]
```

## Step 4: Present Tests One at a Time

For each test, display:

```
╔══════════════════════════════════════════════════════════════╗
║  UAT: Test [N] of [total]                                    ║
╚══════════════════════════════════════════════════════════════╝

**[Test Name]**

[Expected behavior — specific, observable, copy-pasteable commands or clear UI actions]

──────────────────────────────────────────────────────────────
→ Type "pass" or describe what's wrong
──────────────────────────────────────────────────────────────
```

Wait for plain text response (no multiple-choice).

## Step 5: Process Each Response

**If response indicates pass:** "yes", "y", "ok", "pass", "next", "approved", empty
→ Mark test: `result: pass`

**If response indicates skip:** "skip", "can't test", "n/a"
→ Mark test: `result: skipped`, capture reason

**If response is anything else:**
→ Treat as issue description. Infer severity from language:
- "crash", "error", "exception", "fails" → `blocker`
- "doesn't work", "wrong", "missing", "can't" → `major`
- "slow", "weird", "off", "minor" → `minor`
- "color", "font", "spacing", "alignment" → `cosmetic`
- Default: `major`

Mark test:
```
result: issue
reported: "[verbatim user response]"
severity: [inferred]
```

Append to Gaps section:
```yaml
- truth: "[expected behavior from test]"
  status: failed
  reason: "User reported: [verbatim response]"
  severity: [inferred]
  test: [N]
```

After each response: update Summary counts, update `updated` timestamp, write to UAT file, move to next test.

## Step 6: Complete Session

After all tests, update frontmatter: `status: complete`.

Commit:
```bash
git add ".planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-UAT.md"
git commit -m "test([padded_phase]): complete UAT - [N] passed, [M] issues"
```

Display summary:
```
## UAT Complete: Phase [X]

| Result  | Count |
|---------|-------|
| Passed  | [N]   |
| Issues  | [N]   |
| Skipped | [N]   |
```

**If no issues:** 
```
All tests passed. ✓

▶ Next: discuss-phase [X+1]
```

**If issues found:** Continue to Step 7.

## Step 7: Diagnose Issues

```
[N] issues found. Diagnosing root causes...
```

For each issue in the Gaps section, investigate using `@./agents/debugger.md` as your debug persona:
- Read the relevant source files
- Trace the issue to its root cause
- Do not fix yet — just diagnose

Update each gap in UAT.md with the root cause:
```yaml
- truth: "[expected]"
  status: failed
  reason: "User reported: [response]"
  severity: [severity]
  root_cause: "[What's actually broken and why]"
  affected_files: ["[file1]", "[file2]"]
```

## Step 8: Create Fix Plans

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PLANNING FIXES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Using `@./agents/planner.md` as your planning persona, read the UAT.md file with diagnosed gaps. Create fix plans in the phase directory with `gap_closure: true` in frontmatter.

Verify fix plans (max 3 iterations with `@./agents/verifier.md`) — same loop as `plan-phase`.

Present when ready:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► FIXES READY ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Phase [X]** — [N] gap(s) diagnosed, [M] fix plan(s) created

| Gap | Root Cause | Fix Plan |
|-----|------------|----------|
| [issue] | [root cause] | [plan file] |

▶ Next: execute-phase [X] (will run gap closure plans)
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer (after UAT passes with no issues):

> 💡 **Learning moment:** Tests passed — great time to schedule what you learned for future review.
>
> `@agentic-learning space` — Identifies concepts from this session and schedules them for spaced revisit. Writes to `docs/revisit.md`.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning space` to schedule concepts for spaced review."*
