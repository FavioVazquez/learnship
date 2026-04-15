---
name: learnship:ideate
description: Codebase-grounded divergent thinking — discover what is worth working on
argument-hint: "[focus] | --explore [topic]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/ideate.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship ideate workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
