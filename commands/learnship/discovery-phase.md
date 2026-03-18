---
name: learnship:discovery-phase
description: Structured codebase discovery before working on an unfamiliar area — reads code, maps dependencies, surfaces risks
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Glob
  - Grep
---

<execution_context>
@~/.claude/workflows/discovery-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship discovery-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
