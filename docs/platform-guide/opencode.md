---
title: OpenCode
description: learnship on OpenCode — slash command prefixes, skills as context, and parallel subagents.
---

# OpenCode

OpenCode gets full learnship capabilities including real parallel subagents and the complete workflow suite.

## Install

```bash
npx github:FavioVazquez/learnship --opencode --global
```

Installs to `~/.config/opencode/learnship/`.

## Invoke commands

All learnship workflows use the `/learnship-` prefix (hyphen, not colon):

```
/learnship-ls
/learnship-new-project
/learnship-discuss-phase 1
/learnship-plan-phase 1
/learnship-execute-phase 1
/learnship-verify-work 1
/learnship-quick "fix the login bug"
/learnship-help
```

## Skills

Skills are installed as context files:

```
~/.config/opencode/learnship/skills/
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

OpenCode supports real parallel subagents. Enable:

```json title=".planning/config.json"
{ "parallelization": true }
```

When enabled, `execute-phase` dispatches each plan in a wave to its own dedicated agent with a fresh context budget.

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ `/learnship-*` prefix |
| `@agentic-learning` skill | ✅ Context file |
| `impeccable` skill suite | ✅ Context file |
| Parallel subagents | ✅ opt-in |
| Wave execution | ✅ opt-in |
| Specialist agent pool | ✅ |

!!! tip
    Note the **hyphen** separator in OpenCode commands (`/learnship-ls`) vs the **colon** in Claude Code and Gemini CLI (`/learnship:ls`).
