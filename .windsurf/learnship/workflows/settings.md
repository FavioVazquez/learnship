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
  "mode": "auto",
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
    "discuss_mode": "discuss",    // "discuss" (standard 4-exchange) or "deep" (extended questioning, walks every branch until shared understanding)
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

## Step 3: Present Settings

Display the settings banner, then present settings using structured question rounds. Use your platform's interactive question tool, or numbered text lists if unavailable. Pre-select current values where the tool supports it.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► SETTINGS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Round 1 — Core settings (4 questions):**

```
ask_user_question([
  {
    header: "Model Profile",
    question: "Which model quality tier for agents?",
    multiSelect: false,
    options: [
      { label: "Balanced (Recommended)", description: "Large for planning, medium for execution" },
      { label: "Quality", description: "Large-tier for all agents (highest cost)" },
      { label: "Budget", description: "Medium for code, small for research (lowest cost)" },
      { label: "Inherit", description: "Use current session model for all agents" }
    ]
  },
  {
    header: "Mode",
    question: "Working style?",
    multiSelect: false,
    options: [
      { label: "Auto", description: "Auto-approve steps, just execute" },
      { label: "Interactive", description: "Confirm at each step, more control" }
    ]
  },
  {
    header: "Granularity",
    question: "Phase size?",
    multiSelect: false,
    options: [
      { label: "Coarse", description: "3-5 phases, broad strokes" },
      { label: "Standard", description: "5-8 phases, balanced (default)" },
      { label: "Fine", description: "8-12 phases, granular for complex projects" }
    ]
  },
  {
    header: "Learning",
    question: "When should learning partner activate?",
    multiSelect: false,
    options: [
      { label: "Auto", description: "Offer at natural checkpoints (default)" },
      { label: "Manual", description: "Only when you invoke @agentic-learning" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

**Round 2 — Workflow agents (6 questions):**

```
ask_user_question([
  {
    header: "Research",
    question: "Spawn researcher agent before planning?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Research domain before planning each phase" },
      { label: "No", description: "Skip research, plan directly" }
    ]
  },
  {
    header: "Plan Check",
    question: "Verify plans before execution?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Catch gaps before execution starts" },
      { label: "No", description: "Execute without plan verification" }
    ]
  },
  {
    header: "Verifier",
    question: "Verify phase completion?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Confirm deliverables after execution" },
      { label: "No", description: "Skip post-execution verification" }
    ]
  },
  {
    header: "Review",
    question: "Multi-persona code review?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Correctness, security, performance review" },
      { label: "No", description: "Skip review" }
    ]
  },
  {
    header: "Solutions",
    question: "Search prior solutions during planning?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Check .planning/solutions/ for reusable patterns" },
      { label: "No", description: "Plan without searching prior solutions" }
    ]
  },
  {
    header: "TDD",
    question: "Test-first mode?",
    multiSelect: false,
    options: [
      { label: "No (Recommended)", description: "Write tests alongside implementation" },
      { label: "Yes", description: "Red-green-refactor: failing test first, then implement" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

**Round 3 — Pipeline & git (4 questions):**

```
ask_user_question([
  {
    header: "Ship Pipeline",
    question: "Ship pipeline preferences?",
    multiSelect: true,
    options: [
      { label: "Auto-test before shipping (Recommended)", description: "Run tests before every ship" },
      { label: "Conventional commits (Recommended)", description: "Use feat:, fix:, docs: prefixes" },
      { label: "Auto-generate PR description (Recommended)", description: "Create PR body from commits" }
    ]
  },
  {
    header: "Git Tracking",
    question: "Commit planning docs to git?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Planning docs tracked in version control" },
      { label: "No", description: "Keep .planning/ local-only" }
    ]
  },
  {
    header: "Branching",
    question: "Git branching strategy?",
    multiSelect: false,
    options: [
      { label: "None (Recommended)", description: "Commit directly to current branch" },
      { label: "Per Phase", description: "Create branch for each phase" },
      { label: "Per Milestone", description: "One branch for entire milestone" }
    ]
  },
  {
    header: "Context Warnings",
    question: "Context window warnings?",
    multiSelect: false,
    options: [
      { label: "Yes (Recommended)", description: "Warn when context usage is high" },
      { label: "No", description: "Disable warnings, allow natural auto-compact" }
    ]
  }
])
```

> 🛑 STOP. Wait for the user's reply before continuing.

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
