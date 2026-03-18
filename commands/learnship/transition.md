---
name: learnship:transition
description: Hand off a project context to a new session or collaborator — writes a HANDOFF.md with full state snapshot
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/transition.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship transition workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
