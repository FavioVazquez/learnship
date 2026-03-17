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
```

## Skills

Skills are installed as context files: Claude reads them automatically:

```
~/.claude/learnship/skills/
├── agentic-learning/
│   ├── SKILL.md           ← loaded as context
│   └── references/
└── impeccable/
    ├── SKILL.md
    └── [17 sub-skills]/
```

Reference skills explicitly when you want to invoke them:

```
Use the agentic-learning skill: learn React hooks
Use the agentic-learning skill: quiz: authentication patterns
Run the impeccable /audit skill on this component
```

Or just work normally: skills activate at workflow checkpoints when `learning_mode: "auto"`.

## Parallel subagents

Claude Code supports real parallel subagents. Enable in your project:

```json title=".planning/config.json"
{ "parallelization": true }
```

When enabled:
- `plan-phase` spawns three dedicated subagents (researcher, planner, plan-checker) each with a fresh 200k context budget
- `execute-phase` dispatches each independent plan to its own executor agent: plans in the same wave run in parallel
- `debug` spawns a dedicated debugger subagent for deep root-cause investigation

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ `/learnship:*` prefix |
| `@agentic-learning` skill | ✅ Context file |
| `impeccable` skill suite | ✅ Context file |
| Parallel subagents | ✅ opt-in |
| Wave execution | ✅ opt-in |
| Specialist agent pool | ✅ |

## Tips

- **`AGENTS.md` is auto-loaded** by Claude Code as a project rule if placed at the project root.
- **Slash command prefix** is `/learnship:`: not `/learnship-` (that's OpenCode).
- **Subagents are opt-in.** Default is sequential which is always safe. Enable parallelization only after your first project works end-to-end.
