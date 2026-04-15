---
name: learnship:milestone-summary
description: Generate a comprehensive milestone summary for team onboarding — a new contributor reads it and understands the project
argument-hint: "[version]"
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/milestone-summary.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship milestone-summary workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
