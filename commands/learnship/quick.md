---
name: learnship:quick
description: Execute an ad-hoc task with full agentic guarantees — atomic commits, state tracking, no full planning ceremony
argument-hint: ""<task description>""
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - Glob
  - Grep
  - Task
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/quick.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship quick workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
