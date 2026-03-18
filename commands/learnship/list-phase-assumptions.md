---
name: learnship:list-phase-assumptions
description: Surface the intended approach for a phase before planning starts — validate direction early
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
---

<execution_context>
@~/.claude/workflows/list-phase-assumptions.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship list-phase-assumptions workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
