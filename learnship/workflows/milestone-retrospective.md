---
description: Structured learning retrospective at end of milestone — 5 questions, produces RETROSPECTIVE.md, triggers spaced review
---

# Milestone Retrospective

A structured learning retrospective after a milestone ships. Five focused questions surface what was learned, what worked, what didn't, and what to carry forward. Produces a `RETROSPECTIVE.md` and schedules key concepts for spaced review.

**Usage:** `milestone-retrospective`

**Run after:** `complete-milestone`

## Step 1: Load Context

Read the milestone that just shipped:
```bash
ls .planning/milestones/ | sort -V | tail -3
cat .planning/milestones/[VERSION]-ROADMAP.md 2>/dev/null | head -60
```

Read all phase SUMMARY.md files from this milestone:
```bash
ls .planning/milestones/[VERSION]-phases/*/*-SUMMARY.md 2>/dev/null || \
ls .planning/phases/*/*-SUMMARY.md 2>/dev/null
```

Read the debug sessions log for this milestone:
```bash
ls .planning/debug/resolved/ 2>/dev/null
```

Read DECISIONS.md entries from this milestone period:
```bash
cat .planning/DECISIONS.md 2>/dev/null | grep -A 8 "Phase [1-[N]]"
```

Display:
```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► MILESTONE RETROSPECTIVE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Milestone: [VERSION] — [Name]
Phases completed: [N]
Bugs fixed: [M] (from debug sessions)
Decisions made: [K]
```

## Step 2: Five Retrospective Questions

Ask each question and wait for a real answer before moving to the next. These are not checkboxes — they're reflection prompts.

**Question 1: What did you actually build?**
"Describe [VERSION] in your own words — not the requirements, but what you actually created. What can a user do now that they couldn't before?"

**Question 2: What was harder than expected?**
"Which phase or task took longer or required more rework than you anticipated? What made it hard?"

**Question 3: What worked surprisingly well?**
"Any decision, approach, or tool that paid off more than expected? Anything you'd do the same way next time?"

**Question 4: What would you do differently?**
"If you were starting this milestone over with what you know now — what's the one thing you'd change?"

**Question 5: What should carry forward?**
"Any patterns, decisions, or lessons from this milestone that should explicitly inform the next one? What goes into the decision register?"

## Step 3: Synthesize Themes

After all five answers, synthesize the key themes:

```
Retrospective themes:

What we learned:
- [theme 1]
- [theme 2]

What to repeat:
- [approach/decision to carry forward]

What to avoid:
- [approach/anti-pattern to explicitly skip next time]

Decisions to add to register:
- [decision to capture in DECISIONS.md]
```

Ask: "Does this capture it? Anything to add or change?"

## Step 4: Write RETROSPECTIVE.md

Write `.planning/milestones/[VERSION]-RETROSPECTIVE.md`:

```markdown
---
milestone: [VERSION]
created: [date]
---

# Milestone Retrospective: [VERSION] — [Name]

## What Was Built

[Answer to Q1 — user's own words]

## What Was Hard

[Answer to Q2]

## What Worked Well

[Answer to Q3]

## What to Do Differently

[Answer to Q4]

## Carry Forward

[Answer to Q5]

---

## Key Learnings (for next milestone)

[Synthesized themes — the 3-5 most actionable takeaways]

## Decisions to Register

[Any decisions surfaced that should be added to DECISIONS.md]
```

## Step 5: Update DECISIONS.md

For each decision surfaced in the retrospective, append to `.planning/DECISIONS.md`:

```markdown
## DEC-[XXX]: [title — from retrospective]
**Date:** [date] | **Phase:** retrospective | **Type:** lesson
**Context:** [what situation surfaced this]
**Choice:** [what we learned / what to do]
**Rationale:** [from the retrospective answer]
**Consequences:** [what this means for the next milestone]
**Status:** active
```

## Step 6: Commit

```bash
git add .planning/milestones/[VERSION]-RETROSPECTIVE.md .planning/DECISIONS.md
git commit -m "docs: add [VERSION] retrospective and carry-forward decisions"
```

## Step 7: Schedule for Spaced Review

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 learnship ► RETROSPECTIVE COMPLETE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Saved: .planning/milestones/[VERSION]-RETROSPECTIVE.md
Decisions added: [N]
```

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer (always, not conditional — retrospective IS the learning moment):

> 💡 **Now schedule what you just reflected on:**
>
> `@agentic-learning space` — Identifies the key concepts and patterns from this milestone and schedules them for spaced review. Writes to `docs/revisit.md`. The next milestone starts smarter because of this.

**If `manual`:** Offer: *"Tip: `@agentic-learning space` to schedule the key patterns from this milestone for review before the next one starts."*
