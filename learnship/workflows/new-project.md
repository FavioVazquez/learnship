---
description: Initialize a new project — questioning → research → requirements → roadmap
---

# New Project

Initialize a new project with full context gathering, optional research, requirements scoping, and roadmap creation. This is the most leveraged moment in any project — deep questioning now means better plans, better execution, better outcomes.

> **This workflow has 9 mandatory steps. You must complete every step in order. Do not skip, defer, or abbreviate any step. Check each one off as you complete it:**
>
> - [ ] Step 1 — Setup & codebase check
> - [ ] Step 1b — Existing codebase scan (if applicable)
> - [ ] Step 2 — Configuration questions
> - [ ] Step 3 — Deep questioning (4 exchanges)
> - [ ] Step 4 — Write and confirm PROJECT.md
> - [ ] Step 5 — Research decision (ask user, wait for answer)
> - [ ] Step 6 — Define requirements (interactive)
> - [ ] Step 7 — Create and approve roadmap
> - [ ] Step 8 — Generate AGENTS.md ← **mandatory, never skip**
> - [ ] Step 9 — Done banner + next step

## Step 1: Setup

<!-- LEARNSHIP_PLATFORM_LABEL -->

> **Routing protocol suspended.** While this workflow is running, every user message is an answer to a workflow question — not a task to route. Do NOT apply the request routing protocol until `/new-project` is fully complete and `.planning/PROJECT.md` exists.

Check if `.planning/PROJECT.md` already exists:

```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning/PROJECT.md') ? 'EXISTS' : 'NEW')"
```

**If EXISTS:** Stop. Project already initialized. Use the `progress` workflow to see where you are.

**Check for an existing codebase:**

```bash
node -e "
const fs=require('fs'),path=require('path');
function walk(dir,skip){let n=0;try{for(const e of fs.readdirSync(dir,{withFileTypes:true})){const f=path.join(dir,e.name);if(skip.some(s=>f.includes(s)))continue;n+=e.isDirectory()?walk(f,skip):1;}}catch(e){}return n;}
const n=walk('.',['/.git/','node_modules','.planning','__pycache__','.venv']);
console.log(n>2?'HAS_CODE':'BLANK');console.log(n+' files');
"
```

**If HAS_CODE:** Note this internally as `EXISTING_CODEBASE = true`. You will scan the codebase briefly in Step 1b before questioning. Do NOT use existing code as an excuse to skip or shorten the questioning ceremony — the ceremony exists precisely because you need the user's intent, not just their code.

Check if git is initialized:

```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.git') ? 'HAS_GIT' : 'NO_GIT')"
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
node -e "require('fs').mkdirSync('.planning/research',{recursive:true})"
```

## Step 1b: Existing Codebase Scan (only if EXISTING_CODEBASE = true)

If `EXISTING_CODEBASE = true`, do a quick structural scan before questioning so your follow-up questions are grounded in reality:

```bash
find . -maxdepth 3 -not -path './.git/*' -not -path './node_modules/*' -not -path './.planning/*' -not -path './__pycache__/*' -not -path './.venv/*' | sort | head -40
# PowerShell: Get-ChildItem -Recurse -Depth 3 | Where-Object { $_.FullName -notmatch '\.git|node_modules|\.planning|__pycache__|\.venv' } | Select-Object -First 40
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

**Group C — Model profile:**

Ask: "Which model quality tier do you want?"
- **Quality** — Large-tier models for all decision-making agents (highest cost, best results)
- **Balanced** (recommended) — Large for planning, medium for execution
- **Budget** — Medium for code, small for research/verification (lowest cost)

**Group D — Development style:**

Ask: "Test-first (TDD) mode?"
- **No** (recommended) — Write tests alongside implementation
- **Yes** — Enforce red-green-refactor: write failing test first, verify red, implement, verify green

**Group E — Workflow agents (these add quality but cost tokens/time):**

Ask: "Which workflow agents and quality steps should be enabled?"
- **Research** (recommended) — Investigate domain before planning each phase
- **Plan Check** (recommended) — Verify plans achieve their goals before execution
- **Verifier** (recommended) — Confirm deliverables match phase goals after execution
- **Review** (recommended) — Multi-persona code review after verification
- **Solutions Search** (recommended) — Search prior solutions for reusable patterns during planning

Ask: "Auto-trigger review after verify-work passes?"
- **No** (recommended) — Run `/review` manually when ready
- **Yes** — Automatically start review after verification succeeds

**Group F — Ship pipeline defaults:**

Ask: "Ship pipeline preferences?"
- **Auto-test before shipping** (recommended: yes) — Run tests before every ship
- **Conventional commits** (recommended: yes) — Use `feat:`, `fix:`, `docs:` commit prefixes
- **Auto-generate PR description** (recommended: yes) — Create PR body from commit messages

**Group G — Parallel execution:**

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
  "model_profile": "quality|balanced|budget",
  "learning_mode": "auto|manual",
  "parallelization": false|true,
  "test_first": false|true,
  "planning": {
    "commit_docs": true|false,
    "commit_mode": "auto|manual",
    "search_gitignored": false
  },
  "workflow": {
    "research": true|false,
    "plan_check": true|false,
    "verifier": true|false,
    "validation": true|false,
    "review": true|false,
    "solutions_search": true|false
  },
  "review": {
    "auto_after_verify": false|true
  },
  "ship": {
    "auto_test": true|false,
    "conventional_commits": true|false,
    "pr_template": true|false
  },
  "git": {
    "branching_strategy": "none|phase|milestone",
    "phase_branch_template": "phase-{phase}-{slug}",
    "milestone_branch_template": "{milestone}-{slug}"
  }
}
```

