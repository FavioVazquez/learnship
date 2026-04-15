---
name: learnship:note
description: Zero-friction idea capture — one write, one confirmation line, no questions
argument-hint: "[text] | list | promote N"
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/note.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship note workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
