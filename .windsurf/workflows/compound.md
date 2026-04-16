---
description: Capture a solution at the moment of solving — structured doc to .planning/solutions/
---

# Compound

Capture a recently solved problem or learned pattern while context is fresh. Creates structured documentation in `.planning/solutions/` with YAML frontmatter for searchability. Each documented solution compounds your team's knowledge — the first time takes research, the next time takes minutes.

**Usage:** `compound` — document the most recent fix or learning
**Usage:** `compound [brief context]` — provide additional context hint

## Step 1: Choose Mode

Present the user with two options before proceeding. Use the platform's blocking question tool (`ask_user_question` in Claude Code, `request_user_input` in Codex, `ask_user` in Gemini, `ask_user_question` in Windsurf). If no question tool is available, present the options and wait for the user's reply.

```
1. Full (recommended) — the complete compound workflow. Researches,
   cross-references, and reviews your solution to produce documentation
   that compounds your project's knowledge.

2. Lightweight — same documentation, single pass. Faster and uses
   fewer tokens, but won't detect duplicates or cross-reference
   existing docs. Best for simple fixes or long sessions nearing
   context limits.
```

Do NOT pre-select a mode. Do NOT skip this prompt. Wait for the user's choice before proceeding.

---

## Full Mode

### Phase 1: Parallel Research

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization` is `true` (subagent mode — Claude Code, OpenCode, Codex):**

Launch these tasks IN PARALLEL. Each returns text data to the orchestrator — subagents must NOT write any files.

```
Task(
  subagent_type="learnship-solution-writer",
  description="Classify and extract solution",
  prompt="
    <agent_definition>
    You are a learnship solution writer. Analyze conversation history to classify problems and extract structured solution metadata.
    RESEARCH ONLY — do NOT write any files. Return text data to the orchestrator.
    </agent_definition>

    <objective>
    RESEARCH ONLY — do NOT write any files.
    Analyze conversation history to extract:
    1. Problem classification (bug vs knowledge track)
    2. YAML frontmatter skeleton with fields: title, date, category, module,
       problem_type, component, severity, tags
    3. Category directory path mapped from problem_type
    4. Suggested filename: [sanitized-problem-slug]-[YYYY-MM-DD].md

    Bug track problem_types: build_error, test_failure, runtime_error,
    performance_issue, database_issue, security_issue, ui_bug,
    integration_issue, logic_error

    Knowledge track problem_types: best_practice, documentation_gap,
    workflow_issue, developer_experience

    Category mapping:
    - build_error → build-errors/
    - test_failure → test-failures/
    - runtime_error → runtime-errors/
    - performance_issue → performance-issues/
    - database_issue → database-issues/
    - security_issue → security-issues/
    - ui_bug → ui-bugs/
    - integration_issue → integration-issues/
    - logic_error → logic-errors/
    - best_practice → best-practices/
    - workflow_issue → workflow-issues/
    - developer_experience → developer-experience/
    - documentation_gap → documentation-gaps/

    Return text data only.
    </objective>

    <files_to_read>
    - $LEARNSHIP_DIR/references/solution-schema.md
    </files_to_read>
  "
)
```

Simultaneously, search `.planning/solutions/` for related documentation:

```bash
# Search for related solutions
find .planning/solutions/ -name "*.md" -type f 2>/dev/null | head -20
```

If solutions exist, grep for keyword matches from the current problem:
```bash
grep -ril "[keyword1]\|[keyword2]" .planning/solutions/ 2>/dev/null
```

For each candidate, read the frontmatter (first 30 lines) to assess overlap across five dimensions: problem statement, root cause, solution approach, referenced files, and prevention rules.

Score overlap:
- **High** (4-5 dimensions match): essentially the same problem solved again
- **Moderate** (2-3 dimensions match): same area but different angle
- **Low** (0-1 dimensions match): related but distinct

**If `parallelization` is `false` (sequential mode):**

<persona_context>
You are now the **learnship solution writer**. Capture and document a solution at the moment of solving.
Analyze the problem, research the domain, document the fix with full context, and explain the "why" not just the "what."
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[36m  learnship-solution-writer(Capture and document a solution at the moment of solving)\033[0m\n\n"
> ```

Read `@./agents/solution-writer.md` for the full persona definition. Perform all research in sequence:

1. Extract from conversation history: problem, symptoms, what was tried, what worked
2. Classify: determine track (bug vs knowledge), problem_type, category, severity
3. Search `.planning/solutions/` for related docs using grep-first filtering
4. Assess overlap with existing docs
5. Suggest filename: `[sanitized-slug]-[YYYY-MM-DD].md`

### Phase 2: Assembly & Write

**WAIT for all Phase 1 research to complete before proceeding.**

Check the overlap assessment:

