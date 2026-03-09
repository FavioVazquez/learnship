---
name: learnship:execute-plan
description: Run a single PLAN.md file in isolation — useful for re-running a failed plan
argument-hint: "<phase-number> <plan-id>"
allowed-tools:
  - Read
  - Bash
  - Write
  - Edit
  - Glob
  - Grep
  - Task
---

<execution_context>
@~/.claude/learnship/workflows/execute-plan.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship execute-plan workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
