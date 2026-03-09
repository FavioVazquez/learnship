---
description: Show all available workflows with descriptions and when to use them
---

# Help

Show all available workflows, organized by category.

## Start Here

You only need to remember **5 commands** to use learnship effectively:

| Command | When to use |
|---------|-------------|
| `/ls` | "Where am I? What's next?" — works for new and returning users |
| `/next` | Auto-pilot — reads state and runs the right workflow for you |
| `/new-project` | Starting a brand new project |
| `/quick "..."` | One-off task with atomic commit, no ceremony |
| `/help` | This screen — see all 42 commands |

Everything else below is discoverable from `/ls` as you go.

---

## All Workflows

### Core Workflow — build products phase by phase

| Workflow | What it does |
|----------|-------------|
| `/new-project` | Full init: questioning → research → requirements → roadmap |
| `/discuss-phase [N]` | Capture implementation decisions before planning |
| `/plan-phase [N]` | Research + create + verify plans |
| `/execute-phase [N]` | Wave-ordered execution of all plans |
| `/verify-work [N]` | Manual UAT with auto-diagnosis and fix planning |
| `/complete-milestone` | Archive milestone, tag release, prepare next version |
| `/audit-milestone` | Pre-release: requirement coverage + stub detection |
| `/new-milestone [name]` | Start next version cycle after completing a milestone |

### Navigation — know where you are, resume work

| Workflow | What it does |
|----------|-------------|
| `/ls` | Status + next step + offer to run it — **start every session here** |
| `/next` | Auto-pilot: reads state and runs the right workflow automatically |
| `/progress` | Same as `/ls` — status overview + smart routing |
| `/resume-work` | Restore full context from last session |
| `/pause-work` | Save handoff file when stopping mid-phase |
| `/quick [description]` | Ad-hoc task with full guarantees and atomic commits |
| `/help` | Show this reference |

### Phase Management — shape the roadmap mid-milestone

| Workflow | What it does |
|----------|-------------|
| `/add-phase [description]` | Append new phase to roadmap |
| `/insert-phase [N] [description]` | Insert urgent work between existing phases |
| `/remove-phase [N]` | Remove a future phase and renumber |
| `/research-phase [N]` | Deep research only, no plans yet |
| `/list-phase-assumptions [N]` | Preview intended approach before planning |
| `/plan-milestone-gaps` | Create fix phases from audit findings |

### Codebase Intelligence — understand what exists

| Workflow | What it does |
|----------|-------------|
| `/map-codebase` | Analyze existing codebase (brownfield entry point) |
| `/discovery-phase [N]` | Map unfamiliar code area — files, deps, risks — before planning |
| `/debug [description]` | Systematic triage → diagnose → fix with session state |
| `/diagnose-issues [N]` | Batch-diagnose all UAT issues — groups by root cause, proposes fix plan |
| `/execute-plan [N] [id]` | Run a single PLAN.md in isolation (re-run failed plan) |
| `/validate-phase [N]` | Retroactive test coverage audit for a phase |

### Task Management — capture and act on ideas

| Workflow | What it does |
|----------|-------------|
| `/add-todo [description]` | Capture an idea without interrupting flow |
| `/check-todos` | Review and act on captured todos |
| `/add-tests [N]` | Generate unit and E2E tests post-execution |

### Decision Intelligence — institutional memory

| Workflow | What it does |
|----------|-------------|
| `/decision-log [description]` | Capture a decision with context, alternatives, and rationale |
| `/knowledge-base` | Aggregate all decisions + lessons into searchable KNOWLEDGE.md |
| `/knowledge-base search [query]` | Search the project knowledge base |

### Milestone Intelligence — reflect and hand off

| Workflow | What it does |
|----------|-------------|
| `/discuss-milestone [version]` | Capture goals and anti-goals before new-milestone |
| `/milestone-retrospective` | 5-question retrospective after complete-milestone |
| `/transition` | Write full handoff document for collaborator or fresh session |

### Maintenance — keep the project healthy

| Workflow | What it does |
|----------|-------------|
| `/settings` | Interactive config editor for `.planning/config.json` |
| `/set-profile [quality\|balanced\|budget]` | One-step model profile switch |
| `/health` | Project health check: stale files, missing artifacts |
| `/health --repair` | Auto-fix repairable health issues |
| `/cleanup` | Archive completed milestone phase directories |
| `/update` | Update the platform itself to the latest version |
| `/reapply-patches` | Restore local edits after an update |

---

## Quick Reference

**Starting fresh:**
```
/new-project
```

**Standard phase loop:**
```
/discuss-phase N → /plan-phase N → /execute-phase N → /verify-work N
```

**Quick fix:**
```
/quick "description of what to do"
```

**After a break:**
```
/ls           (where am I? — offers to run next step)
/next         (just keep moving — auto-pilot)
/resume-work  (full context restoration)
```

**Before releasing:**
```
/audit-milestone → /plan-milestone-gaps (if gaps) → /complete-milestone
```

---

## Configuration

Edit project settings with `/settings` or directly:
```bash
cat .planning/config.json
```

Key settings: `mode` (yolo/interactive), `model_profile` (quality/balanced/budget), `learning_mode` (auto/manual).

See `README.md` for the full configuration reference.
