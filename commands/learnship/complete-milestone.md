---
name: learnship:complete-milestone
description: Archive a completed milestone, tag the release, and prepare for the next version
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/learnship/workflows/complete-milestone.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship complete-milestone workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
