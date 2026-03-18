---
name: learnship:reapply-patches
description: Restore local workflow customizations after updating the platform
allowed-tools:
  - Read
  - Bash
  - Write
---

<execution_context>
@~/.claude/workflows/reapply-patches.md
</execution_context>

<context>
Arguments: $ARGUMENTS
</context>

<process>
Execute the learnship reapply-patches workflow end-to-end.
Preserve all workflow gates, validations, checkpoints, and routing.
</process>
