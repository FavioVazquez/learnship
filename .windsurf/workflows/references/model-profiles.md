# Model Profiles

Model profiles control which AI model tier each learnship agent uses. Profiles are platform-agnostic — they use three tiers (`large`, `medium`, `small`) that map to specific models depending on your platform.

## Profile Definitions

| Agent | `quality` | `balanced` | `budget` | Notes |
|-------|-----------|------------|----------|-------|
| planner | large | large | medium | Always large — planning is where architecture decisions happen. |
| executor | large | medium | medium | Follows explicit PLAN.md; reasoning is in the plan, not the agent. |
| phase-researcher | large | medium | small | Codebase-only research; no web search needed. |
| project-researcher | large | medium | small | Greenfield research; uses web search to discover ecosystem. |
| research-synthesizer | medium | medium | small | Reads research files and produces SUMMARY.md. |
| researcher | large | medium | small | General-purpose research used across many workflows. |
| roadmapper | large | medium | small | Maps requirements to phases; needs strong scope reasoning. |
| debugger | large | medium | medium | Root-cause investigation needs broad reasoning. |
| verifier | medium | medium | small | Goal-backward checking, mostly structural. |
| plan-checker | medium | medium | small | Plan completeness checks (vertical-slice, wave correctness). |
| solution-writer | medium | medium | small | Captures solved problems while context is fresh. |
| code-reviewer | large | medium | medium | Multi-persona review; needs to reason about correctness + security + perf. |
| challenger | large | medium | medium | Stress-tests proposals; needs strong adversarial reasoning. |
| ideation-agent | large | medium | small | Generates ideas across creative frames. |
| security-auditor | large | medium | medium | STRIDE threat modeling; rigorous reasoning required. |
| doc-writer | medium | medium | small | Writes/updates docs from live code; structural task. |
| doc-verifier | medium | medium | small | Checks docs match code; pattern matching. |

## Platform Model Resolution

Each tier resolves to the best available model on your platform:

| Tier | Anthropic (Claude Code) | Google (Gemini CLI) | OpenAI (Codex CLI) | Windsurf / Cursor / OpenCode |
|------|------------------------|--------------------|--------------------|-----------------------------|
| `large` | Claude Opus 4.7 | Gemini 3.1 Pro | GPT-5.4 | Uses platform default (best available) |
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

