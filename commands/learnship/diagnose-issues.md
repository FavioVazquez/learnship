---
name: learnship:diagnose-issues
description: Batch-diagnose multiple UAT issues after verify-work — groups by root cause, proposes fix plan
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
---

<execution_context>
@~/.claude/workflows/diagnose-issues.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship diagnose-issues workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
