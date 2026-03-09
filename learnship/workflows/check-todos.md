---
description: Review and act on all pending todos captured with add-todo
---

# Check Todos

List all pending todos, select one to review, and route to the appropriate action.

**Usage:** `check-todos` or `check-todos [area]` to filter by area.

## Step 1: Load Todos

```bash
ls .planning/todos/pending/ 2>/dev/null | sort
```

If no pending todos:
```
No pending todos.

Todos are captured during work sessions with add-todo.
```
Stop.

## Step 2: Apply Area Filter (if specified)

If an area argument was provided (e.g., `check-todos api`), filter to only show todos matching that area:
```bash
grep -l "^area: api" .planning/todos/pending/*.md 2>/dev/null
```

Valid areas: `api`, `ui`, `auth`, `database`, `testing`, `docs`, `planning`, `tooling`, `general`.

If filter yields no results: "No todos in area '[area]'. Showing all todos instead."

## Step 3: List Todos

Read frontmatter from each todo file and display as a numbered list:

```
Pending Todos ([N] total):

1. [title] (area: [area], [relative age — e.g., "2d ago"])
2. [title] (area: [area], [relative age])
3. [title] (area: [area], [relative age])

Reply with a number to view details, or 'q' to exit.
```

Wait for selection.

## Step 4: Show Todo Detail

Read the full todo file:

```
## [title]

Area: [area]
Created: [date] ([relative age] ago)
Files: [list of file:line references, or "None"]

### Problem
[problem content]

### Solution
[solution content]
```

If files are listed, briefly check if they still exist and note if any were deleted or moved.

## Step 5: Check Roadmap Relevance

```bash
cat .planning/ROADMAP.md 2>/dev/null
```

Check if the todo's area or files overlap with any upcoming (not yet executed) phase. If yes, note: "This todo may relate to Phase [N]: [name]."

## Step 6: Offer Actions

Present actions based on context:

**If todo relates to a roadmap phase:**
```
This todo relates to Phase [N]: [name].

Actions:
1. Work on it now — move to done, start working immediately
2. Note for Phase [N] — keep pending, bring up when planning that phase
3. Brainstorm approach — think through the problem before deciding
4. Back to list

```

**If no roadmap match:**
```
Actions:
1. Work on it now — move to done, start working immediately
2. Create a phase — add a new phase to the roadmap for this work
3. Brainstorm approach — think through the problem before deciding
4. Back to list
```

Wait for choice.

## Step 7: Execute Action

**Work on it now:**
```bash
mv ".planning/todos/pending/[filename]" ".planning/todos/done/"
git add ".planning/todos/pending/[filename]" ".planning/todos/done/[filename]"
git commit -m "docs: start work on todo — [title]"
```

Present the problem and solution context. Begin work, or ask how to proceed.

**Note for Phase [N]:**
Keep in pending. Remind at planning time. Return to list.

**Create a phase:**
Suggest: `add-phase [description from todo title]`. Keep todo in pending. User runs the command.

**Brainstorm approach:**
Keep in pending. Begin discussing the problem — what approaches exist, trade-offs, what to investigate.

**Back to list:**
Return to Step 3.

## Step 8: Update STATE.md

After any action that changes the todo count:

```bash
PENDING=$(ls .planning/todos/pending/*.md 2>/dev/null | wc -l)
```

Update the `### Pending Todos` section in STATE.md with the new count.
