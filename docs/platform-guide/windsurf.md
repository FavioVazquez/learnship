---
title: Windsurf
description: "learnship on Windsurf: native skills, slash commands, and Cascade-specific tips."
---

# Windsurf

Windsurf is learnship's **native platform.** It gets the richest experience including real `@skill-name` invocation and the full impeccable suite as native slash commands.

## Install

```bash
npx learnship --windsurf --global
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
/review              # v2.0: multi-persona code review
/ship                # v2.0: test → commit → push → PR
/compound            # v2.0: capture solved problem as knowledge
/challenge           # v2.0: stress-test scope
/ideate              # v2.0: codebase-grounded idea generation
```

## Native skills

On Windsurf, skills are first-class: Cascade dispatches to them directly:

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
| Parallel subagents | ❌ Not supported (no `Task()`) |
| Wave execution | Sequential only |
| Agent personas | ✅ 17 `model_decision` rules |
| Interactive questions | ✅ `ask_user_question` |

## Agent personas via `model_decision` rules

Windsurf doesn't support `Task()` subagent spawning, but it has its own native mechanism for persona adoption: **`model_decision` rules**.

When learnship installs on Windsurf, `install.js` generates 17 rule files in `.windsurf/rules/`:

```
.windsurf/rules/
├── learnship-researcher.md
├── learnship-project-researcher.md
├── learnship-planner.md
├── learnship-executor.md
├── learnship-verifier.md
├── learnship-debugger.md
├── learnship-roadmapper.md
└── ... (17 total)
```

Each rule has `trigger: model_decision` frontmatter:

```yaml
---
trigger: model_decision
description: "Adopt this rule when acting as the learnship researcher persona — when investigating a domain..."
---
```

**How it works:** Cascade always sees the rule descriptions in its system prompt. When a workflow says "You are now the **learnship researcher**", Cascade recognizes the match and reads the full rule automatically — adopting the persona's philosophy, tool strategy, confidence levels, and output format.

This is reinforced by inline `<persona_context>` blocks in every workflow that uses a persona:

```markdown
<persona_context>
You are now the **learnship researcher**. Your training data is stale — verify before asserting.
Use search_web for ecosystem discovery, read_url_content for official docs.
Tag confidence: HIGH/MEDIUM/LOW.
</persona_context>
```

The combination of `model_decision` rules + inline persona instructions gives Windsurf the same persona adoption quality as Claude Code's `Task()` subagents — just through a different mechanism.

!!! note "Sequential execution"
    Windsurf always runs plans sequentially (no parallel waves). All context engineering, planning, verification, and learning features are fully available. The agent personas ensure the same quality of work whether running in parallel on Claude Code or sequentially on Windsurf.

## Tips for Cascade

- **Fresh context windows matter.** learnship is designed around fresh context. Start each major workflow (plan-phase, execute-phase) in a new Cascade conversation for best results.
- **`AGENTS.md` is auto-loaded.** Cascade reads `AGENTS.md` from your project root as a rule: you never need to paste context manually.
- **Agent personas activate automatically.** When a workflow references a persona, Cascade reads the matching `model_decision` rule from `.windsurf/rules/` — no manual invocation needed.
- **Skills activate at checkpoints.** When `learning_mode: "auto"`, Cascade will offer `@agentic-learning` actions at the end of each workflow step.
- **Use `/ls` to orient.** If Cascade seems unsure what to do, run `/ls`: it reads all state files and gives a clear next step.
