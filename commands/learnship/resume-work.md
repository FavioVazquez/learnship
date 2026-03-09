---
name: learnship:resume-work
description: Restore full project context and continue from where you left off
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/learnship/workflows/resume-work.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship resume-work workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
