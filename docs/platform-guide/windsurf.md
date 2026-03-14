---
title: Windsurf
description: learnship on Windsurf — native skills, slash commands, and Cascade-specific tips.
---

# Windsurf

Windsurf is learnship's **native platform** — it gets the richest experience including real `@skill-name` invocation and the full impeccable suite as native slash commands.

## Install

```bash
npx github:FavioVazquez/learnship --windsurf --global
```

Installs to `~/.windsurf/workflows/` and `~/.windsurf/skills/`.

## Invoke commands

All learnship workflows are available as slash commands directly:

```
/ls
/new-project
/discuss-phase 1
/plan-phase 1
/execute-phase 1
/verify-work 1
/quick "fix the search bug"
/help
```

## Native skills

On Windsurf, skills are first-class — Cascade dispatches to them directly:

```
@agentic-learning learn React hooks
@agentic-learning quiz authentication patterns
@agentic-learning reflect
```

```
/audit
/critique
/polish
/colorize
```

No prefix needed, no "use the skill" phrasing required. Just invoke.

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ Native |
| `@agentic-learning` skill | ✅ Native `@invoke` |
| `impeccable` skill suite | ✅ Native `/commands` |
| Parallel subagents | ❌ Not supported |
| Wave execution | Sequential only |
| Specialist agent pool | ❌ Not supported |

!!! note "Parallelization"
    Windsurf doesn't support real parallel subagents — `execute-phase` always runs plans sequentially. All context engineering, planning, verification, and learning features are fully available.

## Tips for Cascade

- **Fresh context windows matter.** learnship is designed around fresh context. Start each major workflow (plan-phase, execute-phase) in a new Cascade conversation for best results.
- **`AGENTS.md` is auto-loaded.** Cascade reads `AGENTS.md` from your project root as a rule — you never need to paste context manually.
- **Skills activate at checkpoints.** When `learning_mode: "auto"`, Cascade will offer `@agentic-learning` actions at the end of each workflow step.
- **Use `/ls` to orient.** If Cascade seems unsure what to do, run `/ls` — it reads all state files and gives a clear next step.
