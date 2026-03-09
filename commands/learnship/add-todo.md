---
name: learnship:add-todo
description: Capture a todo/idea mid-session without interrupting flow
argument-hint: "[description]"
allowed-tools:
  - Read
  - Write
---

<execution_context>
@~/.claude/learnship/workflows/add-todo.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship add-todo workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
