---
name: learnship:cleanup
description: Archive completed milestone phase directories to keep .planning/phases/ clean
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/cleanup.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship cleanup workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
