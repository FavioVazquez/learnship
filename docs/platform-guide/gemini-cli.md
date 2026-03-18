---
title: Gemini CLI
description: "learnship on Gemini CLI: slash command prefixes, skills as context, and native parallel execution."
---

# Gemini CLI

Gemini CLI gets full learnship capabilities. Unlike Claude Code and OpenCode, parallel execution is enabled by default (no opt-in needed).

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
    └── [18 sub-skills]/
```

Reference explicitly to invoke:

```
Use the agentic-learning skill: learn [topic]
Run the impeccable /audit skill on this component
```

## Parallel execution

Gemini CLI supports parallel execution natively: it's on by default without requiring `"parallelization": true`. Plans in the same wave run simultaneously with independent context budgets.

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ `/learnship:*` prefix |
| `@agentic-learning` skill | ✅ Context file |
| `impeccable` skill suite | ✅ Context file |
| Parallel subagents | ✅ Default |
| Wave execution | ✅ Default |
| Specialist agent pool | ✅ |

!!! tip
    Gemini CLI is the only platform where parallelization is on by default. If you want sequential execution for debugging, set `"parallelization": false` in `.planning/config.json`.

!!! tip
    **`AGENTS.md` is not auto-loaded on Gemini CLI** the way it is on Windsurf or Claude Code. Run `/new-project` once per project — it generates an `AGENTS.md` at your project root. For subsequent sessions, Gemini CLI reads `GEMINI.md` from the project root automatically, so you can also symlink or copy `AGENTS.md` → `GEMINI.md` for persistent project context.
