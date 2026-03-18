---
name: learnship:plan-phase
description: Research + create + verify plans for a phase — spawns specialist subagents where supported
argument-hint: "[N]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/plan-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship plan-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
