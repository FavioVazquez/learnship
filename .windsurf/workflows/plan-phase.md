---
description: Research + create + verify plans for a phase — spawns specialist subagents where supported
---

# Plan Phase

Create executable plans for a roadmap phase. Default flow: Research → Plan → Verify → Done.

On platforms with subagent support (Claude Code, OpenCode, Codex), each stage spawns a dedicated specialist agent with its own full context budget. On all other platforms, all stages run sequentially in the same context.

**Usage:** `plan-phase [N]` — optionally add `--skip-research`, `--skip-verify`, or `--research` (force re-research)

**Flags:**
- `--skip-research` — skip the research stage even if enabled in config
- `--skip-verify` — skip the plan verification stage
- `--research` — force re-research even if RESEARCH.md already exists
- `--gaps` — plan only for gaps found during verification

> **Platform note:** Read `parallelization` from `.planning/config.json`. When enabled, researcher/planner/checker each run as a spawned subagent. When `false` (default), all stages run inline using agent persona files.

## Step 1: Initialize

Read `.planning/ROADMAP.md` and find the requested phase. If no phase number provided, detect the next unplanned phase.

If phase not found: stop and show available phases.

Read config:
```bash
cat .planning/config.json
```

Read TDD mode:
```bash
TDD_MODE=$(node -e "try{const c=JSON.parse(require('fs').readFileSync('.planning/config.json','utf8'));process.stdout.write(String((c.workflow||{}).tdd_mode||false));}catch(e){process.stdout.write('false');}" 2>/dev/null || echo 'false')
```

When `TDD_MODE` is `true`, instruct the planner to apply `type: tdd` to eligible tasks — the executor will use the red-green-refactor cycle for those tasks.

**Context window scaling:** Check `context_window` in config (default: 200000). At >= 500000, include the 3 most recent prior phase CONTEXT.md and SUMMARY.md files in the planner's context. At < 500000, include only frontmatter from prior phases.

Create the phase directory if it doesn't exist:
```bash
node -e "require('fs').mkdirSync('.planning/phases/[padded_phase]-[phase_slug]',{recursive:true})"
```

Check what already exists:
```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/" 2>/dev/null
```

## Step 1b: Load Decisions Register

If `.planning/DECISIONS.md` exists, read it:
```bash
cat .planning/DECISIONS.md 2>/dev/null
```

Surface any decisions relevant to this phase — the planner must not contradict active decisions without explicit user instruction.

## Step 2: Load CONTEXT.md

Check if a CONTEXT.md exists for this phase.

**If no CONTEXT.md:**
Ask: "No CONTEXT.md found for Phase [X]. Plans will use research and requirements only — your design preferences won't be included."
- **Continue without context** → proceed
- **Run discuss-phase first** → stop, suggest running `discuss-phase [X]` first

**If CONTEXT.md exists:** Load it and confirm: "Using phase context from: [path]"

## Step 2b: Search Solutions for Prior Art

**Skip if:** `workflow.solutions_search` is `false` in config (defaults to `true`).

Search `.planning/solutions/` for prior art matching this phase's keywords:

```bash
# Check if solutions directory exists
ls .planning/solutions/ 2>/dev/null

# Search for matching solutions by phase keywords
grep -ril "[phase_keyword1]\|[phase_keyword2]\|[phase_keyword3]" .planning/solutions/ 2>/dev/null
```

If matches found, read the frontmatter (first 30 lines) of each match. Surface relevant prior solutions to the planner:

```
Solutions prior art found:
- .planning/solutions/[category]/[file].md — [title] (relevant: [why])
```

These solutions provide context for planning — the planner should reference them to avoid reinventing known solutions.

## Step 3: Research Phase

**Skip if:** `--skip-research` flag, or `workflow.research` is `false` in config, or RESEARCH.md already exists (unless `--research` flag forces re-research).

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING PHASE [X]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `parallelization` is `true` (subagent mode):**

