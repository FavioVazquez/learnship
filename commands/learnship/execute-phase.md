---
name: learnship:execute-phase
description: Execute all plans in a phase with wave-based ordered execution, spawning subagents per plan where supported
argument-hint: "<phase-number>"
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
@~/.claude/workflows/execute-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship execute-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
