# Requirements: Chispa v1.1 — Impeccable UI

**Milestone:** v1.1 — Impeccable UI
**Date:** 2026-05-27
**Audit basis:** Impeccable full audit (see research/UI-AUDIT.md)

---

## Context

v1.0 delivered a functionally correct startup validator. The UI works but is visually
generic: Inter-only typography, flat hierarchy (nearly everything `text-sm`), identical
`bg-surface border border-border rounded-xl p-6` containers throughout. v1.1 applies
the impeccable design system to produce a UI that commands attention on a conference
projection screen.

No changes to server code, API, or Claude integration. UI-only milestone.

---

## v1.1 Requirements

| ID | Phase | Category | Description |
|----|-------|----------|-------------|
| UI-01 | 5 | Typography | Add Space Grotesk display font for brand header and verdict moments |
| UI-02 | 5 | Typography | Add Plus Jakarta Sans as primary body font (replace Inter) |
| UI-03 | 5 | Typography | Establish type scale: display / heading / subheading / body / caption — not all `text-sm` |
| UI-04 | 5 | Brand | Redesign App header — larger brand moment with subtle depth treatment |
| UI-05 | 5 | Color | Improve surface/background differentiation so cards have visible depth |
| UI-06 | 5 | Color | Strengthen border system — `border` token more visible, add `border-strong` for emphasis |
| UI-07 | 6 | Form | IdeaForm: add ChevronDown to select, better textarea focus ring, stronger submit button |
| UI-08 | 6 | ActivityFeed | Redesign feed to feel alive — accent bar header, larger step bullets, animated latest step |
| UI-09 | 6 | VerdictCard | Use Space Grotesk for verdict word, increase size, improve padding proportions |
| UI-10 | 6 | Dashboard | Section heading differentiation — accent line or muted treatment, not same as card labels |
| UI-11 | 6 | CompetitorCard | Larger favicon (28px), better name/description hierarchy |
| UI-12 | 6 | MarketSnapshot | Market size and growth values displayed at larger scale (stat display, not label/value) |
| UI-13 | 6 | RiskRadarChart | Brighter grid lines, higher fill opacity, axis labels more readable |
| UI-14 | 6 | FirstSteps | Stagger-animate list items on mount (0.05s delay per item via Framer Motion) |
| UI-15 | 6 | ShareButton | Replace Unicode arrow with Link2 Lucide icon; polish copy feedback |

---

## v2 Candidates (future milestone)

- Mobile-responsive layout (currently desktop-first for conference demo)
- Dark/light mode toggle
- Custom illustrations for empty/error states
- Celebratory animation (confetti) on LAUNCH verdict
- Streaming text animation for verdictReason

---

## Out of Scope for v1.1

- No changes to server, API, or Claude agent
- No new product features
- No database, auth, or deployment changes
- No test coverage (deferred from v1.0)

---

## Traceability

| ID | Component(s) | Notes |
|----|-------------|-------|
| UI-01 | index.html, tailwind.config.js | Google Fonts: Space Grotesk 700 |
| UI-02 | index.html, tailwind.config.js, index.css | Google Fonts: Plus Jakarta Sans 400/500/600/700 |
| UI-03 | All components | Apply font-display, font-heading, consistent size usage |
| UI-04 | App.tsx | Header section redesign |
| UI-05 | tailwind.config.js | surface: '#0e0e18', surface-elevated: '#151523' |
| UI-06 | tailwind.config.js | border: '#252538', border-strong: '#3b3b55' |
| UI-07 | IdeaForm.tsx | ChevronDown from lucide-react (already installed) |
| UI-08 | ActivityFeed.tsx | Accent border header, pulse on latest step |
| UI-09 | VerdictCard.tsx | font-display class, larger verdict text, better proportions |
| UI-10 | Dashboard.tsx | Section separator treatment |
| UI-11 | CompetitorCard.tsx | Favicon size, hierarchy |
| UI-12 | MarketSnapshot.tsx | Stat-style display for values |
| UI-13 | RiskRadarChart.tsx | PolarGrid stroke, fillOpacity |
| UI-14 | FirstSteps.tsx | Framer Motion stagger with index-based delay |
| UI-15 | ShareButton.tsx | Link2 from lucide-react |

---

## v1.0 Requirements (archived — all shipped)

All 26 v1.0 requirements shipped and verified. See milestones/v1.0-SUMMARY.md.

---
*Created: 2026-05-27*
