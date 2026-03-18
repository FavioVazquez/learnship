---
name: learnship:insert-phase
description: Insert a new phase between existing phases for urgent work discovered mid-milestone
argument-hint: "[N] [description]"
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/insert-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship insert-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
