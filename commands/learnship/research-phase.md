---
name: learnship:research-phase
description: Deep-dive domain research for a phase without immediately creating plans
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
---

<execution_context>
@~/.claude/workflows/research-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship research-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
