# Summary Research Template

Template for `.planning/research/SUMMARY.md` — synthesis of all research findings into actionable guidance.

<template>

```markdown
# Research Summary

**Domain:** [domain type]
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Recommended Stack

### Primary Technologies

| Technology | Version | Role |
|------------|---------|------|
| [name] | [version] | [primary purpose in this project] |
| [name] | [version] | [primary purpose in this project] |
| [name] | [version] | [primary purpose in this project] |

### Key Stack Decisions

- **[Decision 1]:** [rationale — why this over alternatives]
- **[Decision 2]:** [rationale]
- **[Decision 3]:** [rationale]

## Table Stakes Features

Features that must be in v1 — users expect these by default:

- [ ] [Feature] — [one-line description]
- [ ] [Feature] — [one-line description]
- [ ] [Feature] — [one-line description]
- [ ] [Feature] — [one-line description]

## Key Architecture Decisions

### System Shape

[1-2 sentences describing the overall architecture pattern — e.g., "Monolithic Next.js app with server components, Postgres via Prisma ORM, and Stripe for payments."]

### Critical Boundaries

| Boundary | What It Separates | Why It Matters |
|----------|-------------------|----------------|
| [boundary] | [side A] / [side B] | [architectural significance] |
| [boundary] | [side A] / [side B] | [architectural significance] |

### Recommended Build Order

1. [Component] — [why first]
2. [Component] — [depends on #1]
3. [Component] — [depends on #1, #2]
4. [Component] — [depends on previous]

## Top Pitfalls

The most dangerous mistakes for this domain, ranked by severity:

| # | Pitfall | Severity | Prevention |
|---|---------|----------|------------|
| 1 | [mistake] | CRITICAL | [one-line prevention strategy] |
| 2 | [mistake] | HIGH | [one-line prevention strategy] |
| 3 | [mistake] | HIGH | [one-line prevention strategy] |
| 4 | [mistake] | MEDIUM | [one-line prevention strategy] |
| 5 | [mistake] | MEDIUM | [one-line prevention strategy] |

## Primary Recommendation

[One paragraph — the single most important takeaway from this research. What should the planner prioritize above all else?]

---
*Research summary for: [domain]*
*Researched: [date]*
*Sources: STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md*
```

</template>

<guidelines>

**Purpose:**
- This file synthesizes the other 4 research files into a single actionable reference
- The planner reads this file first — it should contain everything needed to start planning
- Keep it concise: tables and bullet points, not paragraphs

**Recommended Stack:**
- Only include the primary technologies — no supporting libraries
- Key decisions explain WHY, not just WHAT

**Table Stakes Features:**
- Pull directly from FEATURES.md Table Stakes section
- These become the v1 must_haves in requirements

**Key Architecture Decisions:**
- System shape in 1-2 sentences — enough for the planner to understand the pattern
- Build order feeds directly into roadmap phase ordering

**Top Pitfalls:**
- Maximum 5 — the most dangerous ones only
- Each must have a one-line prevention strategy
- These become verification checkpoints during execution

**Primary Recommendation:**
- One paragraph, one decision
- This is what the planner optimizes for

</guidelines>
