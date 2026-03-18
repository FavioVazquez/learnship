---
name: learnship:discuss-phase
description: Capture implementation decisions for a phase before planning starts
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/discuss-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship discuss-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