Spawn a dedicated researcher agent:
```
Task(
  subagent_type="learnship-phase-researcher",
  description="Phase [phase_number] research",
  prompt="
    <agent_definition>
    You are a learnship phase researcher. You answer 'What do I need to know to PLAN this phase well?' and produce a single RESEARCH.md that the planner consumes.
    Your training data is 6-18 months stale — treat it as hypothesis, not fact. Verify before asserting.
    Flag uncertainty with confidence levels (HIGH/MEDIUM/LOW). Be prescriptive: 'Use X because Y' not 'Options are X, Y, Z.'
    Tool priority: 1. search_web (implementation patterns — always include current year), 2. read_url_content (official docs), 3. Codebase scan (existing patterns to reuse).
    Investigation, not confirmation — gather evidence first, recommend second.
    </agent_definition>

    <objective>
    Research how to implement Phase [phase_number]: [phase_name].
    Answer: 'What do I need to know to PLAN this phase well?'
    You MUST run search_web queries BEFORE writing the file. Do NOT write from training data alone.
    </objective>

    <research_steps>
    1. Read user decisions from CONTEXT.md (if exists), requirements from REQUIREMENTS.md, and project state from STATE.md
    2. Run at least 3 search_web queries: '[phase technology] best practices [current year]', '[phase technology] common mistakes', '[phase technology] recommended libraries'
    3. read_url_content official docs for key libraries or frameworks discovered
    4. Scan the codebase for existing patterns relevant to this phase
    5. Write [padded_phase]-RESEARCH.md with confidence levels and source citations
    </research_steps>

    <files_to_read>
    - [context_path] (user decisions, if exists)
    - .planning/REQUIREMENTS.md
    - .planning/STATE.md
    </files_to_read>

    <output>
    Write to: .planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-RESEARCH.md
    Required sections: ## Don't Hand-Roll, ## Common Pitfalls, ## Existing Patterns in This Codebase, ## Recommended Approach
    </output>
  "
)
```

Wait for agent to complete, then verify RESEARCH.md was written.

**If `parallelization` is `false` (sequential mode):**

