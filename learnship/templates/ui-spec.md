---
phase: {N}
slug: {phase-slug}
status: draft
created: {date}
---

# Phase {N} — UI Design Contract

> Visual and interaction contract for frontend phases. Verified against impeccable standards.

---

## Design System

| Property | Value |
|----------|-------|
| Component library | {library or "none"} |
| Icon library | {library} |
| Font | {font} |
| CSS approach | {tailwind / css modules / styled-components / etc.} |

---

## Spacing Scale

Declared values (must be multiples of 4):

| Token | Value | Usage |
|-------|-------|-------|
| xs | 4px | Icon gaps, inline padding |
| sm | 8px | Compact element spacing |
| md | 16px | Default element spacing |
| lg | 24px | Section padding |
| xl | 32px | Layout gaps |
| 2xl | 48px | Major section breaks |
| 3xl | 64px | Page-level spacing |

Exceptions: {list any, or "none"}

---

## Typography

| Role | Size | Weight | Line Height |
|------|------|--------|-------------|
| Body | {px} | {weight} | {ratio} |
| Label | {px} | {weight} | {ratio} |
| Heading | {px} | {weight} | {ratio} |
| Display | {px} | {weight} | {ratio} |

---

## Color

| Role | Value | Usage |
|------|-------|-------|
| Primary | {hex} | Buttons, links, active states |
| Secondary | {hex} | Supporting actions |
| Neutral | {hex} | Text, borders, backgrounds |
| Success | {hex} | Confirmations, positive states |
| Warning | {hex} | Cautions, pending states |
| Error | {hex} | Errors, destructive actions |

---

## Key Components

| Component | Spec |
|-----------|------|
| {component} | {key constraints: size, padding, border-radius, shadow} |

---

## Interaction Patterns

| Pattern | Behavior |
|---------|----------|
| Loading | {skeleton / spinner / progressive} |
| Empty state | {illustration + CTA / minimal text / guided action} |
| Error state | {inline / toast / modal / redirect} |
| Transitions | {duration, easing, what animates} |

---

## Responsive Breakpoints

| Breakpoint | Width | Layout Changes |
|------------|-------|----------------|
| Mobile | < 640px | {description} |
| Tablet | 640-1024px | {description} |
| Desktop | > 1024px | {description} |

---

## Impeccable Checklist

- [ ] No overused fonts (Inter, Roboto, Arial)
- [ ] No AI palette (cyan-on-dark, purple-to-blue gradients)
- [ ] No pure black (#000) or pure white (#fff) — tinted neutrals
- [ ] No nested cards inside cards
- [ ] No large rounded icons above every heading
- [ ] At least one intentional, memorable design decision
- [ ] Typography has clear visual hierarchy with modular scale
- [ ] Spacing creates rhythm through variation, not uniformity

**If someone saw this interface and immediately thought AI made it — that is the problem.**
