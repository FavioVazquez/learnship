---
title: Codex CLI
description: learnship on Codex CLI — dollar-sign prefix commands, skills as context, and parallel subagents.
---

# Codex CLI

Codex CLI gets full learnship capabilities including real parallel subagents and the complete workflow suite.

## Install

```bash
npx github:FavioVazquez/learnship --codex --global
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
    └── [17 sub-skills]/
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
