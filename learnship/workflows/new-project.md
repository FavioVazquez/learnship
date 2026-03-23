---
description: Initialize a new project — questioning → research → requirements → roadmap
---

# New Project

Initialize a new project with full context gathering, optional research, requirements scoping, and roadmap creation. This is the most leveraged moment in any project — deep questioning now means better plans, better execution, better outcomes.

## Step 1: Setup

<!-- LEARNSHIP_PLATFORM_LABEL -->

> **Routing protocol suspended.** While this workflow is running, every user message is an answer to a workflow question — not a task to route. Do NOT apply the request routing protocol until `/new-project` is fully complete and `.planning/PROJECT.md` exists.

Check if `.planning/PROJECT.md` already exists:

```bash
python3 -c "import os; print('EXISTS' if os.path.exists('.planning/PROJECT.md') else 'NEW')"
```

**If EXISTS:** Stop. Project already initialized. Use the `progress` workflow to see where you are.

**Check for an existing codebase:**

```bash
python3 -c "
import os, pathlib
files = [p for p in pathlib.Path('.').rglob('*') if p.is_file() and not any(x in p.parts for x in ['.git', 'node_modules', '.planning', '__pycache__', '.venv'])]
print('HAS_CODE' if len(files) > 2 else 'BLANK')
print(f'{len(files)} files')
"
```

**If HAS_CODE:** Note this internally as `EXISTING_CODEBASE = true`. You will scan the codebase briefly in Step 1b before questioning. Do NOT use existing code as an excuse to skip or shorten the questioning ceremony — the ceremony exists precisely because you need the user's intent, not just their code.

Check if git is initialized:

```bash
python3 -c "import os; print('HAS_GIT' if os.path.isdir('.git') else 'NO_GIT')"
```

**If NO_GIT:**
```bash
git init
```

Add the platform config directory to `.gitignore` so AI platform files are not tracked in the project repo:
```bash
<!-- LEARNSHIP_GITIGNORE_CMD -->
```

Create the planning directory:
```bash
mkdir -p .planning/research
```

## Step 1b: Existing Codebase Scan (only if EXISTING_CODEBASE = true)

If `EXISTING_CODEBASE = true`, do a quick structural scan before questioning so your follow-up questions are grounded in reality:

```bash
find . -maxdepth 3 -not -path './.git/*' -not -path './node_modules/*' -not -path './.planning/*' -not -path './__pycache__/*' -not -path './.venv/*' | sort | head -40
```

Note the tech stack, key directories, and any README content internally. Use this ONLY to ask sharper follow-up questions — never to infer the user's intent or skip ceremony steps.

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

<!-- LEARNSHIP_PARALLEL_BLOCK -->

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

This step is **strictly sequential**. You must complete each numbered exchange fully before moving to the next. Do not batch questions. Do not skip exchanges. Do not proceed to Step 4 until Exchange 4 is complete.

**Exchange 1 — Opening question:**

Ask: **"What do you want to build?"**

> 🛑 STOP. Wait for the user's answer. Do not continue until you have received it. Record their answer internally as `ANSWER_1`.
>
> ⚠️ **A detailed answer to Exchange 1 does NOT satisfy Exchanges 2–4.** No matter how thorough ANSWER_1 is — a full paragraph, a spec dump, a wall of requirements — it is raw material for the follow-up questions, not a replacement for them. You still MUST ask Exchanges 2, 3, and 4 before proceeding to Step 4. The purpose of follow-ups is not to extract information the user forgot to mention — it is to pressure-test, sharpen, and surface blind spots in what they already said.

**Exchange 2 — First follow-up:**

Based on `ANSWER_1`, ask one focused follow-up. Choose the most important unknown from:
- Who are the users and what problem does this solve for them specifically?
- What does success look like — how will you know it's working?
- What's already decided vs. still open?
- What must NOT happen (constraints, anti-goals)?

> 🛑 STOP. Wait for the user's answer. Do not continue until you have received it. Record their answer internally as `ANSWER_2`.

