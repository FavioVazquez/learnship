---
name: learnship:undo
description: Safe git revert for phase or plan commits — preserves history, checks dependencies
argument-hint: "--last N | --phase NN | --plan NN-MM"
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/undo.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship undo workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
