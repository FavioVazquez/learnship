---
description: Start a new milestone cycle on an existing project after a prior milestone is complete
---

# New Milestone

Start the next version cycle for an existing project. Loads what shipped previously, gathers new goals, optionally researches new feature domains, defines scoped requirements, and creates a new phased roadmap.

**Use after:** `/complete-milestone` has archived the previous milestone.

## Step 1: Load Context

Read all prior project context:
```bash
cat .planning/PROJECT.md
cat .planning/STATE.md
cat .planning/milestones/
ls .planning/milestones/ 2>/dev/null
```

Display what shipped in the last milestone:
```
## Last milestone: [VERSION]
[2-3 sentences from the milestone archive summarizing what was built]

Pending todos carried forward:
- [Any todos from STATE.md]
```

## Step 2: Gather Milestone Goals

Ask openly: **"What do you want to build in this milestone?"**

If a milestone scope was already discussed (look for `.planning/MILESTONE-CONTEXT.md`), load it and confirm:

```
ask_user_question([
  {
    header: "Prior Context Found",
    question: "I found a milestone context file from a prior discussion. Use it as the starting point?",
    multiSelect: false,
    options: [
      { label: "Yes", description: "Proceed with the scope from the prior discussion" },
      { label: "Start fresh", description: "Discard prior context and ask from scratch" }
    ]
  }
])
```

Follow the thread. When you have enough to write clear goals, ask for confirmation before continuing.

## Step 3: Determine Version

Read the last version from `.planning/milestones/`:
```bash
ls .planning/milestones/ | grep -E "^v[0-9]" | sort -V | tail -3
# PowerShell: Get-ChildItem .planning/milestones/ | Where-Object { $_.Name -match '^v[0-9]' } | Sort-Object Name | Select-Object -Last 3
```

Propose the next version (e.g., `v1.0 → v1.1`, or `v2.0` for a major scope change). Confirm with user or let them specify.

## Step 4: Update PROJECT.md

Add or update the current milestone section:
```markdown
## Current Milestone: [VERSION] [Name]

**Goal:** [One sentence describing this milestone's focus]

**Target features:**
- [Feature 1]
- [Feature 2]
```

Update the Active requirements section and "Last updated" footer.

## Step 5: Update STATE.md

Reset current position:
```markdown
## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Defining requirements
Last activity: [today] — Milestone [VERSION] started
```

Keep the Accumulated Context section (decisions, blockers from prior milestones carry forward).

## Step 6: Commit Initial State

```bash
git add .planning/PROJECT.md .planning/STATE.md
git commit -m "docs: start milestone [VERSION] [Name]"
```

If a MILESTONE-CONTEXT.md was consumed, delete it:
```bash
git rm .planning/MILESTONE-CONTEXT.md 2>/dev/null || true
```

## Step 6a: Codebase Map Check

Check if the codebase has changed significantly since the last map:

```bash
node -e "
const fs=require('fs');
const hasCbMap=fs.existsSync('.planning/codebase');
if(!hasCbMap){console.log('NO_MAP');}
else{
  const mapFiles=fs.readdirSync('.planning/codebase').filter(f=>f.endsWith('.md'));
  const mapAge=mapFiles.length>0?Math.max(...mapFiles.map(f=>fs.statSync('.planning/codebase/'+f).mtimeMs)):0;
  const daysSinceMap=Math.floor((Date.now()-mapAge)/(1000*60*60*24));
  console.log('HAS_MAP');console.log('map_files: '+mapFiles.length);console.log('days_since_update: '+daysSinceMap);
}
"
```

**If `NO_MAP`:** Offer codebase mapping:

```
ask_user_question([
  {
    header: "Codebase Map",
    question: "No codebase map found. The codebase may have evolved since the last milestone. Want to map it before planning new features?",
    multiSelect: false,
    options: [
      { label: "Map codebase (Recommended)", description: "Run /map-codebase to analyze current architecture, then return here" },
      { label: "Skip", description: "Continue without mapping — I know the current state" }
    ]
  }
])
```

- **Map codebase:** Tell the user: "Run `/map-codebase` first, then come back to `/new-milestone`." Then **STOP. Exit this workflow.**
- **Skip:** Continue to Step 6b.

**If `HAS_MAP` and `days_since_update` > 30:** Offer to refresh:

```
ask_user_question([
  {
    header: "Stale Codebase Map",
    question: "Your codebase map is [N] days old. Want to refresh it before planning new features?",
    multiSelect: false,
    options: [
      { label: "Refresh map", description: "Run /map-codebase to update, then return here" },
      { label: "Use existing map", description: "Current map is close enough" }
    ]
  }
])
```

- **Refresh map:** Tell the user: "Run `/map-codebase` first, then come back to `/new-milestone`." Then **STOP. Exit this workflow.**
- **Use existing map:** Continue to Step 6b.

**If `HAS_MAP` and `days_since_update` <= 30:** Continue silently to Step 6b.

## Step 6b: Config Review

Check if the project config has all v2 keys:

```bash
node -e "
const fs=require('fs');
try{
  const cfg=JSON.parse(fs.readFileSync('.planning/config.json','utf8'));
  const missing=[];
  if(!('model_profile' in cfg)) missing.push('model_profile');
  if(!('test_first' in cfg)) missing.push('test_first');
  if(!('parallelization' in cfg)) missing.push('parallelization');
  if(!cfg.workflow||!('review' in cfg.workflow)) missing.push('workflow.review');
  if(!cfg.workflow||!('solutions_search' in cfg.workflow)) missing.push('workflow.solutions_search');
  if(!cfg.review||!('auto_after_verify' in cfg.review)) missing.push('review.auto_after_verify');
  if(!cfg.ship) missing.push('ship.*');
  if(!cfg.planning||!('commit_mode' in cfg.planning)) missing.push('planning.commit_mode');
  if(missing.length)console.log('MISSING: '+missing.join(', '));
  else console.log('CONFIG_COMPLETE');
}catch(e){console.log('NO_CONFIG');}
"
```

**If MISSING or NO_CONFIG:** Offer to update config with v2 defaults:

```
Your config is missing some v2 settings: [list]

These control: multi-persona review, solutions search, ship pipeline, TDD mode.
Want me to add them with recommended defaults? (yes/no)
```

If yes: merge missing keys into `.planning/config.json` using the defaults from `@./templates/config.json`. Show the updated config for confirmation.

**If CONFIG_COMPLETE:** Continue silently.

## Step 7: Research Decision

> **🔴 MANDATORY USER CHOICE — You must ask this question and wait for a reply. You are NOT allowed to decide this yourself, even if the domain seems trivial, familiar, or well-understood. The user decides. Always.**

Read `workflow.research` from `.planning/config.json`.

Ask: **"Research the domain for the new features before defining requirements?"**
- **Research first** (recommended) — investigate new capabilities' ecosystem
- **Skip research** — domain is familiar

> 🛑 STOP. Wait for the user's explicit choice. Do not default to either option. Do not reason about whether research is needed — that is the user's call. Do not proceed until the user replies.

Update config accordingly:
```bash
# Edit .planning/config.json: set workflow.research to true or false
```

**If Research first:**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RESEARCHING NEW MILESTONE FEATURES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

<persona_context>
You are now the **learnship project researcher**. Your training data is stale — verify before asserting.
Use search_web for ecosystem discovery (always include current year), read_url_content for official docs.
Tag confidence: HIGH/MEDIUM/LOW. Be comprehensive but opinionated.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[36m  learnship-project-researcher(Your training data is stale — verify before asserting)\033[0m\n\n"
> ```

Read `@./agents/project-researcher.md` for the full persona definition. In project research mode, investigate the new feature domain:
- Focus ONLY on the new capabilities — not the existing codebase
- Write STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md to `.planning/research/`
- Synthesize into `.planning/research/SUMMARY.md`

## Step 8: Define Requirements

Read PROJECT.md, existing REQUIREMENTS traceability (in milestones archive), and research (if run).

Present feature categories for this milestone. For each, have the user select what's in scope (multi-select). Apply REQ-IDs continuing from the last milestone's numbering (or restarting per-domain).

Create `.planning/REQUIREMENTS.md` fresh for this milestone:
- v1 requirements with REQ-IDs
- v2 requirements (next milestone candidates)
- Out-of-scope items with reasoning

Present for confirmation. Iterate if needed.

```bash
git add .planning/REQUIREMENTS.md
git commit -m "docs: define [VERSION] requirements"
```

## Step 9: Create Roadmap

<persona_context>
You are now the **learnship roadmapper**. Transform requirements into a phased roadmap.
Every v1 requirement maps to exactly one phase. Every phase has observable success criteria.
Dependencies drive order. Phases should be deliverable.
</persona_context>

> **Announce persona** — print this before proceeding:
> ```bash
> printf "\n  \033[35m  learnship-roadmapper(Transform requirements into a phased roadmap)\033[0m\n\n"
> ```

Read `@./agents/roadmapper.md` for the full persona definition. Read PROJECT.md, REQUIREMENTS.md, research (if exists).

Create a new `.planning/ROADMAP.md` with phases for this milestone only. Map every v1 requirement to exactly one phase.

Present the proposed roadmap for approval. Iterate if needed.

Update STATE.md to reflect the new phase count and first phase.

```bash
git add .planning/ROADMAP.md .planning/STATE.md
git commit -m "docs: create [VERSION] roadmap ([N] phases)"
```

## Step 10: Update AGENTS.md

If `AGENTS.md` exists at the project root, update:

1. **Current Phase block** — reset for new milestone:
```markdown
## Current Phase

**Milestone:** [VERSION] — [Milestone Name]
**Phase:** 1 — [Phase 1 Name from new ROADMAP.md]
**Status:** planning
**Last updated:** [today's date]
```

2. **Tech Stack** — update if the new milestone introduces new libraries or frameworks.

```bash
git add AGENTS.md
git commit -m "docs: update AGENTS.md — milestone [VERSION] started"
```

## Step 11: Done

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► MILESTONE [VERSION] INITIALIZED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

**[VERSION] — [Name]** — [N] phases, [X] requirements

▶ Next: discuss-phase 1 → plan-phase 1 → execute-phase 1 → verify-work 1 → review → ship → compound

💡 Not sure what to prioritize? Run `/ideate` for codebase-grounded idea generation.
💡 For ambitious milestones, consider running `/challenge` to stress-test the scope before starting Phase 1.
💡 Working near sensitive areas? Run `/guard [scope]` to activate safety mode.
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** New milestone, new mental model. Before writing a line of code:
>
> `@agentic-learning brainstorm [milestone topic]` — Talk through the new features before committing to an approach. Surfaces blind spots before planning starts.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning brainstorm [milestone topic]` before planning starts to surface approach alternatives."*