If `planning.commit_docs` is false, add `.planning/` to `.gitignore`:
```bash
echo ".planning/" >> .gitignore
```

**If `planning.commit_mode` is `auto`:** Stage and commit the initial setup now:
```bash
git add .gitignore .planning/config.json
git commit -m "chore: initialize learnship project setup"
```

**If `planning.commit_mode` is `manual`:** Show this message and skip all future commit steps:
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

> 🛑 **HARD GATE — count your messages.** Before continuing, verify:
> 1. You sent exactly **4 separate question messages** (Exchanges 1–4)
> 2. You received exactly **4 separate user answers** (`ANSWER_1` through `ANSWER_4`)
> 3. Each answer came from a **different user message** (not extracted from one long reply)
>
> If any count is wrong, go back and complete the missing exchanges. Do NOT proceed with fewer than 4 exchanges under any circumstances — even if the user's first answer was extremely detailed.

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

> 🛑 STOP — **Step 4 complete. You MUST now ask the research question (Step 5) before writing any other file.** Do not write REQUIREMENTS.md. Do not write ROADMAP.md. Do not proceed to any other step. The next action is to ask the user exactly one question: whether to research the domain first.

## Step 5: Research Decision

> **🔴 MANDATORY USER CHOICE — You must ask this question and wait for a reply. You are NOT allowed to decide this yourself, even if the domain seems trivial, familiar, or well-understood. The user decides. Always.**

Ask: **"Before I write the requirements — do you want me to research the domain ecosystem first?"**
- **Research first** (recommended) — Discover standard stacks, expected features, architecture patterns
- **Skip research** — I know this domain well, go straight to requirements

> 🛑 STOP. Wait for the user's explicit choice. Do not default to either option. Do not reason about whether research is needed — that is the user's call. Do not write REQUIREMENTS.md yet. Do not proceed until the user replies.

**If Research first:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**You MUST create exactly 5 separate markdown files.** Do NOT write a single monolithic research file. Do NOT combine multiple files into one. Each file is a separate write operation.

Create the research directory first:

```bash
node -e "require('fs').mkdirSync('.planning/research',{recursive:true})"
```

Now create each file one at a time. After writing each file, move to the next.

**File 1 of 5 — Write `.planning/research/STACK.md` now:**
Research the standard tech stack for this domain. The file MUST contain these exact `##` headers:
- `## Recommended Stack`
- `## Alternatives Considered`
- `## What NOT to Use` (with reasons)
- `## Versions`

**File 2 of 5 — Write `.planning/research/FEATURES.md` now:**
Research what features exist in this domain. The file MUST contain these exact `##` headers:
- `## Table Stakes` (must-haves)
- `## Differentiators` (nice-to-haves)
- `## Anti-Features` (what to avoid)

**File 3 of 5 — Write `.planning/research/ARCHITECTURE.md` now:**
Research how systems in this domain are typically structured. The file MUST contain these exact `##` headers:
- `## Component Boundaries`
- `## Data Flow`
- `## Build Order` (suggested sequence)
- `## Integration Points`

