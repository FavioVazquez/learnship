---
description: Capture a todo/idea mid-session without interrupting flow
---

# Add Todo

Capture an idea, task, or issue that surfaces during a session. Fast "thought → capture → continue" — saves context without losing momentum.

**Usage:** `add-todo [description]` or just `add-todo` to capture from recent conversation.

## Step 1: Ensure Directories Exist

```bash
mkdir -p .planning/todos/pending .planning/todos/done
```

## Step 2: Extract Content

**With description argument:** Use it as the title/focus.

**Without argument:** Read recent conversation context to extract:
- The specific problem, idea, or task being discussed
- Relevant file paths mentioned
- Technical details (error messages, constraints, line numbers)

Formulate:
- `title` — 3-10 word descriptive title (action verb preferred, e.g., "Add auth token refresh")
- `problem` — what's wrong or why this is needed (enough context for future Cascade sessions)
- `solution` — approach hints, or "TBD" if just an idea
- `files` — relevant file paths with line numbers from context

## Step 3: Infer Area

Determine area from file paths mentioned:

| Path pattern | Area |
|--------------|------|
| `src/api/`, `api/` | `api` |
| `src/components/`, `src/ui/` | `ui` |
| `src/auth/`, `auth/` | `auth` |
| `src/db/`, `database/` | `database` |
| `tests/`, `__tests__/`, `*.test.*` | `testing` |
| `docs/` | `docs` |
| `.planning/` | `planning` |
| `scripts/`, `bin/` | `tooling` |
| Unclear or none | `general` |

## Step 4: Check for Duplicates

```bash
ls .planning/todos/pending/ 2>/dev/null
grep -rl "[key words from title]" .planning/todos/pending/ 2>/dev/null
```

If a similar todo exists, show it and ask: "A similar todo already exists: [title]. Create anyway, or update the existing one?"

## Step 5: Write Todo File

Generate a date-based slug: `YYYY-MM-DD-[slug].md`

Write to `.planning/todos/pending/[filename]`:

```markdown
---
created: [ISO datetime]
title: [title]
area: [area]
files:
  - [file:line if applicable]
---

## Problem

[problem description — enough context for future Cascade to understand weeks later, without re-reading the full conversation]

## Solution

[approach hints or "TBD — need to investigate"]
```

## Step 6: Update STATE.md

If `.planning/STATE.md` exists, update the Pending Todos count under Accumulated Context:

```bash
grep -c "^" .planning/todos/pending/*.md 2>/dev/null
```

Update the `### Pending Todos` section with the new count and latest title.

## Step 7: Commit

```bash
git add ".planning/todos/pending/[filename]" .planning/STATE.md
git commit -m "docs: capture todo — [title]"
```

## Step 8: Confirm

```
Todo saved: .planning/todos/pending/[filename]

  [title]
  Area: [area]
  Files: [count] referenced

Continue with current work, or check all todos with check-todos.
```
