---
description: Initialize a new project — questioning → research → requirements → roadmap
---

# New Project

Initialize a new project with full context gathering, optional research, requirements scoping, and roadmap creation. This is the most leveraged moment in any project — deep questioning now means better plans, better execution, better outcomes.

> **Platform note:** When this workflow shows structured question blocks, use your platform's interactive question tool to present them (the tool that lets users pick from predefined options). If no such tool is available, present each question as a numbered text list with descriptions and ask the user to reply with their choice number or label.

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

You are running on **Windsurf**. Platform config directory: `.windsurf/`

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
const skip=new Set(['.git','node_modules','.planning','__pycache__','.venv','.windsurf','.claude','.cursor','.codex','.gemini','.opencode','.config']);
const codeExt=new Set(['.ts','.js','.py','.go','.rs','.swift','.java','.kt','.c','.cpp','.h','.cs','.rb','.php','.dart','.scala','.lua','.r','.R','.zig','.ex','.exs','.clj']);
const pkgFiles=['package.json','requirements.txt','Cargo.toml','go.mod','Package.swift','build.gradle','pom.xml','Gemfile','composer.json','pubspec.yaml','CMakeLists.txt','Makefile','mix.exs'];
function hasCode(dir,depth){if(depth>3)return false;try{for(const e of fs.readdirSync(dir,{withFileTypes:true})){if(e.isFile()&&codeExt.has(path.extname(e.name)))return true;if(e.isDirectory()&&!skip.has(e.name)&&hasCode(path.join(dir,e.name),depth+1))return true;}}catch{}return false;}
const hasPkg=pkgFiles.some(f=>fs.existsSync(f));
const hasCodeFiles=hasCode('.',0);
const hasCbMap=fs.existsSync('.planning/codebase');
if(hasCodeFiles||hasPkg){console.log('HAS_CODE');console.log('has_package: '+(hasPkg?'yes':'no'));console.log('has_codebase_map: '+(hasCbMap?'yes':'no'));console.log('needs_map: '+(!hasCbMap?'yes':'no'));}else{console.log('BLANK');}
"
```

**If HAS_CODE:** Note this internally as `EXISTING_CODEBASE = true`. Also record `needs_map` (true if `.planning/codebase/` doesn't exist yet). You will offer codebase mapping in Step 1b before questioning. Do NOT use existing code as an excuse to skip or shorten the questioning ceremony — the ceremony exists precisely because you need the user's intent, not just their code.

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
grep -q '.windsurf/' .gitignore 2>/dev/null || echo '.windsurf/' >> .gitignore
```

Create the planning directory:
```bash
node -e "require('fs').mkdirSync('.planning/research',{recursive:true})"
```

## Step 1b: Existing Codebase Handling (only if EXISTING_CODEBASE = true)

If `EXISTING_CODEBASE = true`, first check whether a codebase map is needed.

**If `needs_map` is true** (existing code detected but no `.planning/codebase/`):

