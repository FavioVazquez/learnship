---
name: learnship:map-codebase
description: Analyze an existing codebase and produce structured reference docs before starting a new project on top of it
allowed-tools:
  - Read
  - Bash
  - Write
  - Glob
  - Grep
---

<execution_context>
@~/.claude/workflows/map-codebase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship map-codebase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
