---
description: Initialize a new project — questioning → research → requirements → roadmap
---

# New Project

Initialize a new project with full context gathering, optional research, requirements scoping, and roadmap creation. This is the most leveraged moment in any project — deep questioning now means better plans, better execution, better outcomes.

## Step 1: Setup

Check if `.planning/PROJECT.md` already exists:

```bash
test -f .planning/PROJECT.md && echo "EXISTS" || echo "NEW"
```

**If EXISTS:** Stop. Project already initialized. Use the `progress` workflow to see where you are.

Check if `.windsurf/` is already in `.gitignore`:
```bash
grep -q '.windsurf' .gitignore 2>/dev/null && echo "IGNORED" || echo "NOT_IGNORED"
```

**If NOT_IGNORED:** Add it now (regardless of whether the project is new or existing):
```bash
echo '.windsurf/' >> .gitignore
```

Check if git is initialized:

```bash
test -d .git && echo "HAS_GIT" || echo "NO_GIT"
```

**If NO_GIT:**
```bash
git init
```

Immediately add `.windsurf/` to `.gitignore` so the AI platform files are not tracked in the project repo:
```bash
echo '.windsurf/' >> .gitignore
```

Create the planning directory:
```bash
mkdir -p .planning/research
```

## Step 2: Configuration

Ask the user the following questions to configure the project. Ask them in a conversational way — not all at once, but grouped naturally.

**Group A — Working style:**

Ask: "How do you want to work?"
- **YOLO** (recommended) — Auto-approve steps, just execute
- **Interactive** — Confirm at each step

Ask: "How finely should scope be sliced into phases?"
- **Coarse** (recommended) — Fewer, broader phases (3-5 phases, 1-3 plans each)
- **Standard** — Balanced phase size (5-8 phases, 3-5 plans each)
- **Fine** — Many focused phases (8-12 phases, 5-10 plans each)

**Group B — Learning mode:**

Ask: "How should the learning partner (agentic-learning) work during this project?"
- **Auto** (recommended) — I'll offer relevant learning actions at natural checkpoints (after planning, after execution, etc.)
- **Manual** — I'll only activate when you explicitly invoke `@agentic-learning`

**Group C — Workflow agents (these add quality but cost tokens/time):**

Ask: "Which workflow agents should be enabled?"
- **Research** (recommended) — Investigate domain before planning each phase
- **Plan Check** (recommended) — Verify plans achieve their goals before execution
- **Verifier** (recommended) — Confirm deliverables match phase goals after execution

**Group D — Parallel execution (Claude Code, OpenCode, Gemini CLI, Codex CLI only — skip for Windsurf):**

Ask: "Do you want to enable parallel subagent execution?"
- **No** (recommended default) — Plans execute sequentially, one at a time. Always safe, works on all platforms.
- **Yes** — Each independent plan in a wave gets its own dedicated subagent with a fresh context budget. Faster but requires a platform that supports real subagents (Claude Code, OpenCode, Gemini CLI, Codex CLI). **Not available on Windsurf.**

> Only ask this question if the platform is not Windsurf. If on Windsurf, always set `parallelization: false`.

Ask: "Commit planning docs to git?"
- **Yes** (recommended) — Planning docs tracked in version control
- **No** — Keep `.planning/` local-only

Ask: "When should learnship commit files to git?"
- **Automatically** (recommended) — Commit after each workflow step completes (config, requirements, roadmap, AGENTS.md)
- **Manually** — I'll commit when I say so; skip all git commit steps

Create `.planning/config.json` with all settings:

```json
{
  "mode": "yolo|interactive",
  "granularity": "coarse|standard|fine",
  "commit_docs": true|false,
  "commit_mode": "auto|manual",
  "learning_mode": "auto|manual",
  "parallelization": false|true,
  "workflow": {
    "research": true|false,
    "plan_check": true|false,
    "verifier": true|false
  }
}
```

If `commit_docs` is false, add `.planning/` to `.gitignore`:
```bash
echo ".planning/" >> .gitignore
```

**If `commit_mode` is `auto`:** Stage and commit the initial setup now:
```bash
git add .gitignore .planning/config.json
git commit -m "chore: initialize learnship project setup"
```

**If `commit_mode` is `manual`:** Show this message and skip all future commit steps:
```
→ Manual commit mode — I will not run any git commits.
  Stage and commit whenever you are ready.
```

## Step 3: Deep Questioning

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► QUESTIONING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Ask openly: **"What do you want to build?"**

Wait for their response. Then follow the thread — each answer opens new questions. Dig into:
- What excited them / what problem sparked this
- What they mean by vague terms ("simple", "fast", "clean")
- What it would actually look like in use
- What's already decided vs. open
- Who the users are and what they need

Use the questioning techniques from `@./references/questioning.md`.

When you have enough to write a clear PROJECT.md, ask:

"I think I understand what you're after. Ready to create PROJECT.md, or do you want to explore more?"

- **Create PROJECT.md** → proceed
- **Keep exploring** → continue questions

Loop until ready.

## Step 4: Write PROJECT.md

Synthesize all gathered context into `.planning/PROJECT.md` using `@./templates/project.md` as the template.

