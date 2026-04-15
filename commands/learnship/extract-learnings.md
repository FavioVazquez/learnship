---
name: learnship:extract-learnings
description: Extract structured learnings from completed phase artifacts — decisions, lessons, patterns, surprises
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/extract-learnings.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship extract-learnings workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
