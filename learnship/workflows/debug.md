---
description: Systematic debugging with persistent state — triage, diagnose root cause, plan fix, execute
---

# Debug

Systematic debugging workflow: triage → root cause diagnosis → fix planning → execution. Creates a persistent debug session file so context survives across context resets.

**Usage:** `debug [description]`

## Step 1: Create Debug Session

```bash
mkdir -p .planning/debug
DATE=$(date +%Y%m%d-%H%M)
```

Generate a slug from the description (lowercase, hyphens). Create session file:
```
.planning/debug/[DATE]-[SLUG].md
```

Write initial session header:
```markdown
---
status: open
opened: [datetime]
description: [description]
---

# Debug: [description]

## Session Log
```

## Step 2: Triage

Ask: **"What is the exact symptom?"**

If description was provided as an argument, use it as starting context. Then ask follow-up questions one at a time:

1. "When does this happen? Always, sometimes, or only under specific conditions?"
2. "What did you expect to happen?"
3. "When did it start? Was it working before? What changed?"
4. "What have you already tried?"

After gathering answers, write a triage summary to the session file:
```markdown
## Triage

**Symptom:** [exact description]
**Expected:** [what should happen]
**Frequency:** [always/intermittent/condition-specific]
**Regression:** [when it started, what changed]
**Already tried:** [list]
```

## Step 3: Form Hypotheses

Based on the symptom and triage, generate 2-4 candidate root causes ranked by likelihood:

```
Hypotheses (ranked by likelihood):

1. [Most likely]: [explanation of why this would cause the symptom]
2. [Second]: [explanation]
3. [Third]: [explanation]
```

Ask: "Does any of these match what you're seeing? Or should I investigate a different direction?"

## Step 4: Investigate

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization` is `true` (subagent mode — Claude Code, OpenCode, Codex):**

Spawn a dedicated debugger agent with a fresh context budget for deep investigation:
```
Task(
  subagent_type="learnship-debugger",
  prompt="
    <objective>
    Investigate the bug described in [session_file].
    Trace from the user-facing symptom inward to find the root cause.
    Find the specific file and line where behavior diverges from expected.
    Confirm: 'If this were fixed, would the symptom go away?'
    Write investigation findings back to [session_file].
    </objective>

    <files_to_read>
    - [session_file] (debug session with triage + hypotheses)
    - ./AGENTS.md or ./CLAUDE.md or ./GEMINI.md (project context, whichever exists)
    </files_to_read>
  "
)
```

Wait for agent to complete, then read the updated session file.

**If `parallelization` is `false` (sequential mode):**

Using `@./agents/debugger.md` as your investigation persona:

For the most likely hypothesis, investigate the codebase (read-only):
- Trace from the user-facing symptom inward toward the root cause
- Find the specific file and line where behavior diverges from expected
- Confirm: "If this were fixed, would the symptom go away?"

Update session file with investigation notes:
```markdown
## Investigation

### Hypothesis [N]: [description]
**Files checked:** [list]
**Finding:** [what was found]
**Root cause:** [specific file:line and why it causes the symptom]
**Confidence:** high | medium | low
```

If hypothesis disproved: move to next hypothesis. If all hypotheses disproved: surface new ones based on what was found.

## Step 5: Diagnose

Present root cause diagnosis:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 DEBUG ► ROOT CAUSE FOUND
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Root cause: [specific description]
Location: [file:line]
Why: [how this causes the symptom]
Confidence: high | medium | low
```

Write to session file:
```markdown
## Root Cause

**Location:** [file:line]
**Cause:** [description]
**Why it produces the symptom:** [explanation]
**Confidence:** high | medium | low
```

If confidence is low: explain what additional information would help confirm.

## Step 6: Plan the Fix

Propose a minimal fix:

```
Fix approach: [1-3 sentences describing the change]
Files to modify:
- [file]: [what to change]

Risk: [any side effects or things to watch out for]
```

Ask: "Does this approach look right? Should I implement it, or do you want to adjust?"

## Step 7: Implement Fix

Once confirmed, implement the fix using the executor approach from `@./agents/executor.md`:
- Make only the changes needed to fix the root cause
- No scope creep — don't fix other things while you're in there
- Commit atomically:

```bash
git add [files changed]
git commit -m "fix([scope]): [description of what was fixed]"
```

## Step 8: Verify Fix

Test the fix against the original symptom:
```bash
[run the verify command from the relevant plan, or run tests]
```

Ask: "Does this fix the problem?"

## Step 9: Close Session

Update session file:
```markdown
## Resolution

**Fix applied:** [description]
**Commit:** [hash]
**Verified:** [yes/no — how verified]
**Status:** resolved | partial | unresolved
```

Move to resolved:
```bash
mkdir -p .planning/debug/resolved
mv ".planning/debug/[session-file]" ".planning/debug/resolved/"
```

## Step 9b: Update AGENTS.md Regressions

If `AGENTS.md` exists at the project root, append a regression entry to the `## Regressions` section:

```markdown
### [YYYY-MM-DD]: [short description — e.g., "Auth token not passed to API calls"]

**Root cause:** [one sentence — the actual code location and why]
**Fix:** [what was changed]
**Lesson:** [the principle extracted — what to watch for next time]
```

Remove the `> No regressions logged yet.` placeholder line if it's still there.

```bash
git add AGENTS.md .planning/debug/resolved/[session-file]
git commit -m "docs(debug): close session — [description]"
```

```
Debug session closed.
Session: .planning/debug/resolved/[session-file]

▶ If more issues remain: debug [new description]
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After resolving, offer based on what happened:

> 💡 **Learning moment:** Root cause found and fixed. Bugs are the highest-signal learning moments — don’t let this one fade:
>
> `@agentic-learning learn [bug domain]` — Active retrieval on the concept that broke. You explain the root cause first, gaps get filled. This is how "I've seen this bug" becomes real pattern recognition.
>
> `@agentic-learning struggle [the problem]` — Reproduce a similar problem from scratch with a hint ladder. The re-investigation builds deeper intuition than reading the fix.
>
> `@agentic-learning either-or` — Which debugging strategy worked (hypothesis testing, bisect, tracing)? Log it for future sessions.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning learn [bug domain]` · `@agentic-learning struggle [problem]` to turn this bug into a lasting pattern."*
