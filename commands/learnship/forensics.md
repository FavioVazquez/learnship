---
name: learnship:forensics
description: Post-mortem investigation for failed or stuck workflows — read-only diagnostic report
argument-hint: "[problem description]"
allowed-tools:
  - Read
  - Bash
---

<execution_context>
@~/.claude/workflows/forensics.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship forensics workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
