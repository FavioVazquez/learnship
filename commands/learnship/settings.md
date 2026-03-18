---
name: learnship:settings
description: Interactive settings editor for .planning/config.json
allowed-tools:
  - Read
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/settings.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship settings workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
