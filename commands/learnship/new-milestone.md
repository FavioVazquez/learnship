---
name: learnship:new-milestone
description: Start a new milestone cycle on an existing project after a prior milestone is complete
argument-hint: "[name]"
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/learnship/workflows/new-milestone.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship new-milestone workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
