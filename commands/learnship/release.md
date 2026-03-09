---
name: learnship:release
description: Cut a new learnship release — bump version, update changelog, push to public-main, tag, create GitHub release
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/learnship/workflows/release.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship release workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
