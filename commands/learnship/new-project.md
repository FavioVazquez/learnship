---
name: learnship:new-project
description: Initialize a new project — questioning → research → requirements → roadmap
argument-hint: "[--auto]"
allowed-tools:
  - Read
  - Bash
  - Write
  - Task
  - AskUserQuestion
---

<execution_context>
@~/.claude/learnship/workflows/new-project.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship new-project workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
