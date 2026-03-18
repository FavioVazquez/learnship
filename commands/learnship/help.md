---
name: learnship:help
description: Show all available learnship workflows with descriptions and when to use them
allowed-tools:
  - Read
---

<execution_context>
@~/.claude/workflows/help.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship help workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
