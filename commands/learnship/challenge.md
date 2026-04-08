---
name: learnship:challenge
description: Product + engineering challenge gate — is this worth building?
argument-hint: "[description]"
allowed-tools:
  - Read
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/challenge.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship challenge workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
