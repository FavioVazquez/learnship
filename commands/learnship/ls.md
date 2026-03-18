---
name: learnship:ls
description: Show project status, next step, and offer to run it — start every session here
allowed-tools:
  - Read
  - Bash
---

<execution_context>
@~/.claude/workflows/ls.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship ls workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
