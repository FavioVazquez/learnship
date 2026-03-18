---
name: learnship:debug
description: Systematic debugging with persistent state — triage, diagnose root cause, plan fix, execute
argument-hint: "[description]"
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
@~/.claude/workflows/debug.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship debug workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
