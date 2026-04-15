---
description: Interactive settings editor for .planning/config.json
---

# Settings

Interactive configuration editor for the current project. Updates `.planning/config.json` with your preferences.

**Usage:** `settings`

## Step 1: Ensure Config Exists

```bash
node -e "const fs=require('fs'); console.log(fs.existsSync('.planning/config.json') ? 'exists' : 'missing')"
```

If missing, create from template:
```bash
cp templates/config.json .planning/config.json 2>/dev/null || cat > .planning/config.json << 'EOF'
{
  "mode": "interactive",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "test_first": false,
  "planning": {
    "commit_docs": true,
    "commit_mode": "auto",
    "search_gitignored": false
  },
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "validation": true,
    "review": true,
    "solutions_search": true,
    "security_enforcement": true,
    "discuss_mode": "discuss",
    "tdd_mode": false
  },
  "parallelization": {
    "enabled": false,
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
    "auto_after_verify": false
  },
  "ship": {
    "auto_test": true,
    "conventional_commits": true,
    "pr_template": true
  },
  "hooks": {
    "context_warnings": true
  },
  "git": {
    "branching_strategy": "none",
    "phase_branch_template": "phase-{phase}-{slug}",
    "milestone_branch_template": "{milestone}-{slug}"
  }
}
EOF
```

## Step 2: Read Current Config

```bash
cat .planning/config.json
```

Parse current values to use as defaults in the prompts.

## Step 3: Present Settings Menu

Display current settings and ask what to change:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► SETTINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Current configuration:

[1] Mode:              [current] (yolo | interactive)
[2] Granularity:       [current] (coarse | standard | fine)
[3] Model profile:     [current] (quality | balanced | budget)
[4] Learning mode:     [current] (auto | manual)
[5] Test-first (TDD):  [on/off]
[6] Research agent:    [on/off]
[7] Plan check agent:  [on/off]
[8] Verifier agent:    [on/off]
[9] Test validation:   [on/off]
[10] Review workflow:   [on/off]
[11] Solutions search:  [on/off]
[12] Security enforcement: [on/off]
[13] Auto-review after verify: [on/off]
[14] Ship: auto-test:   [on/off]
[15] Ship: conventional commits: [on/off]
[16] Ship: PR template: [on/off]
[17] Parallelization:   [on/off] (max agents: [N])
[18] Git branching:     [current] (none | phase | milestone)
[19] Commit docs:       [on/off]
[20] Safety: confirm destructive: [on/off]
[21] Context warnings:  [on/off]

Enter a number to change a setting, or 'done' to save.
```

Wait for selection. Repeat until user types "done".

## Step 4: Change Selected Setting

For each selected setting, explain the options and ask for the new value:

**[1] Mode:**
```
Mode controls how much Cascade auto-approves vs. asks you:
- yolo: auto-approves decisions, fastest flow
- interactive: confirms at each step, more control

Current: [current]. New value?
```

**[2] Granularity:**
```
Granularity controls phase size:
- coarse: 3-5 phases (broad strokes)
- standard: 5-8 phases (default)
- fine: 8-12 phases (more granular, better for complex projects)

Current: [current]. New value?
```

**[3] Model profile:**
```
Model profile controls which model tier each agent uses:
- quality: large-tier for all decision-making agents (highest cost, best results)
- balanced: large for planning, medium for execution (default — good balance)
- budget: medium for writing code, small for research/verification (lowest cost)

Current: [current]. New value?
```

**[4] Learning mode:**
```
Learning mode controls when learning actions are offered:
- auto: offered automatically at workflow checkpoints (default)
- manual: only when you explicitly invoke @agentic-learning

Current: [current]. New value?
```

**[5] Test-first (TDD):**
```
Test-first mode enforces red-green-refactor during execute-phase:
- on: write failing test → verify red → implement → verify green
- off: write tests alongside implementation (default)

Current: [current]. New value? (on/off)
```

**[6-8] Agent toggles (research / plan_check / verifier):**
```
[Research / Plan check / Verifier] agent:
- on: agent runs (recommended for production work)
- off: skip this agent (faster, for familiar domains or prototyping)

Current: [current]. New value? (on/off)
```

**[9] Test validation:**
```
Test validation maps automated test coverage to requirements during plan-phase.
- on: plans include automated verify commands per task (recommended)
- off: skip validation research (good for rapid prototyping)

Current: [current]. New value? (on/off)
```

**[10] Review workflow:**
```
Multi-persona code review after verification:
- on: /review is available and can be auto-triggered (recommended)
- off: skip review workflow

Current: [current]. New value? (on/off)
```

**[11] Solutions search:**
```
Search .planning/solutions/ for prior art during plan-phase:
- on: reuse patterns from solved problems (recommended)
- off: skip solutions search

Current: [current]. New value? (on/off)
```

**[12] Auto-review after verify:**
```
Automatically trigger /review after verify-work passes:
- on: review starts immediately after successful verification
- off: run /review manually when ready (default)

Current: [current]. New value? (on/off)
```

**[13-15] Ship pipeline (auto_test / conventional_commits / pr_template):**
```
[Auto-test / Conventional commits / PR template]:
- on: enabled (recommended)
- off: disabled

Current: [current]. New value? (on/off)
```

**[16] Git branching:**
```
Branching strategy:
- none: no automatic branches (good for solo work)
- phase: create a branch at each execute-phase (good for code review per phase)
- milestone: one branch for all phases in a milestone (good for release branches)

Current: [current]. New value?
```

**[17] Commit docs:**
```
Whether .planning/ files are committed to git:
- on: planning artifacts tracked in git (default)
- off: keep .planning/ local only (add to .gitignore for privacy)

Current: [current]. New value? (on/off)
```

## Step 5: Save Config

After user types "done", read the current config, apply all changes, and write the complete updated JSON. Preserve any fields not shown in the menu (gates, hooks, etc.) — never drop fields the user didn't modify.

```bash
node -e "const fs=require('fs');const c=JSON.parse(fs.readFileSync('.planning/config.json','utf8'));/* apply changes to c */;fs.writeFileSync('.planning/config.json',JSON.stringify(c,null,2)+'\n');"
```

## Step 6: Commit

```bash
git add .planning/config.json
git commit -m "chore(config): update project settings"
```

## Step 7: Confirm

```
Settings saved to .planning/config.json

Changes made:
- [setting]: [old value] → [new value]

These settings apply to all future workflow runs in this project.
```
