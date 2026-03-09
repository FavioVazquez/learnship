---
description: Capture milestone-level goals, constraints, and anti-goals before new-milestone starts
---

# Discuss Milestone

Capture what the next milestone should achieve — and what it should explicitly *not* do — before committing to a roadmap. Produces a `MILESTONE-CONTEXT.md` that `new-milestone` reads to skip re-asking.

**Usage:** `discuss-milestone [version]` — e.g., `discuss-milestone v2.0`

**Run before:** `new-milestone`

## Step 1: Load Prior Context

Read what has already shipped:
```bash
cat .planning/PROJECT.md
cat .planning/STATE.md
ls .planning/milestones/ 2>/dev/null | sort -V | tail -3
```

Display the last milestone summary so the conversation starts informed:
```
Last shipped: [VERSION] — [Name]
[2-sentence summary from milestones archive]

Pending todos: [N] items
```

Check if a MILESTONE-CONTEXT.md already exists:
```bash
test -f .planning/MILESTONE-CONTEXT.md && echo "EXISTS"
```

If exists: ask "A milestone context file already exists from a prior discussion. Update it or start fresh?"

## Step 2: Discuss Goals

Ask openly: **"What do you want this milestone to achieve?"**

Follow the thread. Dig into:
- What user capability will exist after this milestone that doesn't exist now?
- What's the single most important thing to ship?
- Are there any dependencies on external things (APIs, other teams, timing)?
- Is there a deadline or forcing function?

## Step 3: Capture Anti-Goals

These are often the most valuable thing to capture explicitly:

Ask: **"What should this milestone explicitly NOT do?"**

Examples that reveal useful constraints:
- "Don't touch the auth system — it's in use by paying customers"
- "Don't add real-time features — that's v3"
- "Don't change the public API shape — clients depend on it"

If the user doesn't have strong anti-goals, prompt: "Any areas of the codebase that should be off-limits? Features that feel like scope creep for this cycle?"

## Step 4: Capture Constraints

Ask about practical constraints:
- **Team/time**: Solo? Team of N? Approximate timeline?
- **Quality bar**: Prototype/spike, or production-grade?
- **Known technical debt**: Anything that must be addressed in this milestone?
- **Architecture decisions already made**: Anything that constrains the approach?

## Step 5: Write MILESTONE-CONTEXT.md

Write `.planning/MILESTONE-CONTEXT.md`:

```markdown
---
version: [VERSION]
created: [date]
status: ready
---

# Milestone Context: [VERSION]

## Goals

[2-4 bullet points — what the user wants to achieve]

## Must-Have Features

[List of features/capabilities that define this milestone's success]

## Anti-Goals

[What this milestone explicitly does NOT include — equally important as goals]

## Constraints

- **Scope**: [Solo/Team, timeline if known]
- **Quality bar**: [prototype | production-grade]
- **Off-limits areas**: [parts of codebase not to touch]
- **Architecture constraints**: [decisions already locked in]

## Open Questions

[Anything unresolved that new-milestone should ask about]
```

## Step 6: Commit and Confirm

```bash
git add .planning/MILESTONE-CONTEXT.md
git commit -m "docs: capture milestone [VERSION] context"
```

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► MILESTONE CONTEXT CAPTURED ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone: [VERSION]
Goals: [N] captured
Anti-goals: [N] captured

▶ Next: new-milestone [VERSION]  (will read this context automatically)
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** About to start a new milestone. Brainstorm the design before locking scope:
>
> `@agentic-learning brainstorm [milestone topic]` — Talk through the new capabilities before committing. What's the mental model? What are the 2-3 ways this could be built? Surface blind spots now, not mid-execution.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning brainstorm [topic]` before new-milestone to surface approach alternatives."*
