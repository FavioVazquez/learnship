---
name: learnship:docs-update
description: Generate, update, and verify project documentation — detects project type, builds doc queue, verifies against live codebase
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
---

<execution_context>
@~/.claude/workflows/docs-update.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship docs-update workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
