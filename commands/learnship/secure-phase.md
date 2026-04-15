---
name: learnship:secure-phase
description: Per-phase security verification — STRIDE threat register, mitigation check, SECURITY.md generation
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/secure-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship secure-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
