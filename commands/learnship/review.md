---
name: learnship:review
description: Multi-persona code review — correctness, testing, security, performance, maintainability
argument-hint: "[mode]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
---

<execution_context>
@~/.claude/workflows/review.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship review workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
