---
description: Manual user acceptance testing — walk through what was built, log issues, create fix plans
---

# Verify Work

Validate built features through conversational testing. Walk through each deliverable one at a time. You present what SHOULD happen — user confirms or describes what's different.

**Usage:** `verify-work [N]`

**Philosophy:** Show expected, ask if reality matches. No pass/fail buttons. No severity questions. Just: "Here's what should happen. Does it?"

<core_principle>
**Task completion ≠ Goal achievement**

A task "create chat component" can be marked complete when the component is a placeholder. The task was done — but the goal "working chat interface" was not achieved.

Goal-backward verification:
1. What must be TRUE for the goal to be achieved?
2. What must EXIST for those truths to hold?
3. What must be WIRED for those artifacts to function?
4. What must TESTS PROVE for those truths to be evidenced?

Then verify each level against the actual codebase.
</core_principle>

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

## Step 2: Extract Must-Haves

First, extract must-haves from plan frontmatter:
```bash
for plan in .planning/phases/[padded_phase]-[phase_slug]/*-PLAN.md; do
  echo "=== $plan ==="
  head -30 "$plan"
done
```

Look for `must_haves` in each plan's frontmatter — these are the primary verification targets. If plans have must_haves, use them as the backbone of the test list.

Also check ROADMAP.md for Success Criteria for this phase — these override plan-level must_haves when both exist.

## Step 2b: Find Deliverables

Read all SUMMARY.md files for the phase:
```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-SUMMARY.md 2>/dev/null
```

Extract testable deliverables from each SUMMARY.md — focus on **user-observable outcomes**, not implementation details:
- What features/functionality was added?
- What UI changes are visible?
- What workflows can a user now do?

Skip internal changes (refactors, type changes, test additions).

**Stub detection:** Before presenting tests, do a quick scan for placeholder code using patterns from `@./references/verification-patterns.md` (if it exists). Flag any files that look like stubs — these should be tested more carefully.

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

Read `review.auto_after_verify` from `.planning/config.json` (defaults to `false`).

**If `review.auto_after_verify` is `true`:**
```
All tests passed. ✓

Auto-review is enabled — starting multi-persona code review now.
```
Immediately run the `review` workflow for this phase's changes.

**If `review.auto_after_verify` is `false`:**
```
All tests passed. ✓

▶ Recommended next steps:
  `/review`            — multi-persona code review (6 lenses)
  `/secure-phase [X]`  — STRIDE security verification for this phase
  `/ship`              — test → lint → commit → push → PR
  `/compound`          — capture notable solutions or patterns while context is fresh
  `/extract-learnings [X]` — capture decisions, lessons, patterns, surprises

▶ Or continue: discuss-phase [X+1]
```

**If issues found:** Continue to Step 7.

## Step 7: Diagnose Issues

```
[N] issues found. Diagnosing root causes...
```

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization.enabled` is `true` (subagent mode — Claude Code, OpenCode, Codex):**

Spawn a dedicated debugger agent for diagnosis:
```
Task(
  subagent_type="learnship-debugger",
  description="Diagnose UAT issues phase [N]",
  prompt="
    <agent_definition>
    You are a learnship debugger in diagnosis mode. Trace each issue to its root cause.
    Read-first: understand the current design before proposing changes. Find specific files and lines.
    Do NOT fix anything — just diagnose and document. One hypothesis at a time.
    </agent_definition>

    <objective>
    Diagnose all issues found in UAT for phase [N].
    Read the UAT.md file with gaps, trace each issue to its root cause.
    Do NOT fix anything — just diagnose and document root causes.
    Write root_cause and affected_files for each gap back to UAT.md.
    </objective>

    <files_to_read>
    - [UAT.md path]
    </files_to_read>
  "
)
```

**If `parallelization.enabled` is `false` (sequential mode):**

<persona_context>
You are now the **learnship debugger**. Diagnose the root cause of each gap.
One variable at a time. Reproduce before diagnosing. Trace from symptom to root cause.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[38;5;208m  learnship-debugger(Diagnose the root cause of each gap)\033[0m\n\n"
> ```

Read `@./agents/debugger.md` for the full persona definition. For each issue in the Gaps section, investigate:
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

<persona_context>
You are now the **learnship planner**. Create fix plans for diagnosed gaps.
Each plan covers one logical unit of work. Include gap_closure: true in frontmatter.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[32m  learnship-planner(Create fix plans for diagnosed gaps)\033[0m\n\n"
> ```

Read `@./agents/planner.md` for the full persona definition. Read the UAT.md file with diagnosed gaps. Create fix plans in the phase directory with `gap_closure: true` in frontmatter.

<persona_context>
You are now the **learnship verifier**. Verify fix plans close the diagnosed gaps.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[35m  learnship-verifier(Verify fix plans close the diagnosed gaps)\033[0m\n\n"
> ```

Verify fix plans (max 3 iterations — read `@./agents/verifier.md` for the full persona definition) — same loop as `plan-phase`.

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

**If `auto` and UAT passed with no issues:**

> 💡 **Learning moment:** Tests passed — lock in what was learned before moving on:
>
> `@agentic-learning space` — Identifies concepts from this phase and schedules them for spaced revisit. Writes to `docs/revisit.md`. The next phase starts with less decay.
>
> `@agentic-learning quiz [phase topic]` — Quick active recall while the implementation is still fresh. Better now than two phases later.

**If `auto` and issues were found and fixed:**

> 💡 **Learning moment:** Bugs found during UAT are high-signal learning. Don’t just fix and move on:
>
> `@agentic-learning learn [bug domain]` — Active retrieval on the concept that caused the issue. Turns a frustrating bug into a lasting pattern.
>
> `@agentic-learning space` — Schedule the key concepts from this debugging session for spaced review.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning space` · `@agentic-learning quiz [topic]` to consolidate this phase."*
