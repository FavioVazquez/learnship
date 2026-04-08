---
name: learnship:ship
description: Ship pipeline — test, lint, commit, push, PR
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/ship.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship ship workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
