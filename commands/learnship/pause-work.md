---
name: learnship:pause-work
description: Save a handoff file when stopping mid-phase so you can resume seamlessly later
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/pause-work.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship pause-work workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
