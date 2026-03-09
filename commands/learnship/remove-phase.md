---
name: learnship:remove-phase
description: Remove a planned (not yet executed) phase and renumber subsequent phases
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/learnship/workflows/remove-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship remove-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
