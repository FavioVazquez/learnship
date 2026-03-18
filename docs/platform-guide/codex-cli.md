---
title: Codex CLI
description: "learnship on Codex CLI: dollar-sign prefix commands, skills as context, and parallel subagents."
---

# Codex CLI

Codex CLI gets full learnship capabilities including real parallel subagents and the complete workflow suite.

## Install

```bash
npx learnship --codex --global
```

Installs to `~/.codex/learnship/`.

## Invoke commands

Codex CLI uses a `$learnship-` prefix (dollar sign + hyphen):

```
$learnship-ls
$learnship-new-project
$learnship-discuss-phase 1
$learnship-plan-phase 1
$learnship-execute-phase 1
$learnship-verify-work 1
$learnship-quick "fix the login bug"
$learnship-help
```

## Skills

Skills are installed as context files:

```
~/.codex/learnship/skills/
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

## Parallel subagents

Codex CLI supports real parallel subagents. Enable:

```json title=".planning/config.json"
{ "parallelization": true }
```

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ `$learnship-*` prefix |
| `@agentic-learning` skill | ✅ Context file |
| `impeccable` skill suite | ✅ Context file |
| Parallel subagents | ✅ opt-in |
| Wave execution | ✅ opt-in |
| Specialist agent pool | ✅ |

!!! tip
    Codex CLI uses `$learnship-` (dollar sign prefix) rather than `/learnship:` or `/learnship-`. This matches Codex CLI's native skill invocation convention.

!!! tip
    **`AGENTS.md` is not auto-loaded on Codex CLI** the way it is on Windsurf or Claude Code. Run `/new-project` once per project — it generates an `AGENTS.md` at your project root. Codex CLI reads `AGENTS.md` when commands explicitly reference it, but for fully automatic context loading, keep `AGENTS.md` in the project root and your agent will encounter it via the workflows.
