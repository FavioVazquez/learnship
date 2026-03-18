---
name: learnship:health
description: Project health check — stale files, uncommitted changes, missing artifacts, config drift
allowed-tools:
  - Read
  - Bash
---

<execution_context>
@~/.claude/workflows/health.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship health workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