| Overlap | Action |
|---------|--------|
| **High** — existing doc covers the same problem and solution | **Update the existing doc** with fresher context rather than creating a duplicate. Add `last_updated: YYYY-MM-DD` to frontmatter. |
| **Moderate** — same area but different angle or solution | **Create a new doc**. Note the overlap for future consolidation. |
| **Low or none** | **Create a new doc** normally. |

Create directory if needed:
```bash
node -e "require('fs').mkdirSync('.planning/solutions/[category]/',{recursive:true})"
```

Write the solution document using the appropriate track template:

**Bug track template:**
```markdown
---
title: [Clear problem title]
date: [YYYY-MM-DD]
category: [category directory]
module: [module or area]
problem_type: [enum value]
severity: [critical|high|medium|low]
tags: [keyword-one, keyword-two]
---

# [Clear problem title]

## Problem
[1-2 sentence description of the issue and impact]

## Symptoms
- [Observable symptom or error]

## What Didn't Work
- [Attempted fix and why it failed]

## Solution
[The fix that worked, including code snippets]

## Why This Works
[Root cause explanation and why the fix addresses it]

## Prevention
- [Concrete practice, test, or guardrail]

## Related
- [Related docs or issues, if any]
```

**Knowledge track template:**
```markdown
---
title: [Clear, descriptive title]
date: [YYYY-MM-DD]
category: [category directory]
module: [module or area]
problem_type: [enum value]
severity: [critical|high|medium|low]
tags: [keyword-one, keyword-two]
---

# [Clear, descriptive title]

## Context
[What situation, gap, or friction prompted this guidance]

## Guidance
[The practice, pattern, or recommendation with code examples]

## Why This Matters
[Rationale and impact of following or not following this guidance]

## When to Apply
- [Conditions or situations where this applies]

## Examples
[Concrete before/after or usage examples]

## Related
- [Related docs or issues, if any]
```

### Phase 3: Commit & Confirm

```bash
git add ".planning/solutions/[category]/[filename].md"
git commit -m "docs(solutions): compound — [short title]"
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► COMPOUND COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File created:
- .planning/solutions/[category]/[filename].md

What's next?
1. Continue workflow (recommended)
2. View documentation
3. Link related documentation
```

Present the "What's next?" options using the platform's blocking question tool. Wait for the user's selection before proceeding.

**Alternate output (when updating an existing doc due to high overlap):**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► COMPOUND UPDATED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Overlap detected: .planning/solutions/[category]/[existing-file].md
  Action: Updated existing doc with fresher context
  Added: last_updated: [YYYY-MM-DD]

File updated:
- .planning/solutions/[category]/[existing-file].md
```

---

## Lightweight Mode

Single-pass alternative — same documentation, fewer tokens. No subagents, no cross-referencing, no duplicate detection.

1. **Extract from conversation**: Identify the problem and solution from conversation history
2. **Classify**: Determine track (bug vs knowledge), category, and filename using the schema from `$LEARNSHIP_DIR/references/solution-schema.md`
3. **Write minimal doc**: Create `.planning/solutions/[category]/[filename].md` using the appropriate track template with:
   - YAML frontmatter with track-appropriate fields
   - Bug track: Problem, solution with key code snippets, one prevention tip
   - Knowledge track: Context, guidance with key examples, one applicability note
4. **Skip cross-referencing** to conserve context

```bash
node -e "require('fs').mkdirSync('.planning/solutions/[category]/',{recursive:true})"
# Write the file
git add ".planning/solutions/[category]/[filename].md"
git commit -m "docs(solutions): compound — [short title] (lightweight)"
```

**Lightweight output:**
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► COMPOUND COMPLETE ✓ (lightweight)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

File created:
- .planning/solutions/[category]/[filename].md

Note: This was created in lightweight mode. For richer documentation
(cross-references, overlap detection), re-run /compound in a fresh session.

💡 Also consider: /extract-learnings [N] — captures decisions, lessons, patterns, surprises from the entire phase
```

**No subagents are launched. No parallel tasks. One file written.**

---

## The Compounding Philosophy

Each documented solution compounds your project's knowledge:

1. First time you solve a problem → Research (30 min)
2. Document the solution → `.planning/solutions/` (5 min)
3. Next time similar issue occurs → Quick lookup (2 min)
4. Knowledge compounds → Team gets smarter

**Each unit of engineering work should make subsequent units of work easier — not harder.**

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After documenting, offer based on what happened:

> 💡 **Learning moment:** Solution captured. Compound the knowledge further:
>
> `@agentic-learning learn [solution domain]` — Active retrieval on the concept you just documented. You explain the root cause first, gaps get filled. This is how fixes become lasting pattern recognition.
>
> `@agentic-learning space` — Schedule this concept for spaced revisit. Writes to `docs/revisit.md`. Future sessions start with less decay.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning learn [domain]` · `@agentic-learning space` to turn this solution into a lasting pattern."*
