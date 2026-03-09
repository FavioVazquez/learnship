---
name: learnship:set-profile
description: Quick model profile switch without opening full settings
argument-hint: "[quality|balanced|budget]"
allowed-tools:
  - Read
  - Write
---

<execution_context>
@~/.claude/learnship/workflows/set-profile.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship set-profile workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