**File 4 of 5 — Write `.planning/research/PITFALLS.md` now:**
Research common mistakes and prevention strategies. The file MUST contain these exact `##` headers:
- `## Common Mistakes`
- `## Warning Signs`
- `## Prevention Strategies`

**File 5 of 5 — Write `.planning/research/SUMMARY.md` now:**
Synthesize the 4 files above into a summary. The file MUST contain these exact `##` headers:
- `## Recommended Stack`
- `## Table Stakes Features`
- `## Key Architecture Decisions`
- `## Top Pitfalls`

> 🔴 **HARD GATE — Run this verification command now. Do not skip it. Do not proceed without running it.**

```bash
node -e "const fs=require('fs'),path=require('path');const dir='.planning/research/';const checks={'STACK.md':['Recommended Stack','What NOT to Use'],'FEATURES.md':['Table Stakes','Differentiators'],'ARCHITECTURE.md':['Component Boundaries','Data Flow'],'PITFALLS.md':['Common Mistakes','Prevention Strategies'],'SUMMARY.md':['Recommended Stack','Top Pitfalls']};const missing=[];for(const[file,sections]of Object.entries(checks)){const fp=path.join(dir,file);if(!fs.existsSync(fp)){missing.push(file+' MISSING');continue;}const c=fs.readFileSync(fp,'utf8');for(const s of sections){if(!c.includes('## '+s))missing.push(file+': missing ## '+s);}}if(missing.length){console.log('RESEARCH INCOMPLETE:\\n'+missing.join('\\n'));process.exit(1);}console.log('RESEARCH VERIFIED OK — all 5 files present with required sections');"
```

> 🛑 **If the command prints `RESEARCH INCOMPLETE` or exits with code 1:** Go back and create or fix the missing files. Then run the verification again. You MUST see `RESEARCH VERIFIED OK` before continuing. Do NOT proceed to Step 6 without a passing verification.

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

> 🛑 STOP — **Step 7 complete. You MUST now generate AGENTS.md (Step 8) before anything else.** Do not display the done banner. Do not suggest next steps. Do not end the workflow. The roadmap is approved — AGENTS.md is next.

## Step 8: Generate AGENTS.md

> **🔴 MANDATORY — This step must always be completed. Do not skip it, do not defer it, do not move to Step 9 without writing AGENTS.md to the project root. AGENTS.md is the persistent memory file that every future session depends on.**

**Substep 8a — Read the template.** Read `@./templates/agents.md` in full RIGHT NOW before writing anything. This is the canonical template. You need its exact content.

> 🛑 **HARD GATE:** Did you just read `@./templates/agents.md`? If not, go back and read it now. The next substep requires copying sections verbatim from the template. You cannot do that without reading it first.

**Substep 8b — Write AGENTS.md.** Create the file `AGENTS.md` at the project root. The file structure MUST follow the template exactly. Here is the required section order:

1. `# AGENTS.md — [Project Name]` — replace `[PROJECT NAME]` with the actual project name
2. `## Soul — Who We Are Together` — **copy VERBATIM from the template** including all of Voice & Character and Relationship Model. Do not rewrite, summarize, or rephrase any of it.
3. `## Principles — How We Operate` — **copy VERBATIM from the template**. All 10 numbered principles, word for word.
4. `## Request Routing Protocol` — **copy VERBATIM from the template**. The entire decision tree and examples.
5. `## Platform Context` — **copy VERBATIM from the template**. The learnship key facts block.
6. `## Current Phase` — **FILL IN** with project-specific data:
   ```
   **Milestone:** v1.0 — [Milestone Name from PROJECT.md]
   **Phase:** 1 — [Phase 1 name from ROADMAP.md]
   **Status:** planning
   **Last updated:** [today's date]
   ```
7. `## Project Structure` — **FILL IN** by scanning existing directories:
   ```bash
   node -e "const{readdirSync,statSync}=require('fs'),{join}=require('path');const walk=(d,dep=0)=>{if(dep>2)return;try{readdirSync(d).filter(f=>!f.startsWith('.')&&f!=='node_modules').forEach(f=>{const p=join(d,f);if(statSync(p).isDirectory()){console.log(' '.repeat(dep*2)+'├── '+f+'/');walk(p,dep+1);}});}catch{}};walk('.');"
   ```
   Populate the tree with real directories and one-line descriptions.
8. `## Tech Stack` — **FILL IN** using research output (if available) or user's stated stack:
   - Language + version
   - Framework
   - Key libraries (the 3-5 most important)
   - How to run the dev server
   - How to run tests