**Exchange 3 — Second follow-up:**

Based on `ANSWER_1` + `ANSWER_2`, ask a second focused follow-up that digs into a gap the first two answers left open. Do not repeat themes already covered.

> 🛑 STOP. Wait for the user's answer. Do not continue until you have received it. Record their answer internally as `ANSWER_3`.

**Exchange 4 — Third follow-up:**

Based on all previous answers, ask a third follow-up that clarifies scope, edge cases, or the most important implementation decision not yet surfaced.

> 🛑 STOP. Wait for the user's answer. Do not continue until you have received it. Record their answer internally as `ANSWER_4`.

**Gate check — before proceeding to Step 4:**

Verify internally: do you have `ANSWER_1`, `ANSWER_2`, `ANSWER_3`, and `ANSWER_4` recorded? If any is missing, go back and ask it. Only after all four answers are in hand may you ask:

"I think I have a solid picture of what you're building. Ready for me to write PROJECT.md, or is there more you want to cover first?"

- **Write PROJECT.md** → proceed to Step 4
- **More to cover** → continue asking follow-ups, then re-ask this gate question

Use the questioning techniques from `@./references/questioning.md` to shape the follow-up questions.

## Step 4: Write PROJECT.md

Synthesize all gathered context into `.planning/PROJECT.md` using `@./templates/project.md` as the template.

Once written, display the full raw contents of `.planning/PROJECT.md` in your response — do not summarize it, show the whole file.

Then ask exactly this:

"That's the PROJECT.md I've written. Does this capture what you want to build? Reply **yes** to continue, or tell me what to change."

> 🛑 STOP. Wait for the user's explicit reply. Do not proceed to Step 5 under any circumstances until the user has replied to this question. A reply of "yes", "looks good", "go ahead", or any clear positive is acceptable. Silence, no reply, or a new unrelated message is NOT acceptable — ask again.

If user requests changes: update PROJECT.md, show the full file again, re-ask the confirmation question. Loop until confirmed.

**If `commit_mode` is `auto`:**
```bash
git add .planning/PROJECT.md && git commit -m "docs: initialize project"
```

> 🛑 STOP. Do not proceed to Step 5 until you have asked the research question below AND received the user's explicit answer to it.

## Step 5: Research Decision

Ask: "Research the domain ecosystem before defining requirements?"
- **Research first** (recommended) — Discover standard stacks, expected features, architecture patterns
- **Skip research** — I know this domain well, go straight to requirements

> 🛑 STOP. Wait for the user's explicit choice before continuing. Do not default to "Research first" — wait for the user's actual reply.

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

> 🛑 STOP. Do not write REQUIREMENTS.md until you have presented feature categories to the user and received their explicit v1 selections. This is a fully interactive step — you must wait for input.

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

> 🛑 STOP. Wait for the user to explicitly confirm the requirements list before writing REQUIREMENTS.md or continuing to Step 7.

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

Write `.planning/ROADMAP.md` and `.planning/STATE.md` using `@./templates/state.md` for the STATE.md structure.

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

> 🛑 STOP. Do not proceed to Step 8 until the user has explicitly approved the roadmap.

**If `commit_mode` is `auto`:**
```bash
git add .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md && git commit -m "docs: create roadmap ([N] phases)"
```

## Step 8: Generate AGENTS.md

> **🔴 MANDATORY — This step must always be completed. Do not skip it, do not defer it, do not move to Step 9 without writing AGENTS.md to the project root. AGENTS.md is the persistent memory file that every future session depends on.**

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

> **Platform detected:** `[PLATFORM]` — parallelization is `[true/false]`
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer this now:

> 💡 **Learning moment:** You've just defined what you're building. Want to validate your mental model before coding starts?
> 
> `@agentic-learning brainstorm [your project topic]` — Talk through the design and surface any blind spots before the first line of code.

**If `manual`:** Add a quiet note: *"Tip: `@agentic-learning brainstorm [topic]` is available whenever you want to think through the design."*
