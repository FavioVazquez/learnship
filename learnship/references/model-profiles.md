# Model Profiles

Model profiles control which AI model tier each learnship agent uses. Profiles are platform-agnostic — they use three tiers (`large`, `medium`, `small`) that map to specific models depending on your platform.

## Profile Definitions

| Agent | `quality` | `balanced` | `budget` |
|-------|-----------|------------|----------|
| planner | large | large | medium |
| executor | large | medium | medium |
| phase-researcher | large | medium | small |
| debugger | large | medium | medium |
| verifier | medium | medium | small |
| plan-checker | medium | medium | small |
| solution-writer | medium | medium | small |
| code-reviewer | large | medium | medium |
| challenger | large | medium | medium |
| ideation-agent | large | medium | small |

## Platform Model Resolution

Each tier resolves to the best available model on your platform:

| Tier | Anthropic (Claude Code) | Google (Gemini CLI) | OpenAI (Codex CLI) | Windsurf / Cursor / OpenCode |
|------|------------------------|--------------------|--------------------|-----------------------------|
| `large` | Claude Opus 4.6 | Gemini 3.1 Pro | GPT-5.4 | Uses platform default (best available) |
| `medium` | Claude Sonnet 4.6 | Gemini 3.1 Flash | GPT-5.4-mini | Uses platform default |
| `small` | Claude Haiku 4.5 | Gemini 3.1 Flash-Lite | GPT-5.4-nano | Uses platform default |

> **Note:** Windsurf, Cursor, and OpenCode do not expose per-agent model selection. The profile tiers are still useful — they signal the *intended complexity* of each agent's task, and workflows will adapt their prompting strategy accordingly (e.g., more explicit instructions for `small`-tier agents).

## Profile Philosophy

**quality** — Maximum reasoning power
- `large` for all decision-making agents (planner, researcher, reviewer, challenger)
- `medium` for verification (needs reasoning, not just pattern matching)
- Use when: quota available, critical architecture work

**balanced** (default) — Smart allocation
- `large` only for planning (where architecture decisions happen)
- `medium` for execution, research, and verification
- Use when: normal development, good balance of quality and cost

**budget** — Minimal large-model usage
- `medium` for anything that writes code
- `small` for research and verification
- Use when: conserving quota, high-volume work, less critical phases

## Resolution Logic

Resolution order:

```
1. Read .planning/config.json
2. Check model_overrides for agent-specific override
3. If no override, look up agent in profile table
4. Map the tier (large/medium/small) to the platform's actual model
5. Apply the resolved model when adopting the agent persona
```

## Per-Agent Overrides

Override specific agents without changing the entire profile:

```json
{
  "model_profile": "balanced",
  "model_overrides": {
    "executor": "large",
    "planner": "small"
  }
}
```

Overrides take precedence over the profile. Valid values: `large`, `medium`, `small`.

## Switching Profiles

Runtime: `/set-profile <profile>`

Per-project default: Set in `.planning/config.json`:
```json
{
  "model_profile": "balanced"
}
```

## Design Rationale

**Why `large` for the planner?**
Planning involves architecture decisions, goal decomposition, and task design. This is where model quality has the highest impact.

**Why `medium` for the executor?**
Executors follow explicit PLAN.md instructions. The plan already contains the reasoning; execution is implementation.

**Why `medium` (not `small`) for verifiers in balanced?**
Verification requires goal-backward reasoning — checking if code *delivers* what the phase promised, not just pattern matching. Medium-tier models handle this well; small-tier models may miss subtle gaps.

