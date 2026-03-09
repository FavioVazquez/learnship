---
description: Surface Cascade's intended approach for a phase before planning starts — validate direction early
---

# List Phase Assumptions

Surface what Cascade intends to do for a phase before committing to a plan. This is **analysis of what Cascade thinks**, not intake of what you want — use `discuss-phase` for that.

**Use when:** You want to validate direction before planning, or you're unsure what approach will be taken.

**Usage:** `list-phase-assumptions [N]`

## Step 1: Validate Phase

Phase number is required:
```
Usage: list-phase-assumptions [N]
Example: list-phase-assumptions 3
```

Find phase `[N]` in ROADMAP.md:
```bash
grep -E "Phase [N]:" .planning/ROADMAP.md
```

If not found: list available phases and stop.

## Step 2: Load Context

```bash
cat .planning/ROADMAP.md
cat .planning/PROJECT.md
cat .planning/STATE.md
```

Check for CONTEXT.md (user decisions):
```bash
ls ".planning/phases/" 2>/dev/null | grep "^0*[N]-"
```

If CONTEXT.md exists, read it — it affects assumptions.

## Step 3: Analyze Phase

Based on the phase goal, project context, and codebase, surface assumptions across five dimensions. Be honest about confidence levels.

```
## My Assumptions for Phase [N]: [Phase Name]

### Technical Approach
What libraries, frameworks, or patterns I'd use:
- [Fairly confident:] I'd use [X] because [reason from phase context]
- [Assuming:] I'd structure this as [Y] because it fits the existing pattern
- [Unclear:] [Z] could go multiple ways depending on [ambiguity]

### Implementation Order
What I'd build first, second, third:
1. [First thing] — because it's foundational
2. [Second thing] — because it depends on #1
3. [Third thing] — because it integrates the pieces

### Scope Boundaries
**In scope:** [What I think this phase covers]
**Out of scope:** [What I'd defer to later phases]
**Ambiguous:** [Things that could go either way]

### Risk Areas
Where I anticipate complexity or challenges:
- [Tricky thing]: [Why it's hard and what I'd watch out for]
- [Potential issue]: [What could go wrong]

### Dependencies
**From prior phases:** [What must exist before this runs]
**External:** [Third-party dependencies needed]
**Feeds into:** [What later phases will need from this phase's output]

---

**What do you think?**

Are these assumptions accurate? Tell me:
- What I got right
- What I got wrong  
- What I'm missing
```

Wait for user response.

## Step 4: Acknowledge Feedback

**If corrections provided:**
```
Key corrections noted:
- [correction 1]
- [correction 2]

This changes my approach significantly: [summarize updated understanding]
```

**If assumptions confirmed:**
```
Assumptions validated. Ready to plan.
```

## Step 5: Offer Next Steps

```
What's next?

1. discuss-phase [N] — you answer my questions to build CONTEXT.md
2. plan-phase [N] — create plans now (assumptions noted above apply)
3. Re-examine — I'll analyze again with your corrections
```

Note: Any corrections discussed here are not automatically captured. Run `discuss-phase [N]` to write them to a CONTEXT.md that planners will read.

---

## Learning Checkpoint

Read `learning_mode` from `.planning/config.json`.

**If `auto`:** Offer:

> 💡 **Learning moment:** About to commit to an approach. Log the path not taken:
>
> `@agentic-learning either-or` — Record the alternatives considered, the choice made, and expected consequences. When the build goes sideways, this record tells you which assumption failed.

**If `manual`:** Add quietly: *"Tip: `@agentic-learning either-or` to log the approach decisions being made here."*
