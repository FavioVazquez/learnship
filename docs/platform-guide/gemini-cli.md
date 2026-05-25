---
title: Gemini CLI
description: "learnship on Gemini CLI: slash command prefixes, skills as context, and 17 specialist agent personas."
---

# Gemini CLI

Gemini CLI gets full learnship capabilities including slash commands, 17 specialist agent personas, session hooks, and the complete workflow suite.

## Install

```bash
npx learnship --gemini --global
```

Alternatively, install as a native Gemini CLI extension (no terminal needed after this):

```bash
gemini extensions install https://github.com/FavioVazquez/learnship
```

Installs to `~/.gemini/learnship/`.

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

Skills are installed as context files:

```
~/.gemini/learnship/skills/
├── agentic-learning/
│   ├── SKILL.md
│   └── references/
└── impeccable/
    ├── SKILL.md
    └── [21 sub-skills]/
```

Reference explicitly to invoke:

```
Use the agentic-learning skill: learn [topic]
Run the impeccable /audit skill on this component
```

## Parallel execution

Gemini CLI supports subagents — including parallel dispatch since April 2026 — but learnship installs Gemini with sequential execution by default for stability. Plans run one at a time within each wave.

To opt in to parallel subagent execution (experimental on Gemini), set:

```json title=".planning/config.json"
{ "parallelization": true }
```

When enabled, `execute-phase` will attempt to dispatch each plan in a wave to its own subagent. Note that Gemini's parallel subagent runtime is still maturing, so prefer sequential for production work.

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ `/learnship:*` prefix |
| `@agentic-learning` skill | ✅ Context file |
| `impeccable` skill suite | ✅ Context file |
| Parallel subagents | ⚠️ Opt-in (experimental on Gemini) |
| Wave execution | ✅ Sequential by default |
| Agent personas (17) | ✅ Native subagents + inline `<persona_context>` |
| Session hooks | ✅ 4 hooks |
| Interactive questions | ✅ `ask_user` |
| Playwright MCP smoke tests | ✅ Via @playwright/mcp MCP server |

## Playwright MCP smoke tests

Live UI smoke tests via Playwright MCP are supported when `@playwright/mcp` is configured. The `/verify-work` and `/ship` workflows will use it automatically for UI verification when available.

!!! tip
    **`AGENTS.md` is not auto-loaded on Gemini CLI** the way it is on Windsurf or Claude Code. Run `/new-project` once per project — it generates an `AGENTS.md` at your project root. For subsequent sessions, Gemini CLI reads `GEMINI.md` from the project root automatically, so you can also symlink or copy `AGENTS.md` → `GEMINI.md` for persistent project context.
