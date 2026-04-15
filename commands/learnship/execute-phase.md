---
name: learnship:execute-phase
description: Execute all plans in a phase using wave-based ordered execution — spawns subagents per plan where the platform supports it
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
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
