---
name: learnship:next
description: Auto-pilot — reads project state and runs the correct next workflow automatically
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/next.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship next workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
