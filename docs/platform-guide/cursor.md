---
title: Cursor
description: "learnship on Cursor: marketplace plugin, agent rules, and workflow integration."
---

# Cursor

Cursor gets learnship via the plugin marketplace — no terminal required. The `cursor-rules/learnship.mdc` rule file activates learnship context automatically in every Cursor session.

## Install

**From the marketplace (recommended, after marketplace approval):**

```
/add-plugin learnship
```

**Or clone and install locally:**

```bash
npx learnship --cursor --global
```

!!! note "Marketplace status"
    learnship has been submitted to the Cursor marketplace. Until approved, use the direct npm install or copy `cursor-rules/learnship.mdc` into your project's `.cursor/rules/` directory.

## How it works on Cursor

Cursor uses `.mdc` rule files to inject persistent context into every agent session. The `learnship.mdc` rule:

- Loads all 42 workflow commands with when-to-use guidance
- Explains `.planning/` artifact structure so the agent always knows where state lives
- Activates learning mode and design system behaviors
- Defines key agent behaviors (atomic commits, no scope creep, goal-backward verification)

```
.cursor/rules/
└── learnship.mdc     ← loaded automatically every session
```

## Using workflows

All learnship workflows are available as natural language or slash commands. Cursor's agent understands them from the rule file context:

```
/ls
/new-project
/discuss-phase 1
/plan-phase 1
/execute-phase 1
/verify-work 1
/quick "fix the auth bug"
/help
```

## Skills

On Cursor, skills ship as context files inside the learnship plugin package under `skills/`:

```
learnship-plugin/
├── skills/
│   ├── agentic-learning/
│   │   ├── SKILL.md         ← loaded as AI context
│   │   └── references/
│   └── impeccable/
│       ├── SKILL.md
│       └── [18 sub-skills]/
├── cursor-rules/
│   └── learnship.mdc        ← loaded every session automatically
└── hooks/
    └── session-start        ← injects learnship context at session start
```

The `learnship.mdc` rule file describes both skills to Cursor's agent, and the `session-start` hook injects the full learnship context at every session — you don't need to reference anything manually. Just invoke the skills naturally:

```
Use the agentic-learning skill: quiz React hooks
Run the impeccable audit skill on this component
```

Or just work normally — the rule file activates skills at workflow checkpoints when `learning_mode: "auto"`.

## Capabilities

| Feature | Status |
|---------|--------|
| Slash commands | ✅ Via `.mdc` rule context |
| `@agentic-learning` skill | ✅ Context-file |
| `impeccable` skill suite | ✅ Context-file |
| Parallel subagents | ❌ Not supported |
| Wave execution | Sequential only |
| Marketplace install | ✅ `/add-plugin learnship` |

## Manual rule install (before marketplace approval)

Copy the rule file to your project:

```bash
mkdir -p .cursor/rules
cp node_modules/learnship/cursor-rules/learnship.mdc .cursor/rules/
```

Or if you have learnship installed globally:

```bash
mkdir -p .cursor/rules
cp ~/.local/share/learnship/cursor-rules/learnship.mdc .cursor/rules/
```

## Tips

- **Rule file is automatic.** Once `.cursor/rules/learnship.mdc` exists, Cursor loads it every session — no manual context pasting.
- **Start with `/ls`.** Even on Cursor, `/ls` is the right entry point — it reads your `.planning/` state and tells you exactly where you are and what to do next.
- **`AGENTS.md` still works.** Place an `AGENTS.md` at your project root; Cursor reads it as project context automatically.