<persona_context>
You are now the **learnship phase researcher**. Your training data is stale — verify before asserting.
Tag every claim: [VERIFIED: source], [CITED: url], or [ASSUMED]. Never present assumed knowledge as verified fact.
Use search_web for implementation patterns, read_url_content for official docs, codebase scan for existing patterns to reuse.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[34m  learnship-phase-researcher(Your training data is stale — verify before asserting)\033[0m\n\n"
> ```

Read `@./agents/phase-researcher.md` for the full persona definition. Investigate how to implement this phase.

**Online research first.** Before writing anything, run at least 3 search_web queries relevant to this phase's domain. Use read_url_content to read official docs for any libraries discovered. Then read:
- The CONTEXT.md (user decisions)
- `.planning/REQUIREMENTS.md` (which requirements this phase covers)
- `.planning/STATE.md` (project history and decisions)
- Existing codebase for relevant patterns

Write `.planning/phases/[padded_phase]-[phase_slug]/[padded_phase]-RESEARCH.md` based on your web research findings. Include confidence levels and cite sources. The file must have two key sections:
- **Don't Hand-Roll** — problems with good existing solutions ("Don't build your own JWT — use jose")
- **Common Pitfalls** — what goes wrong, why, how to avoid it

## Step 4: Check Existing Plans

```bash
ls ".planning/phases/[padded_phase]-[phase_slug]/"*-PLAN.md 2>/dev/null
```

If plans already exist, ask: "Phase [X] already has [N] plan(s)."
- **Add more plans** → continue to planning
- **View existing** → show plans, then ask
- **Replan from scratch** → delete existing plans, continue

## Step 5: Create Plans

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PLANNING PHASE [X]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `parallelization` is `true` (subagent mode):**

Spawn a dedicated planner agent:
```
Task(
  subagent_type="learnship-planner",
  description="Plan phase [phase_number]",
  prompt="
    <agent_definition>
    You are a learnship planner. Create executable PLAN.md files that an AI agent can follow step-by-step.
    Each plan covers a single logical unit of work. Tasks use XML format with file, action, verify, done fields.
    Plans have YAML frontmatter: wave, depends_on, files_modified, autonomous.
    Be specific — task actions should be concrete instructions, not vague guidance.
    </agent_definition>

    <objective>
    Create 2-4 executable PLAN.md files for Phase [phase_number]: [phase_name].
    Write plans to [phase_dir]/[padded_phase]-NN-PLAN.md.
    </objective>

    <files_to_read>
    - .planning/STATE.md
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - [context_path] (if exists)
    - [research_path] (if exists)
    - $LEARNSHIP_DIR/templates/plan.md
    </files_to_read>

    <output>
    Write to: [phase_dir]/[padded_phase]-01-PLAN.md, [padded_phase]-02-PLAN.md, etc.
    Each plan must have: YAML frontmatter (wave, depends_on, files_modified) + tasks in XML + must_haves section
    </output>
  "
)
```

Wait for agent to complete, then verify PLAN.md files were written.

**If `parallelization` is `false` (sequential mode):**

<persona_context>
You are now the **learnship planner**. Create implementation plans that are executable in a single context window.
Each plan covers one logical unit of work. Tasks use XML format. Include YAML frontmatter with wave, depends_on, files_modified.
Right-size plans: too small = overhead, too large = risk. Aim for plans completable in one focused session.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[32m  learnship-planner(Create implementation plans that are executable in a single context window)\033[0m\n\n"
> ```

Read `@./agents/planner.md` for the full persona definition. Read all available context:
- `.planning/STATE.md`
- `.planning/ROADMAP.md`
- `.planning/REQUIREMENTS.md`
- CONTEXT.md (if exists)
- RESEARCH.md (if exists)

Create 2-4 PLAN.md files in the phase directory. Each plan:
- Covers a single logical unit of work executable in one context window
- Has YAML frontmatter: `wave`, `depends_on`, `files_modified`, `autonomous`
- Contains tasks in XML format (see `$LEARNSHIP_DIR/templates/plan.md`)
- Has `must_haves` section with observable verification criteria

**Wave assignment:**
- Plans with no dependencies → Wave 1 (independent, execute in any order)
- Plans depending on Wave 1 → Wave 2
- Plans with cross-plan file conflicts → same wave or sequential

**Name plans:** `[padded_phase]-01-PLAN.md`, `[padded_phase]-02-PLAN.md`, etc.

## Step 6: Verify Plans

**Skip if:** `--skip-verify` flag, or `workflow.plan_check` is `false` in config.

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► VERIFYING PLANS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**If `parallelization` is `true` (subagent mode):**

Spawn a plan-checker agent:
```
Task(
  subagent_type="learnship-plan-checker",
  description="Verify phase [phase_number] plans",
  prompt="
    <agent_definition>
    You are a learnship plan checker. Verify plans are complete, correct, and executable.
    Check: phase goal coverage, requirement IDs, CONTEXT.md decisions honored, task completeness, wave/dependency correctness.
    Be strict — flag missing requirement IDs, vague task actions, incorrect wave assignments.
    </agent_definition>

    <objective>
    Verify all PLAN.md files in [phase_dir] for Phase [phase_number]: [phase_name].
    Check: phase goal coverage, requirement IDs, CONTEXT.md decisions, task completeness, wave correctness.
    Return: PASS or list of specific issues per plan.
    </objective>

    <files_to_read>
    - [phase_dir]/*-PLAN.md (all plans)
    - .planning/ROADMAP.md
    - .planning/REQUIREMENTS.md
    - [context_path] (if exists)
    </files_to_read>
  "
)
```

If issues returned: revise affected plans, re-spawn checker. Max 3 iterations.
If still failing after 3 iterations: present issues and ask — **Force proceed** / **Provide guidance and retry** / **Abandon**.

**If `parallelization` is `false` (sequential mode):**

<persona_context>
You are now the **learnship plan checker**. Verify plans are complete, correct, and executable.
Every v1 requirement must map to at least one plan task. Success criteria must be observable and testable.
Flag gaps, missing coverage, unrealistic estimates, and circular dependencies.
Check: phase goal coverage, requirement IDs, CONTEXT.md decisions honored, task completeness, wave/dependency correctness.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[36m  learnship-plan-checker(Verify plans are complete, correct, and executable)\033[0m\n\n"
> ```

Read `@./agents/plan-checker.md` for the full persona definition. Check the plans against:
- The phase goal from ROADMAP.md
- All requirement IDs assigned to this phase
- CONTEXT.md decisions (are they honored?)
- Task completeness (files, action, verify, done fields)
- Wave/dependency correctness

**Verification loop (max 3 iterations):**

If issues found:
1. List the issues clearly
2. Revise the affected plans to fix them
3. Re-verify
4. If still failing after 3 iterations: present remaining issues and ask — **Force proceed** / **Provide guidance and retry** / **Abandon**

If verification passes: proceed.

## Step 7: Commit Plans

```bash
git add ".planning/phases/[padded_phase]-[phase_slug]/"
git commit -m "docs([padded_phase]): create phase plans"
```

## Step 7b: Update AGENTS.md

If `AGENTS.md` exists at the project root, update the `## Current Phase` block:

```markdown
## Current Phase

**Milestone:** [VERSION from STATE.md]
**Phase:** [N] — [Phase Name]
**Status:** planning
**Last updated:** [today's date]
```

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md — planning phase [N]"
```

## Step 8: Present Status

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PHASE [X] PLANNED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Phase [X]: [Name]** — [N] plan(s) in [M] wave(s)

| Wave | Plans | What it builds |
|------|-------|----------------|
| 1    | 01, 02 | [objectives] |
| 2    | 03     | [objective]  |

Research: [Completed | Used existing | Skipped]
Verification: [Passed | Passed with override | Skipped]

▶ Next: execute-phase [X]
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer based on context:

> 💡 **Learning moment:** Plans are ready. Before you execute, make sure the domain is solid:
>
> `@agentic-learning explain-first [phase topic]` — Explain the approach back in your own words before touching code. Gaps in the explanation reveal gaps in the mental model — before they become bugs.
>
> `@agentic-learning cognitive-load [topic]` — If the scope feels overwhelming, decompose it into working-memory-sized steps first.
>
> `@agentic-learning quiz [phase topic]` — Quick active recall on the domain concepts this phase covers. Especially useful if the research surfaced unfamiliar territory.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning explain-first [topic]` to validate your mental model before executing."*
