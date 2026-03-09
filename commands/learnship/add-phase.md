---
name: learnship:add-phase
description: Append a new phase to the current milestone roadmap when scope grows after initial planning
argument-hint: "[description]"
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/learnship/workflows/add-phase.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship add-phase workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
