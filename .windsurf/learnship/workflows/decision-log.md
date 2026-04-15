---
description: Capture an architectural or scope decision with its context, alternatives, and rationale into .planning/DECISIONS.md
---

# Decision Log

Capture a decision — architectural choice, library pick, scope trade-off, pattern selection — into `.planning/DECISIONS.md`. The decision register is the project's institutional memory: it tells future Cascade (and future you) *why* the project is built the way it is.

**Usage:** `decision-log [description]` or just `decision-log` to capture from recent conversation.

## Step 1: Extract Decision Content

**With description argument:** Use it as the decision title/focus.

**Without argument:** Analyze recent conversation to extract the decision being made:
- What choice was just discussed or made?
- What were the alternatives?
- What was the rationale?
- What does this lock in or foreclose?

Formulate:
- `title` — 3-8 words (e.g., "Use Zustand over Redux for state", "Single-table DynamoDB design")
- `type` — `architecture` | `library` | `scope` | `pattern` | `lesson`
- `context` — why this decision was needed (1-2 sentences)
- `options` — alternatives that were considered (list)
- `choice` — what was decided
- `rationale` — why this choice over the alternatives
- `consequences` — what this locks in or makes harder

## Step 2: Read Existing DECISIONS.md

```bash
cat .planning/DECISIONS.md 2>/dev/null || echo "File does not exist yet."
```

If it doesn't exist, it will be created. Note the highest existing DEC-XXX number to assign the next ID.

## Step 3: Check for Conflicts

Scan existing decisions for any that might conflict with or be superseded by the new one:

```bash
grep -i "[key words from title]" .planning/DECISIONS.md 2>/dev/null
```

If a related decision exists, show it and ask: "This may relate to DEC-[XXX]: [title]. Is this a new decision, or does it update/supersede the existing one?"

- **New decision** → create DEC-[next]
- **Updates existing** → add a note to existing entry, create new entry with `supersedes: DEC-[XXX]`

## Step 4: Read Phase Context

```bash
cat .planning/STATE.md | grep "Phase:"
```

Note the current phase number for the decision record.

## Step 5: Write to DECISIONS.md

If DECISIONS.md doesn't exist, create it with header:

```markdown
# Decisions Register

A living record of architectural, scope, and pattern decisions made during this project.
Each entry captures context, alternatives considered, and rationale — so future sessions
understand *why* the project is built the way it is.

Read this before proposing approaches that may conflict with prior decisions.

---
```

Append the new entry:

```markdown
## DEC-[XXX]: [title]

**Date:** [YYYY-MM-DD] | **Phase:** [N] | **Type:** [type]

**Context:** [why this decision was needed]

**Options considered:**
- [option A]: [brief description and trade-off]
- [option B]: [brief description and trade-off]

**Choice:** [what was decided]

**Rationale:** [why this over the alternatives]

**Consequences:** [what this locks in, what it makes harder, what it enables]

**Status:** active

---
```

## Step 6: Commit

```bash
git add .planning/DECISIONS.md
git commit -m "docs: log decision — [title]"
```

## Step 7: Confirm

```
Decision logged: DEC-[XXX]

  [title]
  Type: [type] | Phase: [N]

Decisions register: .planning/DECISIONS.md ([N] total decisions)

Continue with current work, or capture another with decision-log.
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** After logging a significant architectural decision:

> 💡 **Decision logged.** Want to explore it deeper?
>
> `@agentic-learning either-or` — Walk through the decision more systematically: what did each option optimize for? What would have to be true for the other option to have been better? This builds the decision-making intuition, not just the record.

**If `manual`:** No note (keep it fast — this workflow is meant to be a quick capture).
