---
name: learnship:discuss-milestone
description: Capture milestone-level goals, constraints, and anti-goals before new-milestone starts
argument-hint: "[version]"
allowed-tools:
  - Read
  - Bash
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/discuss-milestone.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship discuss-milestone workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
