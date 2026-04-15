# Pitfalls Research Template

Template for `.planning/research/PITFALLS.md` — common mistakes and prevention strategies for the project domain.

<template>

```markdown
# Pitfalls Research

**Domain:** [domain type]
**Researched:** [date]
**Confidence:** [HIGH/MEDIUM/LOW]

## Common Mistakes

| # | Mistake | Severity | Frequency | Impact |
|---|---------|----------|-----------|--------|
| 1 | [what goes wrong] | CRITICAL/HIGH/MEDIUM/LOW | [how often teams hit this] | [what breaks] |
| 2 | [what goes wrong] | CRITICAL/HIGH/MEDIUM/LOW | [how often teams hit this] | [what breaks] |
| 3 | [what goes wrong] | CRITICAL/HIGH/MEDIUM/LOW | [how often teams hit this] | [what breaks] |
| 4 | [what goes wrong] | CRITICAL/HIGH/MEDIUM/LOW | [how often teams hit this] | [what breaks] |
| 5 | [what goes wrong] | CRITICAL/HIGH/MEDIUM/LOW | [how often teams hit this] | [what breaks] |

### Mistake Details

**1. [Mistake name]**
- **What happens:** [detailed description of the failure mode]
- **Why it happens:** [root cause — usually a misunderstanding or shortcut]
- **Example:** [concrete scenario]
- **Fix cost:** [how expensive is it to fix after the fact]

**2. [Mistake name]**
- **What happens:** [detailed description]
- **Why it happens:** [root cause]
- **Example:** [concrete scenario]
- **Fix cost:** [cost to fix later]

## Warning Signs

Early indicators that a project is heading toward common pitfalls:

| Warning Sign | Indicates | Action |
|-------------|-----------|--------|
| [observable symptom] | [which mistake is brewing] | [what to do immediately] |
| [observable symptom] | [which mistake is brewing] | [what to do immediately] |
| [observable symptom] | [which mistake is brewing] | [what to do immediately] |

## Prevention Strategies

Proactive measures to avoid the mistakes above:

| Strategy | Prevents | When to Apply | How |
|----------|----------|---------------|-----|
| [strategy name] | [mistake #N] | [at what phase/stage] | [concrete implementation steps] |
| [strategy name] | [mistake #N] | [at what phase/stage] | [concrete implementation steps] |
| [strategy name] | [mistake #N] | [at what phase/stage] | [concrete implementation steps] |

## Domain-Specific Patterns

### Patterns That Look Right But Aren't

| Pattern | Why It Seems Good | Actual Problem | Better Approach |
|---------|-------------------|----------------|-----------------|
| [pattern] | [surface appeal] | [hidden issue] | [what to do instead] |
| [pattern] | [surface appeal] | [hidden issue] | [what to do instead] |

### Patterns That Look Wrong But Work

| Pattern | Why It Seems Bad | Why It Actually Works | When to Use |
|---------|------------------|----------------------|-------------|
| [pattern] | [surface concern] | [deeper reason] | [specific conditions] |

---
*Pitfalls research for: [domain]*
*Researched: [date]*
```

</template>

<guidelines>

**Common Mistakes:**
- Rank by severity — CRITICAL mistakes should be listed first
- Include fix cost — some mistakes are cheap to fix later, others are architectural
- Be specific: "not handling auth token refresh" not "bad auth"

**Warning Signs:**
- These are observable symptoms, not the mistakes themselves
- Help the executor recognize when things are going wrong mid-implementation
- Each warning sign should map to a specific mistake

**Prevention Strategies:**
- Must be actionable — "be careful" is not a strategy
- Include when to apply (during planning, during implementation, during testing)
- Reference specific mistakes they prevent

**Domain-Specific Patterns:**
- "Looks right but isn't" catches cargo-cult patterns
- "Looks wrong but works" prevents premature optimization of working patterns
- Both require domain expertise to identify

</guidelines>
