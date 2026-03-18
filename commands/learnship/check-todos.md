---
name: learnship:check-todos
description: Review and act on all pending todos captured with add-todo
allowed-tools:
  - Read
  - Write
  - Bash
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/check-todos.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship check-todos workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
