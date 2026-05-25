---
title: Claude Code
description: "learnship on Claude Code: slash command prefixes, skills as context, and parallel subagents."
---

# Claude Code

Claude Code gets full learnship capabilities including real parallel subagents, specialist agent dispatch, and the complete workflow suite.

## Install

```bash
npx learnship --claude --global
```

Installs to `~/.claude/learnship/`.

Alternatively, install via the community marketplace (no terminal required):

```
/plugin marketplace add FavioVazquez/learnship-marketplace
/plugin install learnship@learnship-marketplace
```

## Invoke commands

All learnship workflows use the `/learnship:` prefix:

```
/learnship:ls
/learnship:new-project
/learnship:discuss-phase 1
/learnship:plan-phase 1
/learnship:execute-phase 1
/learnship:verify-work 1
/learnship:quick "fix the login bug"
/learnship:help
/learnship:review              # two-pass review: spec compliance + quality (v2.4.0)
/learnship:ship                # v2.0: test → commit → push → PR
/learnship:compound            # v2.0: capture solved problem as knowledge
/learnship:challenge           # v2.0: stress-test scope
/learnship:ideate              # v2.0: codebase-grounded idea generation
```

## Skills

Skills are installed as **native Claude Code skills** — they appear as first-class slash commands immediately after install:

```
~/.claude/skills/
├── agentic-learning/
│   ├── SKILL.md           ← native skill, all actions inline
│   └── references/        ← supplementary detail files
└── impeccable/
    └── SKILL.md           ← all 21 sub-skill bodies inlined
```

Invoke with slash commands:

```
/agentic-learning learn React hooks
/agentic-learning quiz
/agentic-learning either-or
/agentic-learning brainstorm my auth design
/impeccable audit
/impeccable polish
/impeccable critique
```

Or just work normally: skills activate at workflow checkpoints when `learning_mode: "auto"`.

## Parallel subagents

Claude Code runs parallel subagents by default. Every new project created with `/new-project` (Quick or Customize mode) starts with `parallelization.enabled: true`.

To disable and run sequentially:

```json title=".planning/config.json"
{ "parallelization": { "enabled": false } }
```

When parallelization is on:
- `new-project` spawns a project-researcher for domain research, then a roadmapper for phase planning
- `plan-phase` spawns three dedicated subagents (phase-researcher, planner, plan-checker) each with a fresh 200k context budget
- `execute-phase` dispatches each independent plan to its own executor agent: plans in the same wave run in parallel
- `debug` spawns a dedicated debugger subagent for deep root-cause investigation
- `review` spawns a code-reviewer subagent through 6 review lenses
- `challenge` spawns a challenger subagent for scope stress-testing
- `compound` spawns a solution-writer subagent to capture knowledge
- `ideate` spawns an ideation-agent for codebase-grounded idea generation
- `secure-phase` spawns a security-auditor for STRIDE verification
- `verify-work` spawns debugger, planner, and verifier subagents for UAT diagnosis
- `validate-phase` spawns a verifier subagent for retroactive test coverage
- `docs-update` spawns a doc-writer and doc-verifier for documentation generation

All 17 agent personas have inline `<persona_context>` blocks as sequential fallback when parallelization is disabled.

## Session hooks (v2.2)

Claude Code gets 4 session hooks installed automatically:

| Hook | What it does |
|------|--------------|
| **Statusline** | Shows model, task/phase, directory, and a context usage bar (green → yellow → orange → red) |
| **Context monitor** | Warns the AI at 35% remaining (WARNING) and 25% remaining (CRITICAL) context to prevent unfinished work |
| **Prompt guard** | Scans `.planning/` file writes for prompt injection patterns (advisory, does not block) |
| **Session state** | Injects STATE.md orientation at session start and triggers background update checks |

Hooks are installed to `~/.claude/settings.json` automatically. No configuration needed.

## Interactive questions (v2.2)

14 workflows now present user decisions via `AskUserQuestion` — Claude Code's native structured question tool. You'll see clickable option cards instead of plain text lists during `/new-project`, `/settings`, `/discuss-phase`, and other interactive workflows.

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ `/learnship:*` prefix |
| `/agentic-learning` skill | ✅ Native skill (`~/.claude/skills/`) |
| `/impeccable` skill suite | ✅ Native skill, all 21 actions inlined |
| Parallel subagents | ✅ on by default |
| Wave execution | ✅ on by default |
| Agent personas (17) | ✅ `Task()` subagents + inline `<persona_context>` |
| Session hooks | ✅ 4 hooks |
| Interactive questions | ✅ `AskUserQuestion` |
| Playwright MCP smoke tests | ✅ Via @playwright/mcp MCP server |

## Playwright MCP smoke tests

Live UI smoke tests via Playwright MCP are supported when `@playwright/mcp` is configured. The `/verify-work` and `/ship` workflows will use it automatically for UI verification when available.

## Tips

- **`AGENTS.md` is auto-loaded** by Claude Code as a project rule if placed at the project root.
- **Slash command prefix** is `/learnship:`: not `/learnship-` (that's OpenCode).
- **Subagents are on by default.** To run sequentially, set `"parallelization": { "enabled": false }` in `.planning/config.json`. Sequential mode is always safe if you prefer one plan at a time.
