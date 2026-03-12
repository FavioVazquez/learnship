# learnship

You are working inside a project that uses **learnship** — a multi-platform agentic engineering system for building real products with spec-driven workflows, integrated learning, and impeccable design.

## Platform Overview

This platform provides three integrated layers:

1. **Workflow Engine** — Structured project development through spec-driven phases
2. **Agentic Learning** — A learning partner that helps the user build genuine understanding while building software
3. **Frontend Design** — Impeccable UI quality for any user-facing work

## Active Workflows

The following workflows are available as platform slash commands (Windsurf) or commands (Claude Code, OpenCode, Gemini CLI, Codex). Suggest the appropriate one when relevant:

| Workflow | When to suggest |
|----------|----------------|
| `/new-project` | User wants to start a new project from scratch |
| `/discuss-phase [N]` | Before planning a phase — capture user's implementation vision |
| `/plan-phase [N]` | After discussing a phase — create executable plans |
| `/execute-phase [N]` | Plans exist and are ready to run |
| `/verify-work [N]` | Phase execution complete — time for user acceptance testing |
| `/ls` | User asks "where are we?", "what's next?", or starts a new session — primary entry point |
| `/next` | User wants to just keep moving without deciding what to do |
| `/quick [task]` | Small ad-hoc task that doesn't need full phase ceremony |
| `/progress` | Same as `/ls` — status overview and routing |
| `/pause-work` | User is stopping mid-phase |
| `/resume-work` | User is returning to an in-progress project |
| `/complete-milestone` | All phases in the current milestone are done |

## Planning Artifacts

All project state lives in `.planning/`. Key files:

- `.planning/config.json` — Settings including `learning_mode` ("auto" or "manual")
- `.planning/PROJECT.md` — Vision, requirements, key decisions
- `.planning/ROADMAP.md` — Phase-by-phase delivery plan
- `.planning/STATE.md` — Current position, decisions, blockers
- `.planning/phases/[N]-[slug]/` — Per-phase artifacts (CONTEXT, RESEARCH, PLANs, SUMMARYs, UAT, VERIFICATION)

Always read STATE.md and ROADMAP.md before any planning or execution operation to understand current project position.

## Agent Personas

Reference these files when adopting a specific role:

- `@./agents/planner.md` — Creating PLAN.md files
- `@./agents/researcher.md` — Researching domain or phase
- `@./agents/executor.md` — Implementing plans (atomic commits, no scope creep)
- `@./agents/verifier.md` — Verifying plans or phase goal achievement
- `@./agents/debugger.md` — Diagnosing root causes (read-only, never fix)

## Learning Mode

Read `learning_mode` from `.planning/config.json` (default: "auto"):

- **`auto`** — Proactively offer learning actions at natural workflow checkpoints (after planning, execution, verification)
- **`manual`** — Only activate `@agentic-learning` when the user explicitly asks

Learning checkpoints:
- After requirements approved → `@agentic-learning brainstorm`
- After discuss-phase → `@agentic-learning either-or`
- After plan-phase → `@agentic-learning cognitive-load`
- After execute-phase → `@agentic-learning reflect`
- After verify-work passes → `@agentic-learning space`
- During complex quick tasks → `@agentic-learning struggle`

## Design Skill

The `impeccable` skill suite is always available for any UI work. Use its steering commands (`/audit`, `/critique`, `/polish`, `/colorize`, `/animate`, `/bolder`, `/quieter`, `/distill`, `/clarify`, `/optimize`, `/harden`, `/delight`, `/extract`, `/adapt`, `/onboard`, `/normalize`, `/teach-impeccable`) when reviewing or building user-facing interfaces.

## Key Behaviors

- **Context efficiency**: Reference file paths rather than inlining file contents. Load context fresh when needed rather than carrying it forward.
- **Atomic commits**: Every task gets its own commit. Never batch unrelated changes.
- **No scope creep**: Execute exactly what plans say. Document deviations in SUMMARY.md.
- **Goal-backward verification**: Check that `must_haves` are met in the codebase, not just that tasks ran.
- **Deferred ideas**: When users suggest things outside the current phase scope, note them for the roadmap backlog — don't act on them immediately.

## Reference Files

- `@./references/questioning.md` — Questioning techniques for new-project and discuss-phase
- `@./references/verification-patterns.md` — How to verify implementation quality
- `@./references/git-integration.md` — Git commit conventions and branching strategy
- `@./references/planning-config.md` — Config.json schema and options
