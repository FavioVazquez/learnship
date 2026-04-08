---
name: learnship:sync-docs
description: Detect stale documentation after code changes
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/sync-docs.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship sync-docs workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
