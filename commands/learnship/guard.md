---
name: learnship:guard
description: Safety mode — warn on destructive commands, lock file scope
argument-hint: "[scope|off]"
allowed-tools:
  - Read
  - Write
---

<execution_context>
@~/.claude/workflows/guard.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship guard workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
