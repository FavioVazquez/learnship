---
description: Systematic debugging with persistent state — triage, diagnose root cause, plan fix, execute
---

# Debug

Systematic debugging workflow: triage → root cause diagnosis → fix planning → execution. Creates a persistent debug session file so context survives across context resets.

**Usage:** `debug [description]`

## Step 1: Create Debug Session

```bash
node -e "require('fs').mkdirSync('.planning/debug',{recursive:true})"
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

If no description was provided as an argument, ask: **"What is the exact symptom?"** and wait for response.

If description was provided, use it as starting context. Then gather triage details using structured questions:

```
ask_user_question([
  {
    header: "Frequency",
    question: "When does this happen?",
    multiSelect: false,
    options: [
      { label: "Always", description: "Reproduces every time" },
      { label: "Sometimes", description: "Intermittent, not always reproducible" },
      { label: "Specific conditions", description: "Only under certain circumstances" }
    ]
  },
  {
    header: "Regression",
    question: "When did it start?",
    multiSelect: false,
    options: [
      { label: "Always been broken", description: "Never worked correctly" },
      { label: "Recently broke", description: "Was working before, something changed" },
      { label: "Not sure", description: "Don't know when it started" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

Then ask as follow-ups (one at a time):
- "What did you expect to happen?"
- "What have you already tried?"

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
  description="Investigate bug",
  prompt="
    <agent_definition>
    You are a learnship debugger. Trace from user-facing symptoms inward to find root causes.
    Read-first: understand the current design before proposing changes. Find the specific file and line where behavior diverges.
    Confirm the root cause with: 'If this were fixed, would the symptom go away?'
    One hypothesis at a time. Change one thing, verify, then move to the next.
    </agent_definition>

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

<persona_context>
You are now the **learnship debugger**. Diagnose the root cause, not the symptoms.
One variable at a time. Add logging to track state. Reproduce before fixing. Never guess — verify.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[38;5;208m  learnship-debugger(Diagnose the root cause, not the symptoms)\033[0m\n\n"
> ```

Read `@./agents/debugger.md` for the full persona definition. As your investigation persona:

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

<persona_context>
You are now the **learnship executor**. Implement the fix surgically — minimal change, maximum precision.
Commit atomically. Verify the fix resolves the original issue. Don't improve adjacent code.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[33m  learnship-executor(Implement the fix surgically — minimal change, maximum precision)\033[0m\n\n"
> ```

Read `@./agents/executor.md` for the full persona definition. Once confirmed, implement the fix:
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
node -e "require('fs').mkdirSync('.planning/debug/resolved',{recursive:true})"
mv ".planning/debug/[session-file]" ".planning/debug/resolved/"
```

Suggest compounding the solution:
```
💡 Compound this fix? Run `/compound` to capture the problem, root cause,
and solution while context is fresh. Future plan-phase runs will search
these solutions before planning.
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
▶ Stuck or need deeper investigation? /forensics — post-mortem analysis
▶ Need to revert the fix? /undo --last 1
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
