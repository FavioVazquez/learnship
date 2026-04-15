# Solution Schema Reference

Canonical contract for `.planning/solutions/` frontmatter written by the `/compound` workflow.

Use this file as the quick reference for:
- Required fields
- Enum values
- Validation expectations
- Category mapping
- Track classification (bug vs knowledge)

## Tracks

The `problem_type` determines which **track** applies. Each track has different required and optional fields.

| Track | problem_types | Description |
|-------|--------------|-------------|
| **Bug** | `build_error`, `test_failure`, `runtime_error`, `performance_issue`, `database_issue`, `security_issue`, `ui_bug`, `integration_issue`, `logic_error` | Defects and failures that were diagnosed and fixed |
| **Knowledge** | `best_practice`, `documentation_gap`, `workflow_issue`, `developer_experience` | Practices, patterns, workflow improvements, and documentation |

## Required Fields (both tracks)

- **title**: Clear problem/learning title
- **date**: ISO date in `YYYY-MM-DD`
- **category**: Category directory from mapping below
- **module**: Module or area affected
- **problem_type**: One of the values listed in the Tracks table above
- **severity**: One of `critical`, `high`, `medium`, `low`

## Optional Fields (both tracks)

- **tags**: Search keywords, lowercase and hyphen-separated
- **last_updated**: ISO date `YYYY-MM-DD` — added when updating an existing doc

## Bug Track Additional Fields

Optional but recommended:
- **symptoms**: YAML array with 1-5 observable symptoms (errors, broken behavior)
- **root_cause**: Brief description of the underlying cause
- **resolution_type**: One of `code_fix`, `migration`, `config_change`, `test_fix`, `dependency_update`, `environment_setup`, `workflow_improvement`, `documentation_update`, `tooling_addition`

## Knowledge Track Additional Fields

Optional:
- **applies_when**: Conditions or situations where this guidance applies

## Category Mapping

Map from `problem_type` to `.planning/solutions/` subdirectory:

- `build_error` → `.planning/solutions/build-errors/`
- `test_failure` → `.planning/solutions/test-failures/`
- `runtime_error` → `.planning/solutions/runtime-errors/`
- `performance_issue` → `.planning/solutions/performance-issues/`
- `database_issue` → `.planning/solutions/database-issues/`
- `security_issue` → `.planning/solutions/security-issues/`
- `ui_bug` → `.planning/solutions/ui-bugs/`
- `integration_issue` → `.planning/solutions/integration-issues/`
- `logic_error` → `.planning/solutions/logic-errors/`
- `best_practice` → `.planning/solutions/best-practices/`
- `workflow_issue` → `.planning/solutions/workflow-issues/`
- `developer_experience` → `.planning/solutions/developer-experience/`
- `documentation_gap` → `.planning/solutions/documentation-gaps/`

## Bug Track Template

```markdown
---
title: [Clear problem title]
date: [YYYY-MM-DD]
category: [category directory]
module: [module or area]
problem_type: [enum value]
severity: [critical|high|medium|low]
tags: [keyword-one, keyword-two]
---

# [Clear problem title]

## Problem
[1-2 sentence description of the issue and impact]

## Symptoms
- [Observable symptom or error]

## What Didn't Work
- [Attempted fix and why it failed]

## Solution
[The fix that worked, including code snippets]

## Why This Works
[Root cause explanation and why the fix addresses it]

## Prevention
- [Concrete practice, test, or guardrail]

## Related
- [Related docs or issues, if any]
```

## Knowledge Track Template

```markdown
---
title: [Clear, descriptive title]
date: [YYYY-MM-DD]
category: [category directory]
module: [module or area]
problem_type: [enum value]
severity: [critical|high|medium|low]
tags: [keyword-one, keyword-two]
---

# [Clear, descriptive title]

## Context
[What situation, gap, or friction prompted this guidance]

## Guidance
[The practice, pattern, or recommendation with code examples]

## Why This Matters
[Rationale and impact of following or not following this guidance]

## When to Apply
- [Conditions or situations where this applies]

## Examples
[Concrete before/after or usage examples]

## Related
- [Related docs or issues, if any]
```

## Validation Rules

1. Determine the track from `problem_type` using the Tracks table
2. All required fields must be present
3. Enum fields must match allowed values exactly
4. `date` must match `YYYY-MM-DD`
5. `tags` should be lowercase and hyphen-separated
6. Filename pattern: `[sanitized-problem-slug]-[YYYY-MM-DD].md`

## Overlap Assessment

When existing solutions exist, assess overlap across five dimensions:

1. Problem statement
2. Root cause
3. Solution approach
4. Referenced files
5. Prevention rules

| Score | Dimensions | Action |
|-------|-----------|--------|
| **High** | 4-5 match | Update existing doc, add `last_updated` |
| **Moderate** | 2-3 match | Create new doc, note overlap |
| **Low** | 0-1 match | Create new doc normally |
