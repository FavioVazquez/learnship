---
name: learnship:verify-work
description: Manual user acceptance testing — walk through what was built, log issues, create fix plans
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/verify-work.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship verify-work workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
