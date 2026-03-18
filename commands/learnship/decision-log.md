---
name: learnship:decision-log
description: Capture an architectural or scope decision with its context, alternatives, and rationale into DECISIONS.md
argument-hint: "[description]"
allowed-tools:
  - Read
  - Write
  - AskUserQuestion
---

<execution_context>
@~/.claude/workflows/decision-log.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship decision-log workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