**If `commit_mode` is `auto`:**
```bash
git add .planning/PROJECT.md && git commit -m "docs: initialize project"
```

## Step 5: Research Decision

Ask: "Research the domain ecosystem before defining requirements?"
- **Research first** (recommended) — Discover standard stacks, expected features, architecture patterns
- **Skip research** — I know this domain well, go straight to requirements

**If Research first:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Run 4 research passes sequentially. Each writes a file to `.planning/research/`:

1. **STACK.md** — Standard tech stack for this domain (specific libraries, versions, what NOT to use and why)
2. **FEATURES.md** — What features exist in this domain: table stakes vs. differentiators vs. anti-features
3. **ARCHITECTURE.md** — How systems in this domain are typically structured, component boundaries, data flow, suggested build order
4. **PITFALLS.md** — Common mistakes, warning signs, prevention strategies

After all four complete, synthesize into `.planning/research/SUMMARY.md` covering: recommended stack, table stakes features, key architecture decisions, top pitfalls to avoid.

Display key findings:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCH COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**Stack:** [key recommendation]
**Table Stakes:** [top 3 must-have features]
**Watch Out For:** [top 2 pitfalls]

Files: .planning/research/
```

## Step 6: Define Requirements

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► DEFINING REQUIREMENTS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Read `.planning/PROJECT.md` and research files if they exist. Present features by category with clear v1 vs. v2 distinctions.

For each feature category, ask the user which features are in v1 (multi-select). Track:
- Selected → v1 requirements
- Unselected table stakes → v2 (note: users will expect these)
- Unselected differentiators → out of scope

Each requirement should be:
- **Specific and testable:** "User can reset password via email link"
- **User-centric:** "User can X" (not "System does Y")
- **Atomic:** One capability per requirement

Create `.planning/REQUIREMENTS.md` with v1 requirements (with REQ-IDs like `AUTH-01`), v2 requirements, and out-of-scope items with reasoning.

Present the full list for confirmation. If user wants adjustments, iterate.

**If `commit_mode` is `auto`:**
```bash
git add .planning/REQUIREMENTS.md && git commit -m "docs: define v1 requirements"
```

## Step 7: Create Roadmap

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► CREATING ROADMAP
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Read `.planning/PROJECT.md`, `.planning/REQUIREMENTS.md`, and research summary (if exists).

Using `@./agents/planner.md` as your planning persona:

1. Derive phases from requirements (don't impose structure — let requirements drive phases)
2. Map every v1 requirement to exactly one phase
3. Create 2-5 observable success criteria per phase ("After this phase, user can ___")
4. Validate 100% requirement coverage

Write `.planning/ROADMAP.md` and `.planning/STATE.md` using `@./templates/requirements.md` and `@./templates/state.md`.

Present the roadmap clearly:

```
## Proposed Roadmap

**[N] phases** | **[X] requirements mapped** | All v1 requirements covered ✓

| # | Phase | Goal | Requirements |
|---|-------|------|--------------|
| 1 | [Name] | [Goal] | [REQ-IDs] |
...
```

Ask for approval:
- **Approve** → commit and continue
- **Adjust phases** → get feedback, revise, re-present
- **Review full file** → show raw ROADMAP.md, then re-ask

**If `commit_mode` is `auto`:**
```bash
git add .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md && git commit -m "docs: create roadmap ([N] phases)"
```

## Step 8: Generate AGENTS.md

Copy `@./templates/agents.md` to the project root as `AGENTS.md`.

Fill in the placeholder sections using information gathered in this session:

**Project Structure** — derive from the project description and any existing directories:
```bash
find . -maxdepth 2 -not -path './.git/*' -not -path './node_modules/*' -not -path './.planning/*' -type d | sort | head -20
```

Populate the `## Project Structure` tree with real directories and one-line descriptions.

**Tech Stack** — use the research output (if research was run) or the user's stated stack:
- Language + version
- Framework
- Key libraries (the 3-5 most important)
- How to run the dev server
- How to run tests

**Current Phase** block:
```
Milestone: v1.0 — [Milestone Name from PROJECT.md]
Phase: 1 — [Phase 1 name from ROADMAP.md]
Status: planning
Last updated: [today's date]
```

**If `commit_mode` is `auto`:**
```bash
git add AGENTS.md && git commit -m "docs: add AGENTS.md with project context"
```

## Step 9: Done

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► PROJECT INITIALIZED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**[Project Name]** — [N] phases, [X] requirements

Files created:
- AGENTS.md            ← your AI agent reads this every conversation
- .planning/PROJECT.md
- .planning/REQUIREMENTS.md
- .planning/ROADMAP.md
- .planning/STATE.md
- .planning/config.json
[- .planning/research/ (if research was run)]

▶ Next: discuss-phase 1 → plan-phase 1 → execute-phase 1
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer this now:

> 💡 **Learning moment:** You've just defined what you're building. Want to validate your mental model before coding starts?
> 
> `@agentic-learning brainstorm [your project topic]` — Talk through the design and surface any blind spots before the first line of code.

**If `manual`:** Add a quiet note: *"Tip: `@agentic-learning brainstorm [topic]` is available whenever you want to think through the design."*
