---
name: learnship:validate-phase
description: Retroactive test coverage audit for a completed phase — fill validation gaps without modifying implementation
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/learnship/workflows/validate-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship validate-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