9. `## Skills — Operational Knowledge` — **copy VERBATIM from the template**. CHANGELOG Discipline, Decisions Register, and Solutions Store sections.
10. `## Regressions — What Broke and What We Learned` — **copy VERBATIM from the template**. The empty starter block.

**You may ADD project-specific sections** (e.g., Conventions, Content Sources, Definition of Done) **after** Tech Stack and **before** Skills. But you must NEVER remove, rename, or replace the 10 sections listed above.

**Substep 8c — Verify AGENTS.md.** Run this command now. Do not skip it.

> 🔴 **HARD GATE — Run this verification command now. Do not skip it. Do not proceed without running it.**

```bash
node -e "const fs=require('fs');if(!fs.existsSync('AGENTS.md')){console.log('AGENTS.md NOT FOUND');process.exit(1);}const f=fs.readFileSync('AGENTS.md','utf8');const required=['Soul','Principles','Request Routing Protocol','Platform Context','Current Phase','Project Structure','Tech Stack','Skills','Regressions'];const missing=required.filter(s=>!f.includes('## '+s));if(missing.length){console.log('AGENTS.md INCOMPLETE — missing sections:\\n'+missing.map(s=>'  ## '+s).join('\\n'));process.exit(1);}const verbatim=['pair programmer','Direct, no fluff','Have opinions','Friction Is Signal','Minimal Upstream Fix','decision tree'];const missingV=verbatim.filter(s=>!f.includes(s));if(missingV.length){console.log('AGENTS.md TEMPLATE VIOLATION — these verbatim phrases are missing (did you rewrite instead of copy?):\\n'+missingV.join('\\n'));process.exit(1);}console.log('AGENTS.md VERIFIED OK — all '+required.length+' sections present, verbatim content intact');"
```

> 🛑 **If the command prints `INCOMPLETE` or `TEMPLATE VIOLATION` or exits with code 1:** The AGENTS.md is broken. Re-read `@./templates/agents.md` and fix the missing sections or restore the verbatim content. Run the verification again. You MUST see `AGENTS.md VERIFIED OK` before continuing to Step 9.

**If `commit_mode` is `auto`:**
```bash
git add AGENTS.md && git commit -m "docs: add AGENTS.md with project context"
```

<!-- LEARNSHIP_AGENTSMD_PLATFORM_NOTE -->

## Step 9: Done

Display this banner and then **STOP. Do not continue. Do not run any other workflow. Do not start Phase 1.**

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

▶ Next: `/discuss-phase 1` — **start here, not `/plan-phase`**

The full phase loop:
`discuss-phase` → `plan-phase` → `execute-phase` → `verify-work` → `review` → `ship` → `compound`

`discuss-phase` is mandatory before planning — it captures your intent and writes the CONTEXT.md that plan-phase depends on. Skipping it means planning without context.

After verify-work passes: `/review` for multi-persona code review, `/ship` to test+commit+push+PR, `/compound` to capture what you learned.

💡 For ambitious projects, consider running `/challenge` to stress-test the scope through product and engineering lenses before starting Phase 1.

💡 Working near sensitive areas (auth, payments, migrations)? Run `/guard [scope]` to activate safety mode.

> **Platform detected:** `[PLATFORM]` — parallelization is `[true/false]`
```

> 🔴 **HARD STOP — `/new-project` is now complete. This workflow is FINISHED.**
>
> **Do NOT automatically start `/discuss-phase 1`.** Do NOT run any phase workflow. Do NOT begin implementing Phase 1. Do NOT say "Let me start Phase 1" or "Now starting Phase 1" or anything similar.
>
> The user must explicitly type `/discuss-phase 1` (or another command) in a **new message** to continue. Your only job now is to display the banner above and wait.
>
> If the user's next message is a new task or question, apply the Request Routing Protocol from AGENTS.md — the routing suspension from Step 1 is now lifted.

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer this after the done banner (still within this message, but AFTER the banner):

> 💡 **Learning moment:** You've just defined what you're building. Want to validate your mental model before coding starts?
> 
> `@agentic-learning brainstorm [your project topic]` — Talk through the design and surface any blind spots before the first line of code.

**If `manual`:** Add a quiet note: *"Tip: `@agentic-learning brainstorm [topic]` is available whenever you want to think through the design."*

**After displaying the learning checkpoint, STOP. Wait for the user's next message.**
