# Roadmap: Chispa v1.1 — Impeccable UI

**Milestone:** v1.1 — Impeccable UI
**Total phases:** 2 (phases 5–6, continuing from v1.0 phases 1–4)
**Total v1.1 requirements:** 15
**Coverage:** 15/15 ✓ (planned)

---

## Phase 5 — Design Foundation *(in progress)*

**Goal:** Establish the design system — distinctive display font, refined color tokens,
improved surface depth, and a redesigned brand header. Everything downstream builds on this.

**Requirements covered:** UI-01, UI-02, UI-03, UI-04, UI-05, UI-06

**Success criteria:**
- After this phase, `Space Grotesk` appears in the App header and `Plus Jakarta Sans` is the body font
- After this phase, the App header is visually commanding — legible from 10 feet at a conference
- After this phase, dashboard cards have clear depth against the background (not the same gray)
- After this phase, borders are visible without hovering — structural, not invisible
- After this phase, a type scale is applied: heading/subheading/body/caption are visually distinct

**Plans:**
- `05-01`: Font system + color tokens (index.html, tailwind.config.js, index.css)
- `05-02`: App header redesign (App.tsx)

**Notes:**
- Google Fonts with `display=swap` + `preconnect` — acceptable for conference localhost demo
- No new npm packages — lucide-react already installed, fonts via CDN link
- Keep primary purple `#7c3aed` unchanged — brand color that's already in demos

---

## Phase 6 — Component Polish

**Goal:** Apply the design system to every component. The activity feed needs visual
energy. The verdict needs to feel like a reveal. Each card needs its own visual identity
rather than being interchangeable gray boxes.

**Requirements covered:** UI-07, UI-08, UI-09, UI-10, UI-11, UI-12, UI-13, UI-14, UI-15

**Success criteria:**
- After this phase, IdeaForm has a visible select chevron and a submit button that feels intentional
- After this phase, ActivityFeed steps feel live — the feed has energy, not a plain list
- After this phase, VerdictCard verdict text uses Space Grotesk and fills the visual space
- After this phase, MarketSnapshot shows market size as a prominent stat, not a label/value pair
- After this phase, CompetitorCard has a larger favicon and clearer name hierarchy
- After this phase, RiskRadarChart grid is visible and fill is readable
- After this phase, FirstSteps list items animate in with stagger (0–4 items, 50ms apart)
- After this phase, ShareButton shows Link2 icon from lucide-react

**Plans:**
- `06-01`: IdeaForm + ActivityFeed
- `06-02`: VerdictCard + MarketSnapshot + CompetitorCard
- `06-03`: RiskRadarChart + FirstSteps + ShareButton + Dashboard sections

**Notes:**
- All animations respect `useReducedMotion()` — already used throughout codebase
- Do NOT change server code, types, or analysis logic — UI-only changes
- Test `typecheck` after each plan to catch Tailwind class typos (JSX string literals)

---

## Requirement → Phase Mapping

| Req | Phase | Component |
|-----|-------|-----------|
| UI-01 | 5 | index.html, tailwind.config.js |
| UI-02 | 5 | index.html, tailwind.config.js, index.css |
| UI-03 | 5 | App.tsx, all components |
| UI-04 | 5 | App.tsx |
| UI-05 | 5 | tailwind.config.js |
| UI-06 | 5 | tailwind.config.js |
| UI-07 | 6 | IdeaForm.tsx |
| UI-08 | 6 | ActivityFeed.tsx |
| UI-09 | 6 | VerdictCard.tsx |
| UI-10 | 6 | Dashboard.tsx |
| UI-11 | 6 | CompetitorCard.tsx |
| UI-12 | 6 | MarketSnapshot.tsx |
| UI-13 | 6 | RiskRadarChart.tsx |
| UI-14 | 6 | FirstSteps.tsx |
| UI-15 | 6 | ShareButton.tsx |

**Coverage: 15/15 ✓**

---

## v1.0 Roadmap (archived)

See milestones/v1.0-SUMMARY.md for the v1.0 phase breakdown.

---
*Roadmap created: 2026-05-27*
