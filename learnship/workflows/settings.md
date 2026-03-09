---
description: Interactive settings editor for .planning/config.json
---

# Settings

Interactive configuration editor for the current project. Updates `.planning/config.json` with your preferences.

**Usage:** `settings`

## Step 1: Ensure Config Exists

```bash
test -f .planning/config.json && echo "exists" || echo "missing"
```

If missing, create from template:
```bash
cp templates/config.json .planning/config.json 2>/dev/null || cat > .planning/config.json << 'EOF'
{
  "mode": "yolo",
  "granularity": "standard",
  "model_profile": "balanced",
  "learning_mode": "auto",
  "planning": {
    "commit_docs": true,
    "search_gitignored": false
  },
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true,
    "nyquist_validation": true
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
[5] Research agent:    [on/off]
[6] Plan check agent:  [on/off]
[7] Verifier agent:    [on/off]
[8] Nyquist validation:[on/off]
[9] Git branching:     [current] (none | phase | milestone)
[10] Commit docs:      [on/off]

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
- quality: Opus for all decision-making agents (highest cost, best results)
- balanced: Opus for planning, Sonnet for execution (default — good balance)
- budget: Sonnet for writing code, Haiku for research/verification (lowest cost)

Current: [current]. New value?
```

**[4] Learning mode:**
```
Learning mode controls when learning actions are offered:
- auto: offered automatically at workflow checkpoints (default)
- manual: only when you explicitly invoke @agentic-learning

Current: [current]. New value?
```

**[5-7] Agent toggles (research / plan_check / verifier):**
```
[Research / Plan check / Verifier] agent:
- on: agent runs (recommended for production work)
- off: skip this agent (faster, for familiar domains or prototyping)

Current: [current]. New value? (on/off)
```

**[8] Nyquist validation:**
```
Nyquist validation maps automated test coverage to requirements during plan-phase.
- on: plans include automated verify commands per task (recommended)
- off: skip validation research (good for rapid prototyping)

Current: [current]. New value? (on/off)
```

**[9] Git branching:**
```
Branching strategy:
- none: no automatic branches (good for solo work)
- phase: create a branch at each execute-phase (good for code review per phase)
- milestone: one branch for all phases in a milestone (good for release branches)

Current: [current]. New value?
```

**[10] Commit docs:**
```
Whether .planning/ files are committed to git:
- on: planning artifacts tracked in git (default)
- off: keep .planning/ local only (add to .gitignore for privacy)

Current: [current]. New value? (on/off)
```

## Step 5: Save Config

After user types "done", write the updated config:

```bash
cat > .planning/config.json << EOF
{
  "mode": "[value]",
  "granularity": "[value]",
  "model_profile": "[value]",
  "learning_mode": "[value]",
  "planning": {
    "commit_docs": [true/false],
    "search_gitignored": false
  },
  "workflow": {
    "research": [true/false],
    "plan_check": [true/false],
    "verifier": [true/false],
    "nyquist_validation": [true/false]
  },
  "git": {
    "branching_strategy": "[value]",
    "phase_branch_template": "phase-{phase}-{slug}",
    "milestone_branch_template": "{milestone}-{slug}"
  }
}
EOF
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
