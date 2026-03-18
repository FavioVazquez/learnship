---
name: learnship:add-tests
description: Generate and add test coverage for a specific plan or phase post-execution
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - Task
---

<execution_context>
@~/.claude/workflows/add-tests.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship add-tests workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