```
ask_user_question([
  {
    header: "Existing Codebase Detected",
    question: "I detected existing code in this directory. Would you like to map the codebase first? This produces structured reference docs that make the questioning phase sharper.",
    multiSelect: false,
    options: [
      { label: "Map codebase first (Recommended)", description: "Run /map-codebase to analyze architecture, stack, conventions, and concerns — then return here" },
      { label: "Quick scan only", description: "Do a fast structural scan and continue without full mapping" },
      { label: "Skip — I know this codebase", description: "Proceed directly to configuration questions" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

- **Map codebase first:** Tell the user: "Run `/map-codebase` first, then come back to `/new-project` — the codebase map will be available for the questioning phase." Then **STOP. Exit this workflow.** The user will return to `/new-project` after mapping completes.
- **Quick scan only:** Continue with the quick scan below.
- **Skip:** Continue directly to Step 2 (configuration).

**If `needs_map` is false** (codebase map already exists): Read the existing map for context and continue with the quick scan below.

**Quick structural scan** (for "Quick scan only" or when map already exists):

```bash
find . -maxdepth 3 -not -path './.git/*' -not -path './node_modules/*' -not -path './.planning/*' -not -path './__pycache__/*' -not -path './.venv/*' -not -path './.windsurf/*' -not -path './.windsurf/*' -not -path './.cursor/*' -not -path './.codex/*' -not -path './.gemini/*' -not -path './.opencode/*' | sort | head -40
# PowerShell: Get-ChildItem -Recurse -Depth 3 | Where-Object { $_.FullName -notmatch '\.git|node_modules|\.planning|__pycache__|\.venv|\.windsurf|\.claude|\.cursor|\.codex|\.gemini|\.opencode' } | Select-Object -First 40
```

If `.planning/codebase/` exists, also read the summary docs:
```bash
cat .planning/codebase/ARCHITECTURE.md 2>/dev/null | head -40
cat .planning/codebase/STACK.md 2>/dev/null | head -40
cat .planning/codebase/CONCERNS.md 2>/dev/null | head -20
```

Note the tech stack, key directories, and any README content internally. Use this ONLY to ask sharper follow-up questions — never to infer the user's intent or skip ceremony steps.

## Step 2: Configuration

> **🔴 MANDATORY INTERACTIVE QUESTIONS — You MUST present each round as a blocking question using `ask_user_question` (or your platform's equivalent: `ask_user_question` on Windsurf, `ask_user` on Gemini, `request_user_input` on Codex). Each round is a SEPARATE blocking call. Do NOT combine all rounds into one. Do NOT render questions as plain text or markdown lists — you MUST use the interactive question tool so the user clicks options. Wait for the user's reply after EACH round before showing the next round.**
>
> **🛑 FORBIDDEN:** Do NOT present all questions at once as a text wall. Do NOT skip any question. Do NOT invent answers. Do NOT proceed to the config.json write step until ALL 4 rounds have been answered by the user.

**Round 1 — Core settings (4 questions):**

> Present these 4 questions as a SINGLE blocking `ask_user_question` call. STOP and wait for the user's reply before proceeding to Round 2.

```
ask_user_question([
  {
    header: "Working Style",
    question: "How do you want to work?",
    multiSelect: false,
    options: [
      { label: "Auto (Recommended)", description: "Auto-approve steps, just execute" },
      { label: "Interactive", description: "Confirm at each step" }
    ]
  },
  {
    header: "Granularity",
    question: "How finely should scope be sliced into phases?",
    multiSelect: false,
    options: [
      { label: "Coarse (Recommended)", description: "Fewer, broader phases (3-5 phases, 1-3 plans each)" },
      { label: "Standard", description: "Balanced phase size (5-8 phases, 3-5 plans each)" },
      { label: "Fine", description: "Many focused phases (8-12 phases, 5-10 plans each)" }
    ]
  },
  {
    header: "Learning Partner",
    question: "How should agentic-learning work during this project?",
    multiSelect: false,
    options: [
      { label: "Auto (Recommended)", description: "Offer learning actions at natural checkpoints (after planning, execution, etc.)" },
      { label: "Manual", description: "Only activate when you explicitly invoke @agentic-learning" }
    ]
  },
  {
    header: "AI Models",
    question: "Which model quality tier for planning agents?",
    multiSelect: false,
    options: [
      { label: "Balanced (Recommended)", description: "Large for planning, medium for execution — good quality/cost ratio" },
      { label: "Quality", description: "Large-tier models for all agents (highest cost, best results)" },
      { label: "Budget", description: "Medium for code, small for research/verification (lowest cost)" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's Round 1 reply before continuing.

**Round 2 — Workflow agents (5 questions):**

> Present these 5 questions as a SINGLE blocking `ask_user_question` call. STOP and wait for the user's reply before proceeding to Round 3.

```
ask_user_question([
  {
    header: "Research",
    question: "Research domain before planning each phase? (adds tokens/time)",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Investigate domain, find patterns, surface gotchas" },
      { label: "No", description: "Plan directly from requirements" }
    ]
  },
  {
    header: "Plan Check",
    question: "Verify plans will achieve their goals? (adds tokens/time)",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Catch gaps before execution starts" },
      { label: "No", description: "Execute plans without verification" }
    ]
  },
  {
    header: "Verifier",
    question: "Verify work satisfies requirements after each phase? (adds tokens/time)",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Confirm deliverables match phase goals" },
      { label: "No", description: "Trust execution, skip verification" }
    ]
  },
  {
    header: "Review",
    question: "Multi-persona code review after verification?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Correctness, security, performance, maintainability review" },
      { label: "No", description: "Skip code review" }
    ]
  },
  {
    header: "Solutions Search",
    question: "Search prior solutions for reusable patterns during planning?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Check .planning/solutions/ for relevant past fixes" },
      { label: "No", description: "Plan without searching prior solutions" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's Round 2 reply before continuing.

**Round 3 — Pipeline & git (4 questions):**

> Present these 4 questions as a SINGLE blocking `ask_user_question` call. STOP and wait for the user's reply before proceeding to Round 4.

```
ask_user_question([
  {
    header: "TDD",
    question: "Test-first (TDD) mode?",
    multiSelect: false,
    options: [
      { label: "No (Recommended)", description: "Write tests alongside implementation" },
      { label: "Yes", description: "Red-green-refactor: write failing test first, implement, verify green" }
    ]
  },
  {
    header: "Ship Pipeline",
    question: "Ship pipeline preferences?",
    multiSelect: true,
    options: [
      { label: "Auto-test before shipping (Recommended)", description: "Run tests before every ship" },
      { label: "Conventional commits (Recommended)", description: "Use feat:, fix:, docs: commit prefixes" },
      { label: "Auto-generate PR description (Recommended)", description: "Create PR body from commit messages" }
    ]
  },
  {
    header: "Git Tracking",
    question: "Commit planning docs to git?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Planning docs tracked in version control" },
      { label: "No", description: "Keep .planning/ local-only (add to .gitignore)" }
    ]
  },
  {
    header: "Commit Mode",
    question: "When should learnship commit files to git?",
    multiSelect: false,
    options: [
      { label: "Automatically (Recommended)", description: "Commit after each workflow step completes" },
      { label: "Manually", description: "You commit when ready; skip all git commit steps" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's Round 3 reply before continuing.

**Group D — Parallel execution:**

Windsurf does not support real subagents. Parallelization is automatically set to `false`.

> 🛑 STOP. Wait for the user's Round 4 reply (parallelization) before continuing.

**Now create `.planning/config.json`** — use EXACTLY this schema. Map the user's answers to these keys. Do NOT invent keys. Do NOT use flat keys like `working_style`, `model_tier`, `platform`, `milestone`, or `phases` — those are WRONG.

**Key mapping from questions to config:**
- Working Style → `"mode"`: `"auto"` or `"interactive"`
- Granularity → `"granularity"`: `"coarse"`, `"standard"`, or `"fine"`
- Learning Partner → `"learning_mode"`: `"auto"` or `"manual"`
- AI Models → `"model_profile"`: `"balanced"`, `"quality"`, or `"budget"`
- Research → `"workflow.research"`: `true` or `false`
- Plan Check → `"workflow.plan_check"`: `true` or `false`
- Verifier → `"workflow.verifier"`: `true` or `false`
- Review → `"workflow.review"`: `true` or `false`
- Solutions Search → `"workflow.solutions_search"`: `true` or `false`
- TDD → `"test_first"`: `true` or `false`
- Ship Pipeline → `"ship.auto_test"`, `"ship.conventional_commits"`, `"ship.pr_template"`: each `true` or `false`
- Git Tracking → `"planning.commit_docs"`: `true` or `false`
- Commit Mode → `"planning.commit_mode"`: `"auto"` or `"manual"`
- Parallel Execution → `"parallelization.enabled"`: `true` or `false`

Create `.planning/config.json` with all settings:

```json
{
  "mode": "auto|interactive",
  "granularity": "coarse|standard|fine",
  "model_profile": "quality|balanced|budget",
  "learning_mode": "auto|manual",
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
    "solutions_search": true|false,
    "security_enforcement": true|false,
    "discuss_mode": "discuss",
    "tdd_mode": false|true
  },
  "parallelization": {
    "enabled": false|true,
    "plan_level": true,
    "task_level": false,
    "max_concurrent_agents": 5,
    "min_plans_for_parallel": 2
  },
  "gates": {
    "confirm_project": true,
    "confirm_phases": true,
    "confirm_roadmap": true,
    "confirm_plan": true,
    "execute_next_plan": true,
    "issues_review": true,
    "confirm_transition": true
  },
  "safety": {
    "always_confirm_destructive": true,
    "always_confirm_external_services": true
  },
  "review": {
    "auto_after_verify": false|true
  },
  "ship": {
    "auto_test": true|false,
    "conventional_commits": true|false,
    "pr_template": true|false
  },
  "hooks": {
    "context_warnings": true
  },
  "git": {
    "branching_strategy": "none|phase|milestone",
    "phase_branch_template": "phase-{phase}-{slug}",
    "milestone_branch_template": "{milestone}-{slug}"
  }
}
```

**Note:** The `parallelization` field is now an object (not a flat boolean). Legacy flat `"parallelization": true` is still honored for backward compatibility. The `gates` and `safety` sections use sensible defaults — only ask users about them if they specifically want to customize.

**Verify config.json was written correctly:**

```bash
node -e "
const fs=require('fs');
try{
  const c=JSON.parse(fs.readFileSync('.planning/config.json','utf8'));
  const errs=[];
  if(!['auto','interactive'].includes(c.mode)) errs.push('mode must be auto|interactive, got: '+c.mode);
  if(!['coarse','standard','fine'].includes(c.granularity)) errs.push('granularity must be coarse|standard|fine');
  if(!['quality','balanced','budget'].includes(c.model_profile)) errs.push('model_profile must be quality|balanced|budget');
  if(!['auto','manual'].includes(c.learning_mode)) errs.push('learning_mode must be auto|manual');
  if(typeof c.test_first!=='boolean') errs.push('test_first must be boolean');
  if(!c.planning||!['auto','manual'].includes(c.planning.commit_mode)) errs.push('planning.commit_mode must be auto|manual');
  if(!c.workflow||typeof c.workflow.research!=='boolean') errs.push('workflow.research must be boolean');
  if(!c.workflow||typeof c.workflow.plan_check!=='boolean') errs.push('workflow.plan_check must be boolean');
  if(!c.workflow||typeof c.workflow.verifier!=='boolean') errs.push('workflow.verifier must be boolean');
  if(!c.workflow||typeof c.workflow.review!=='boolean') errs.push('workflow.review must be boolean');
  if(!c.parallelization||typeof c.parallelization.enabled!=='boolean') errs.push('parallelization.enabled must be boolean');
  if(!c.ship||typeof c.ship.auto_test!=='boolean') errs.push('ship.auto_test must be boolean');
  const bad=['working_style','model_tier','platform','milestone','phases','commit_mode'];
  for(const k of bad){if(k in c)errs.push('FORBIDDEN top-level key: '+k+' — use the nested schema');}
  if(errs.length){console.log('CONFIG_INVALID');errs.forEach(e=>console.log('  - '+e));}
  else console.log('CONFIG_VALID');
}catch(e){console.log('CONFIG_MISSING_OR_CORRUPT: '+e.message);}
"
```

**If `CONFIG_INVALID` or `CONFIG_MISSING_OR_CORRUPT`:** The config file is wrong. Fix it to match the schema above exactly, then re-run the verification. Do NOT proceed until it passes.

**If `CONFIG_VALID`:** Continue.

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

Use the questioning techniques from `@./references/questioning.md` and domain-aware probes from `@./references/domain-probes.md` to shape the follow-up questions. When the user mentions a known domain (auth, real-time, dashboard, API, database, search, file uploads, caching, testing, deployment, AI/ML), use the relevant probes to ask sharper questions.

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

> **🔴 MANDATORY USER CHOICE — You must ask this question and wait for a reply. You are NOT allowed to decide this yourself.**

Display the research decision banner, then present the choice using a structured question:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCH DECISION
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

```
ask_user_question([
  {
    header: "Research",
    question: "Before I write the requirements — do you want me to research the domain ecosystem first?",
    multiSelect: false,
    options: [
      { label: "Research first (Recommended)", description: "Discover standard stacks, expected features, architecture patterns, common pitfalls — writes 5 research files" },
      { label: "Skip research", description: "Go straight to requirements" }
    ]
  }
])
```

> � **HARD GATE — This is a user decision. You MUST wait for the user to reply.**
>
> **You are FORBIDDEN from deciding this yourself.** It does not matter if:
> - The tech stack is already defined in PROJECT.md
> - The domain seems trivial or well-understood
> - You already know the ecosystem
> - The user gave detailed answers in Deep Questioning
> - The project seems simple
>
> **None of these are valid reasons to skip the question.** The user ALWAYS gets asked. The user ALWAYS decides.
>
> **Forbidden responses (do NOT say anything like these):**
> - "The tech stack is already well-defined in PROJECT.md. No research needed."
> - "Since you've already described the stack, I'll skip research."
> - "Moving straight to requirements/roadmap."
> - "Research isn't necessary for this project."
> - Any sentence that contains "no research needed" or "skip research" that you wrote yourself (not the user).
>
> **The ONLY acceptable next action is: display the question above and wait.** Do not write REQUIREMENTS.md. Do not write ROADMAP.md. Do not proceed to Step 6. Wait for the user's reply.

**If Research first:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► WRITING RESEARCH FILES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

> 🔴 **CRITICAL — "Research" in this step means TWO things: (1) SEARCHING THE WEB for current information, then (2) WRITING 5 FILES to disk based on what you found. The deliverable is 5 markdown files grounded in real online research, not training data. You are not done with research until all 5 files exist and pass verification.**
>
> **Forbidden behaviors (if you do any of these, the research step has FAILED):**
> - **Writing files without doing web research first** — reading templates and writing from training data is NOT research. You must run search_web queries and read_url_content official docs BEFORE writing any file.
> - Doing web searches or thinking about the domain and then saying "I have enough research data" WITHOUT writing the 5 files
> - Writing research findings only in your response text instead of to files
> - Writing fewer than 5 files (e.g., one combined file)
> - Moving to Step 6 or writing REQUIREMENTS.md before the verification command below prints `RESEARCH VERIFIED OK`
> - Saying "Let me proceed to requirements" or "Moving to requirements" before verification passes
>
> **The ONLY acceptable sequence is:** mkdir → **web research (search_web + read_url_content)** → write file 1 → write file 2 → write file 3 → write file 4 → write file 5 → run verification → see `RESEARCH VERIFIED OK` → present findings → get user confirmation.

**Step 5a — Create the research directory.** Run this command now:

```bash
node -e "require('fs').mkdirSync('.planning/research',{recursive:true})"
```

> 🛑 Did the mkdir command run? If not, run it now before continuing.

Read `parallelization` from `.planning/config.json` (defaults to `false`).

**If `parallelization.enabled` is `true` (subagent mode — Claude Code, OpenCode, Codex):**

Display spawning indicator:
```
◆ Spawning 4 researchers in parallel...
  → Stack research
  → Features research
  → Architecture research
  → Pitfalls research
```

Spawn 4 parallel researcher agents — one per research dimension. Each agent writes ONE file.

```
Task(
  subagent_type="learnship-researcher",
  description="Stack research",
  prompt="
    <agent_definition>
    You are a learnship researcher. Your training data is 6-18 months stale — treat it as hypothesis, not fact.
    Verify before asserting. Flag uncertainty with confidence levels (HIGH/MEDIUM/LOW). Be prescriptive: 'Use X because Y' not 'Options are X, Y, Z.'
    Tool priority: 1. search_web (ecosystem discovery — always include current year), 2. read_url_content (official docs), 3. Codebase scan.
    </agent_definition>

    <objective>
    Research the standard tech stack for [project domain]. Write .planning/research/STACK.md.
    You MUST run search_web queries BEFORE writing the file. Do NOT write from training data alone.
    </objective>

    <research_steps>
    1. Read .planning/PROJECT.md to understand the project domain and goals
    2. Run 2-3 search_web queries: '[domain] recommended tech stack [current year]', '[domain] best libraries [current year]'
    3. read_url_content official docs for any key libraries discovered
    4. Write .planning/research/STACK.md with confidence levels and source citations
    </research_steps>

    <files_to_read>
    - .planning/PROJECT.md (project context and goals)
    </files_to_read>

    <downstream_consumer>
    Your STACK.md feeds into roadmap creation. Be prescriptive:
    - Specific libraries with versions
    - Clear rationale for each choice
    - What NOT to use and why
    </downstream_consumer>

    <quality_gate>
    - [ ] Versions are current (verified via search_web/read_url_content, not training data)
    - [ ] Rationale explains WHY, not just WHAT
    - [ ] Confidence levels assigned to each recommendation
    </quality_gate>

    <output>
    Write to: .planning/research/STACK.md
    Required sections: ## Recommended Stack, ## Alternatives Considered, ## What NOT to Use, ## Versions
    </output>
  "
)

Task(
  subagent_type="learnship-researcher",
  description="Features research",
  prompt="
    <agent_definition>
    You are a learnship researcher. Your training data is 6-18 months stale — treat it as hypothesis, not fact.
    Verify before asserting. Flag uncertainty with confidence levels (HIGH/MEDIUM/LOW). Be prescriptive: 'Use X because Y' not 'Options are X, Y, Z.'
    Tool priority: 1. search_web (ecosystem discovery — always include current year), 2. read_url_content (official docs), 3. Codebase scan.
    </agent_definition>

    <objective>
    Research what features [project domain] products typically have. Write .planning/research/FEATURES.md.
    You MUST run search_web queries BEFORE writing the file. Do NOT write from training data alone.
    </objective>

    <research_steps>
    1. Read .planning/PROJECT.md to understand the project domain and goals
    2. Run 2-3 search_web queries: '[domain] features table stakes [current year]', '[domain] product features comparison'
    3. read_url_content any relevant product comparison pages or feature lists
    4. Write .planning/research/FEATURES.md with confidence levels and source citations
    </research_steps>

    <files_to_read>
    - .planning/PROJECT.md (project context and goals)
    </files_to_read>

    <downstream_consumer>
    Your FEATURES.md feeds into requirements definition. Categorize clearly:
    - Table stakes (must have or users leave)
    - Differentiators (competitive advantage)
    - Anti-features (things to deliberately NOT build)
    </downstream_consumer>

    <quality_gate>
    - [ ] Categories are clear (table stakes vs differentiators vs anti-features)
    - [ ] Complexity noted for each feature
    - [ ] Dependencies between features identified
    </quality_gate>

    <output>
    Write to: .planning/research/FEATURES.md
    Required sections: ## Table Stakes, ## Differentiators, ## Anti-Features
    </output>
  "
)

Task(
  subagent_type="learnship-researcher",
  description="Architecture research",
  prompt="
    <agent_definition>
    You are a learnship researcher. Your training data is 6-18 months stale — treat it as hypothesis, not fact.
    Verify before asserting. Flag uncertainty with confidence levels (HIGH/MEDIUM/LOW). Be prescriptive: 'Use X because Y' not 'Options are X, Y, Z.'
    Tool priority: 1. search_web (ecosystem discovery — always include current year), 2. read_url_content (official docs), 3. Codebase scan.
    </agent_definition>

    <objective>
    Research how [project domain] systems are typically structured. Write .planning/research/ARCHITECTURE.md.
    You MUST run search_web queries BEFORE writing the file. Do NOT write from training data alone.
    </objective>

    <research_steps>
    1. Read .planning/PROJECT.md to understand the project domain and goals
    2. Run 2-3 search_web queries: '[domain] architecture patterns', '[domain] system design components'
    3. read_url_content architectural guides or documentation for the chosen stack
    4. Write .planning/research/ARCHITECTURE.md with confidence levels and source citations
    </research_steps>

    <files_to_read>
    - .planning/PROJECT.md (project context and goals)
    </files_to_read>

    <downstream_consumer>
    Your ARCHITECTURE.md informs phase structure in roadmap. Include:
    - Component boundaries (what talks to what)
    - Data flow (how information moves)
    - Suggested build order (dependencies between components)
    </downstream_consumer>

    <quality_gate>
    - [ ] Components clearly defined with boundaries
    - [ ] Data flow direction explicit
    - [ ] Build order implications noted
    </quality_gate>

    <output>
    Write to: .planning/research/ARCHITECTURE.md
    Required sections: ## Component Boundaries, ## Data Flow, ## Build Order, ## Integration Points
    </output>
  "
)

Task(
  subagent_type="learnship-researcher",
  description="Pitfalls research",
  prompt="
    <agent_definition>
    You are a learnship researcher. Your training data is 6-18 months stale — treat it as hypothesis, not fact.
    Verify before asserting. Flag uncertainty with confidence levels (HIGH/MEDIUM/LOW). Be prescriptive: 'Use X because Y' not 'Options are X, Y, Z.'
    Tool priority: 1. search_web (ecosystem discovery — always include current year), 2. read_url_content (official docs), 3. Codebase scan.
    </agent_definition>

    <objective>
    Research what [project domain] projects commonly get wrong. Write .planning/research/PITFALLS.md.
    You MUST run search_web queries BEFORE writing the file. Do NOT write from training data alone.
    </objective>

    <research_steps>
    1. Read .planning/PROJECT.md to understand the project domain and goals
    2. Run 2-3 search_web queries: '[domain] common mistakes gotchas', '[domain] pitfalls beginners'
    3. read_url_content any detailed postmortems or lessons-learned articles
    4. Write .planning/research/PITFALLS.md with confidence levels and source citations
    </research_steps>

    <files_to_read>
    - .planning/PROJECT.md (project context and goals)
    </files_to_read>

    <downstream_consumer>
    Your PITFALLS.md prevents mistakes in roadmap/planning. For each pitfall:
    - Warning signs (how to detect early)
    - Prevention strategy (how to avoid)
    - Which phase should address it
    </downstream_consumer>

    <quality_gate>
    - [ ] Pitfalls are specific to this domain (not generic advice)
    - [ ] Prevention strategies are actionable
    - [ ] Phase mapping included where relevant
    </quality_gate>

    <output>
    Write to: .planning/research/PITFALLS.md
    Required sections: ## Common Mistakes, ## Warning Signs, ## Prevention Strategies
    </output>
  "
)
```

After all 4 agents complete, spawn a synthesizer to create SUMMARY.md from the other 4 files:

```
Task(
  subagent_type="learnship-researcher",
  description="Synthesize research",
  prompt="
    <objective>
    Synthesize the 4 research files into a single SUMMARY.md.
    Read all 4 files, extract the key findings, and write a cohesive summary.
    </objective>

    <files_to_read>
    - .planning/research/STACK.md
    - .planning/research/FEATURES.md
    - .planning/research/ARCHITECTURE.md
    - .planning/research/PITFALLS.md
    </files_to_read>

    <output>
    Write to: .planning/research/SUMMARY.md
    Required sections: ## Recommended Stack, ## Table Stakes Features, ## Key Architecture Decisions, ## Top Pitfalls
    </output>
  "
)
```

Wait for the synthesizer to complete, then proceed to Step 5c (verification) to confirm all 5 files were written correctly.

**If `parallelization.enabled` is `false` (sequential mode):**

<persona_context>
You are now the **learnship project researcher**. Your training data is 6–18 months stale — verify before asserting.
Use search_web for ecosystem discovery (always include current year), read_url_content for official docs, codebase scan for existing patterns.
Tag confidence: HIGH (multi-source verified), MEDIUM (single official source), LOW (unverified).
Be comprehensive but opinionated — "Use X because Y" not "Options are X, Y, Z."
Investigation, not confirmation — gather evidence first, recommend second.
Your research feeds the roadmapper: STACK.md → tech decisions, FEATURES.md → what to build, ARCHITECTURE.md → system structure, PITFALLS.md → risk flags.
</persona_context>

Read `@./agents/project-researcher.md` for the full persona definition.

**Step 5b-pre — Online research (BEFORE writing any files).**

> 🔴 **You MUST do web research before writing files.** Your training data is stale. Do not write research files from memory alone — investigate first, write second.

Run at least 5 search_web queries to discover the current state of this project's domain. Include the current year in all queries. Example queries (adapt to the actual project domain):

1. `"[project domain] recommended tech stack 2026"` — discover what's standard
2. `"[project domain] best libraries 2026"` — find specific tools
3. `"[project domain] architecture patterns"` — how systems in this domain are structured
4. `"[project domain] common mistakes gotchas"` — what goes wrong
5. `"[key technology from PROJECT.md] best practices"` — specific tech guidance

For any libraries or frameworks discovered, use read_url_content to read their official documentation pages.

Record your findings internally. You will use them to write the 5 files below. Every recommendation in the files should be grounded in what you found online — include confidence levels (HIGH/MEDIUM/LOW) and cite sources where possible.

> 🛑 STOP. Confirm: did you run at least 5 search_web queries? If you skipped straight to writing files, go back and search now. Files written purely from training data without web verification are low-quality research.

**Step 5b — Write all 5 files.** Create each file one at a time using your file write tool. Each file is a separate write operation. Do NOT combine files. Do NOT skip files. **Before writing each file, read the corresponding template** from `@./templates/research-project/` to understand the expected structure. Base your content on the web research findings from Step 5b-pre.

**File 1 of 5 — Write `.planning/research/STACK.md` to disk now.**
First, read the template at `@./templates/research-project/STACK.md` for the expected structure. Then write the stack research based on your web search findings. Include confidence levels and cite sources. The file MUST contain these exact `##` headers:
- `## Recommended Stack`
- `## Alternatives Considered`
- `## What NOT to Use` (with reasons)
- `## Versions`

> 🛑 STOP. Confirm: did you write `.planning/research/STACK.md` to the filesystem? If you only thought about the stack but did not create the file, go back and create it now.

**File 2 of 5 — Write `.planning/research/FEATURES.md` to disk now.**
First, read the template at `@./templates/research-project/FEATURES.md` for the expected structure. Then write the features research based on your web search findings. The file MUST contain these exact `##` headers:
- `## Table Stakes` (must-haves)
- `## Differentiators` (nice-to-haves)
- `## Anti-Features` (what to avoid)

**File 3 of 5 — Write `.planning/research/ARCHITECTURE.md` to disk now.**
First, read the template at `@./templates/research-project/ARCHITECTURE.md` for the expected structure. Then write the architecture research based on your web search findings. The file MUST contain these exact `##` headers:
- `## Component Boundaries`
- `## Data Flow`
- `## Build Order` (suggested sequence)
- `## Integration Points`

**File 4 of 5 — Write `.planning/research/PITFALLS.md` to disk now.**
First, read the template at `@./templates/research-project/PITFALLS.md` for the expected structure. Then write the pitfalls research based on your web search findings. The file MUST contain these exact `##` headers:
- `## Common Mistakes`
- `## Warning Signs`
- `## Prevention Strategies`

**File 5 of 5 — Write `.planning/research/SUMMARY.md` to disk now.**
First, read the template at `@./templates/research-project/SUMMARY.md` for the expected structure. Then synthesize the 4 files above into a summary. The file MUST contain these exact `##` headers:
- `## Recommended Stack`
- `## Table Stakes Features`
- `## Key Architecture Decisions`
- `## Top Pitfalls`

**Step 5c — Verify all 5 files exist on disk.** Run this verification command now. Do not skip it.

> 🔴 **HARD GATE — You MUST run this command. If you skip it and proceed to Step 6, the workflow has FAILED.**

```bash
node -e "const fs=require('fs'),path=require('path');const dir='.planning/research/';const checks={'STACK.md':['Recommended Stack','What NOT to Use'],'FEATURES.md':['Table Stakes','Differentiators'],'ARCHITECTURE.md':['Component Boundaries','Data Flow'],'PITFALLS.md':['Common Mistakes','Prevention Strategies'],'SUMMARY.md':['Recommended Stack','Top Pitfalls']};const missing=[];for(const[file,sections]of Object.entries(checks)){const fp=path.join(dir,file);if(!fs.existsSync(fp)){missing.push(file+' MISSING');continue;}const c=fs.readFileSync(fp,'utf8');for(const s of sections){if(!c.includes('## '+s))missing.push(file+': missing ## '+s);}}if(missing.length){console.log('RESEARCH FAILED — files missing or incomplete:\\n'+missing.join('\\n'));console.log('\\nGo back and create the missing files. Do NOT proceed to requirements.');process.exit(1);}console.log('RESEARCH VERIFIED OK — all 5 files present with required sections');"
```

> 🛑 **If the command prints `RESEARCH FAILED` or exits with code 1:** Go back and create or fix the missing files. Run the verification again. You MUST see `RESEARCH VERIFIED OK` before continuing.
>
> **If you did not run the command at all:** You have skipped verification. Go back and run it now. You cannot proceed to Step 5d without a passing verification.

**Step 5d — Present findings.** Read all 5 research files from disk now and present their findings in full. Do NOT summarize into 3 bullets — display the actual content from the files you wrote. Display this exact structure, populated from the actual file contents:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCH COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Recommended Stack
[Full content from STACK.md ## Recommended Stack — include all items, versions, and rationale]

**Alternatives Considered:** [From STACK.md ## Alternatives Considered]
**What NOT to Use:** [From STACK.md ## What NOT to Use — include reasons]

## Features
**Table Stakes (must have for v1):**
[Full list from FEATURES.md ## Table Stakes]

**Differentiators (v2 candidates):**
[Full list from FEATURES.md ## Differentiators]

**Anti-Features (avoid):**
[From FEATURES.md ## Anti-Features]

## Architecture
**Component Boundaries:**
[From ARCHITECTURE.md ## Component Boundaries]

**Data Flow:**
[From ARCHITECTURE.md ## Data Flow]

**Recommended Build Order:**
[From ARCHITECTURE.md ## Build Order]

**Integration Points:**
[From ARCHITECTURE.md ## Integration Points]

## Top Pitfalls to Avoid
[Full list from PITFALLS.md ## Common Mistakes]

**Warning Signs:**
[From PITFALLS.md ## Warning Signs]

**Prevention Strategies:**
[From PITFALLS.md ## Prevention Strategies]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Files written: .planning/research/STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md, SUMMARY.md
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then ask exactly this:

"Research is complete. Does this align with what you had in mind, or are there stack/architecture decisions you want to override before I define requirements? Reply **continue** to proceed, or tell me what to change."

> 🛑 **HARD GATE — Wait for the user's reply before proceeding to Step 6.** Do NOT automatically continue to requirements. Do NOT write REQUIREMENTS.md. The user must explicitly say "continue" or give a change request. If they request changes, update the relevant research file(s) and re-display the affected section, then re-ask this question.

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

<persona_context>
You are now the **learnship roadmapper**. Transform requirements into a phased roadmap.
Every v1 requirement maps to exactly one phase. Every phase has observable success criteria.
Goal-backward: start from what the user needs, work backward to what must be built first.
Dependencies drive order. Phases should be deliverable — each produces something testable.
</persona_context>

Read `@./agents/roadmapper.md` for the full persona definition.

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

**Substep 8a-pre — Check for existing context files.** Run this command now:

```bash
node -e "const fs=require('fs');const files=['AGENTS.md','CLAUDE.md','GEMINI.md','.cursorrules'];const found=files.filter(f=>fs.existsSync(f));if(found.length){console.log('EXISTING: '+found.join(', '));}else{console.log('NONE FOUND');}"
```

**If the command prints `EXISTING:`** — Ask the user:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► EXISTING CONTEXT FILES DETECTED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

I found existing context file(s): [list from command output]

What would you like to do?

 1. Replace (recommended for new learnship projects)
    → Overwrite with learnship's AGENTS.md

 2. Merge
    → Keep your existing content, add learnship sections

 3. Keep separate
    → Write AGENTS.md alongside your existing file(s)

Reply 1, 2, or 3.
```

> 🔴 **HARD GATE — Wait for the user's reply. Do NOT auto-decide.**

- **Replace (1):** Continue to substep 8a. The old files will be overwritten.
- **Merge (2):** Read the existing file(s) first, then in substep 8b, append learnship sections that are missing (Soul, Principles, Request Routing Protocol, etc.) while preserving the user's existing content at the top.
- **Keep separate (3):** Continue to substep 8a. Write `AGENTS.md` as a new file. Leave existing files untouched.

**If the command prints `NONE FOUND`:** Continue directly to substep 8a.

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
node -e "const fs=require('fs');if(!fs.existsSync('AGENTS.md')){console.log('AGENTS.md NOT FOUND');process.exit(1);}const f=fs.readFileSync('AGENTS.md','utf8');const required=['Soul','Principles','Request Routing Protocol','Platform Context','Current Phase','Project Structure','Tech Stack','Skills','Regressions'];const missing=required.filter(s=>!f.includes('## '+s));if(missing.length){console.log('AGENTS.md INCOMPLETE — missing sections:\\n'+missing.map(s=>'  ## '+s).join('\\n'));process.exit(1);}const verbatim=['pair programmer','Direct, no fluff','Have opinions','Friction Is Signal','Surgical Change','Nothing Extra','Understand First','decision tree'];const missingV=verbatim.filter(s=>!f.includes(s));if(missingV.length){console.log('AGENTS.md TEMPLATE VIOLATION — these verbatim phrases are missing (did you rewrite instead of copy?):\\n'+missingV.join('\\n'));process.exit(1);}console.log('AGENTS.md VERIFIED OK — all '+required.length+' sections present, verbatim content intact');"
```

> 🛑 **If the command prints `INCOMPLETE` or `TEMPLATE VIOLATION` or exits with code 1:** The AGENTS.md is broken. Re-read `@./templates/agents.md` and fix the missing sections or restore the verbatim content. Run the verification again. You MUST see `AGENTS.md VERIFIED OK` before continuing to Step 9.

**If `commit_mode` is `auto`:**
```bash
git add AGENTS.md && git commit -m "docs: add AGENTS.md with project context"
```



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

💡 Building on an existing codebase? Run `/ideate` for codebase-grounded idea generation — it scans your code for hotspots and improvement opportunities.

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
