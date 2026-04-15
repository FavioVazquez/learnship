# Design Steering Commands

Steering commands for the frontend-design skill. Invoke these during any UI work to get targeted design guidance, critique, and improvements.

---

## Full Command Reference

| Command | What it triggers |
|---------|-----------------|
| `/audit` | Comprehensive UI quality audit against the full design checklist |
| `/critique` | Candid design critique — what's working, what isn't, specific improvements |
| `/polish` | Refine and elevate an existing interface — details, spacing, hierarchy |
| `/motion` | Add purposeful motion: entrances, transitions, state changes |
| `/tokens` | Design token system: color, spacing, typography scale, border radius |
| `/brand` | Brand coherence check across all surfaces |
| `/typography` | Typography system: scale, pairing, hierarchy, loading |
| `/color` | Color palette review: OKLCH, contrast ratios, dark mode, tinting |
| `/layout` | Layout and spatial rhythm: grid, breathing room, asymmetry |
| `/responsive` | Mobile-first: container queries, fluid design, breakpoints |
| `/interaction` | Interaction design: forms, focus states, loading patterns, optimistic UI |
| `/accessibility` | Accessibility: focus management, contrast, screen reader support |
| `/empty-states` | Empty state design that teaches the interface |
| `/loading` | Loading patterns: skeletons, spinners, progressive disclosure |
| `/forms` | Form UX: labels, validation, error states, field grouping |
| `/copy` | UX writing: labels, errors, empty states, CTAs |
| `/density` | Information density: when to compress, when to breathe |

---

## When to Use Each

### Starting a new component or page
→ `/audit` first — understand what quality problems to avoid before writing a line

### After first implementation pass
→ `/critique` — honest feedback before spending time on polish
→ `/layout` — is the spatial rhythm right?

### Typography feels off
→ `/typography` — systematic review of scale, pairing, hierarchy
→ `/copy` — are the words doing their job?

### Colors feel wrong or generic
→ `/color` — OKLCH-based palette review, tinting strategy, contrast
→ `/tokens` — establish a proper design token system

### Interface feels stiff or lifeless
→ `/motion` — purposeful animation for state changes and entrances
→ `/interaction` — does every interactive surface feel responsive?

### Shipping to production
→ `/accessibility` — focus, contrast ratios, screen reader support
→ `/responsive` — does it adapt properly at all sizes?
→ `/polish` — final refinement pass

### Something feels "AI-generated"
→ `/critique` — the AI slop test: would someone immediately recognize this as AI output?

---

## The Anti-Patterns to Watch For

The design skill actively guards against these common AI aesthetics:

**Colors:**
- Cyan-on-dark with purple-to-blue gradients
- Neon accents on dark backgrounds
- Pure black (#000) or pure white (#fff)
- Gray text on colored backgrounds

**Layout:**
- Everything in cards — not everything needs a container
- Nested cards inside cards
- Identical card grids (same-sized cards with icon + heading + text, repeated)
- Centering everything
- The "hero metric" template: big number, small label, gradient accent

**Typography:**
- Overused fonts: Inter, Roboto, Arial, Open Sans, system defaults
- Monospace as lazy "developer vibes"
- Large rounded icons above every heading

**Motion:**
- Bounce or elastic easing
- Animating layout properties (width, height, padding, margin)
- Scattered micro-interactions everywhere

**Details:**
- Glassmorphism used decoratively (not purposefully)
- Rounded elements with thick one-sided colored borders
- Generic rounded rectangles with drop shadows
- Gradient text for "impact" on metrics or headings

---

## The AI Slop Test

Before shipping any interface, ask:

> If you showed this to someone and said "AI made this" — would they believe you immediately?

If yes: use `/critique` to find what makes it look templated, then `/polish` to address it.

A well-designed interface makes someone ask **"how was this made?"** not "which AI made this?"

---

## Reference Files

The design skill includes 7 domain-specific reference files:

- `reference/typography.md` — scales, pairing, fluid sizing with clamp()
- `reference/color-and-contrast.md` — OKLCH, palettes, dark mode strategy
- `reference/spatial-design.md` — grids, rhythm, container queries
- `reference/motion-design.md` — timing, easing curves, reduced motion
- `reference/interaction-design.md` — forms, focus, loading patterns
- `reference/responsive-design.md` — mobile-first, fluid design, breakpoints
- `reference/ux-writing.md` — labels, errors, empty states, microcopy
