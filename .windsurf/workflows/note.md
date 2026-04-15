---
description: Zero-friction idea capture — one write, one confirmation line, no questions
---

# Note

Zero-friction idea capture. One write call, one confirmation line. No questions, no prompts. Runs inline — no subagents.

**Usage:**
- `note [text]` — save a note
- `note list` — show all notes
- `note promote [N]` — promote note N to a todo or decision

Notes are different from todos: **notes are observations**, todos are actions.

## Step 1: Parse Subcommand

| Condition | Subcommand |
|-----------|------------|
| Arguments are exactly `list` (case-insensitive) | **list** |
| Arguments are exactly `promote [N]` where N is a number | **promote** |
| Arguments are empty (no text at all) | **list** |
| Anything else | **append** (the text IS the note) |

**Critical:** `list` is only a subcommand when it's the ENTIRE argument. `note list of groceries` saves a note with text "list of groceries".

## Step 2: Determine Scope

- **Project scope** (default): `.planning/notes/` — used when `.planning/` exists
- **Global scope** (fallback): use project scope if `.planning/` exists, otherwise tell user no project is initialized

**Important:** Do NOT create `.planning/` if it doesn't exist. Fall back gracefully.

## Step 3a: Append — Create a Timestamped Note

1. Ensure notes directory exists:
```bash
node -e "require('fs').mkdirSync('.planning/notes',{recursive:true})"
```

2. Generate slug: first ~4 meaningful words, lowercase, hyphen-separated
3. Generate filename: `{YYYY-MM-DD}-{slug}.md`
   - If file exists, append `-2`, `-3`, etc.

4. Write the file:
```markdown
---
date: "YYYY-MM-DD HH:mm"
promoted: false
---

{note text verbatim}
```

5. Confirm with exactly one line: `Noted: {note text}`

**Constraints:**
- **Never modify the note text** — capture verbatim, including typos
- **Never ask questions** — just write and confirm

## Step 3b: List — Show All Notes

```bash
ls .planning/notes/*.md 2>/dev/null
```

For each file, read frontmatter to get `date` and `promoted` status. Sort by date, number sequentially.

Display:
```
## Notes

 #  | Date       | Note
----|------------|------
 1  | 2025-01-20 | [first line of note text]
 2  | 2025-01-21 | [first line of note text]
 *3 | 2025-01-22 | [promoted — first line] 

[N] notes ([M] active, [K] promoted)
```

Promoted notes shown with `*` prefix and dimmed.

## Step 3c: Promote — Convert Note to Action

Read note N from the numbered list. Display the full note text.

Ask: "Promote this note to:"
- **Todo** — create via `/add-todo [note text]`
- **Decision** — create via `/decision-log [note text]`
- **Phase proposal** — create via `/add-phase [note text]`
- **Keep as note** — cancel

After promoting, update the note's frontmatter: `promoted: true`.

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto` and this is an append:** No learning prompt for notes — keep it fast.

**If `auto` and this is a promote:**

> **Learning moment:** Promoting a note means the idea had lasting value:
>
> `@agentic-learning either-or` — Why did this note survive? What made it worth promoting over others? Log the reasoning.

**If `manual`:** No note for notes — keep it fast.
