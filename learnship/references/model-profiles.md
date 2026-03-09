# Model Profiles

Model profiles control which AI model each learnship agent uses. This allows balancing quality vs token spend.

## Profile Definitions

| Agent | `quality` | `balanced` | `budget` |
|-------|-----------|------------|----------|
| planner | opus | opus | sonnet |
| roadmapper | opus | sonnet | sonnet |
| executor | opus | sonnet | sonnet |
| phase-researcher | opus | sonnet | haiku |
| project-researcher | opus | sonnet | haiku |
| research-synthesizer | sonnet | sonnet | haiku |
| debugger | opus | sonnet | sonnet |
| codebase-mapper | sonnet | haiku | haiku |
| verifier | sonnet | sonnet | haiku |
| plan-checker | sonnet | sonnet | haiku |
| integration-checker | sonnet | sonnet | haiku |
| nyquist-auditor | sonnet | sonnet | haiku |

## Profile Philosophy

**quality** - Maximum reasoning power
- Opus for all decision-making agents
- Sonnet for read-only verification
- Use when: quota available, critical architecture work

**balanced** (default) - Smart allocation
- Opus only for planning (where architecture decisions happen)
- Sonnet for execution and research (follows explicit instructions)
- Sonnet for verification (needs reasoning, not just pattern matching)
- Use when: normal development, good balance of quality and cost

**budget** - Minimal Opus usage
- Sonnet for anything that writes code
- Haiku for research and verification
- Use when: conserving quota, high-volume work, less critical phases

## Resolution Logic

Resolution order:

```
1. Read .planning/config.json
2. Check model_overrides for agent-specific override
3. If no override, look up agent in profile table
4. Apply the resolved profile when adopting the agent persona
```

## Per-Agent Overrides

Override specific agents without changing the entire profile:

```json
{
  "model_profile": "balanced",
  "model_overrides": {
    "executor": "opus",
    "planner": "haiku"
  }
}
```

Overrides take precedence over the profile. Valid values: `opus`, `sonnet`, `haiku`.

## Switching Profiles

Runtime: `/set-profile <profile>`

Per-project default: Set in `.planning/config.json`:
```json
{
  "model_profile": "balanced"
}
```

## Design Rationale

**Why Opus for the planner?**
Planning involves architecture decisions, goal decomposition, and task design. This is where model quality has the highest impact.

**Why Sonnet for the executor?**
Executors follow explicit PLAN.md instructions. The plan already contains the reasoning; execution is implementation.

**Why Sonnet (not Haiku) for verifiers in balanced?**
Verification requires goal-backward reasoning — checking if code *delivers* what the phase promised, not just pattern matching. Sonnet handles this well; Haiku may miss subtle gaps.

**Why Haiku for the codebase-mapper?**
Read-only exploration and pattern extraction. No reasoning required, just structured output from file contents.
