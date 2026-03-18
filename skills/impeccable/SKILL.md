---
name: impeccable
description: >
  A design quality system for frontend interfaces. 18 focused actions for
  auditing, refining, and elevating UI quality. Invoke with @impeccable
  followed by one of: adapt, animate, audit, bolder, clarify, colorize,
  critique, delight, distill, extract, frontend-design, harden, normalize,
  onboard, optimize, polish, quieter, or teach-impeccable.
license: MIT
compatibility: Works with Windsurf Cascade, Claude Code, and any AgentSkills-compatible agent.
metadata:
  author: favio-vazquez
  version: "1.0"
---

# Impeccable

A design quality system composed of 18 focused actions for auditing, refining,
and elevating frontend interfaces. Each action is a specialist — invoke the one
that matches your current need.

**Core principle:** Good design is intentional. Every action here resists vague
"make it better" requests by applying a specific, disciplined lens. Use
`frontend-design` as the foundation — all other actions reference its
principles and anti-patterns.

---

## Actions

### `adapt` — Responsive & cross-platform adaptation
[adapt/SKILL.md](adapt/SKILL.md)

### `animate` — Purposeful motion & micro-interactions
[animate/SKILL.md](animate/SKILL.md)

### `audit` — Comprehensive quality audit
[audit/SKILL.md](audit/SKILL.md)

### `bolder` — Amplify safe or boring designs
[bolder/SKILL.md](bolder/SKILL.md)

### `clarify` — UX copy, microcopy & labels
[clarify/SKILL.md](clarify/SKILL.md)

### `colorize` — Strategic color addition
[colorize/SKILL.md](colorize/SKILL.md)

### `critique` — UX effectiveness evaluation
[critique/SKILL.md](critique/SKILL.md)

### `delight` — Moments of joy & personality
[delight/SKILL.md](delight/SKILL.md)

### `distill` — Strip to essence
[distill/SKILL.md](distill/SKILL.md)

### `extract` — Reusable components & design tokens
[extract/SKILL.md](extract/SKILL.md)

### `frontend-design` — Design foundation & principles
[frontend-design/SKILL.md](frontend-design/SKILL.md)

### `harden` — Resilience, i18n & edge cases
[harden/SKILL.md](harden/SKILL.md)

### `normalize` — Design system consistency
[normalize/SKILL.md](normalize/SKILL.md)

### `onboard` — Onboarding flows & empty states
[onboard/SKILL.md](onboard/SKILL.md)

### `optimize` — Performance & loading speed
[optimize/SKILL.md](optimize/SKILL.md)

### `polish` — Final quality pass before shipping
[polish/SKILL.md](polish/SKILL.md)

### `quieter` — Tone down aggressive designs
[quieter/SKILL.md](quieter/SKILL.md)

### `teach-impeccable` — Project design context setup
[teach-impeccable/SKILL.md](teach-impeccable/SKILL.md)

---

## How to use

Invoke with the action that matches your need:

```
@impeccable audit          — full quality audit report
@impeccable polish         — final pass before shipping
@impeccable critique       — UX effectiveness review
@impeccable normalize      — align with design system
@impeccable frontend-design — apply design foundation principles
```

When in doubt, start with `@impeccable audit` to get a full picture, then
use the specific action it recommends.

---

## After running any impeccable action

When an impeccable action produces a list of recommendations, improvements, or issues — always close with this suggestion:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 impeccable ► RECOMMENDATIONS READY
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[N] improvements identified. To apply them in a traceable, structured way:

▶ Run `/new-milestone` to create a dedicated "UI Polish" or "Design Quality" milestone.
  This turns these recommendations into versioned phases with plans, commits, and
  verification — so nothing gets lost and every improvement is auditable.

Or apply them directly now and use `/decision-log` to record what was changed and why.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

This applies after: `audit`, `critique`, `polish`, `normalize`, `harden`, `adapt`, `optimize`, `bolder`, `quieter`, `colorize`, `clarify`, `delight`, `onboard`, `animate`, `distill`, `extract`.

For `teach-impeccable` and `frontend-design` (which set up context, not produce recommendations), skip this suggestion.
