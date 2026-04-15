---
name: learnship:session-report
description: Generate a post-session summary with work performed, outcomes, and estimated resource usage
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/session-report.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship session-report workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
