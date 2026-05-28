# Impeccable UI Audit — Chispa v1.0

**Date:** 2026-05-27
**Scope:** Full client-side UI (all 9 components + App.tsx + index.css)
**Auditor:** impeccable audit action

---

## Anti-Patterns Verdict: MOSTLY CLEAR (with gaps)

Not full AI slop, but shows some generic tells:
- **Inter-only typography** — used by ~40% of all websites; no visual personality
- **Uniform rounded rectangles** — every component is `rounded-xl bg-surface border border-border p-6`; interchangeable, undifferentiated
- **Purple accent on dark** — `#7c3aed` is Tailwind violet-600, recognizable as a default

**What avoids the AI slop trap:**
- No gradient text, no glassmorphism, no hero metric layout
- VerdictCard's dynamic color system is genuinely well-designed
- Framer Motion is used purposefully with `useReducedMotion()` respecting accessibility
- MarketSnapshot timing badge has proper semantic color

---

## Executive Summary

| Category | Issues | Critical |
|----------|--------|---------|
| Typography | 4 | 2 |
| Color/Surface | 3 | 0 |
| Component-specific | 8 | 0 |
| Positive findings | 6 | — |

**Overall assessment:** Functionally sound, visually generic. The system works but
lacks the visual differentiation needed to command attention at a conference. The
hierarchy problem is systemic: almost everything renders as `text-sm` in grays
`text-gray-300` through `text-gray-500`, creating a flat, undifferentiated field.

---

## Critical Issues

### C1 — Typography: Single font family, no hierarchy

**Location:** `index.css`, `tailwind.config.js`, all components
**Impact:** No visual personality; every element looks equally important

Inter is used for everything from the brand name to footnote-level labels.
There is no differentiation through font choice — hierarchy is attempted only
through size (inconsistently) and opacity/shade.

**Fix:** Add Space Grotesk for display moments (brand header, VerdictCard verdict),
Plus Jakarta Sans as the primary body/UI font.

**Impeccable action:** `typeset`

---

### C2 — Typography: Flat hierarchy — nearly everything is `text-sm`

**Location:** All components
**Impact:** No information hierarchy; audience at 10 feet from projector cannot distinguish primary/secondary/tertiary

Survey of text sizes across all components:
- `text-5xl font-black` — VerdictCard verdict only
- `text-4xl font-black` — App header only
- `text-sm` — every section label, competitor name, description, market data, step text, feed steps, chart title, form label, everything

The jump is from 5xl directly to sm with nothing in between.

**Fix:** Establish scale: display (6xl+) → heading (2xl-3xl) → subheading (lg-xl) → body (sm-base) → caption (xs)

---

## High-Severity Issues

### H1 — Brand: Header is undersized for a demo app

**Location:** `App.tsx` lines 66-71
**Impact:** First impression on projector screen is weak; brand doesn't command space

`text-4xl font-black` for "✦ Chispa" is the same size as a typical page heading.
For a demo that needs to read from 10 feet, the brand should be significantly larger.
The tagline at `text-base text-gray-400` is barely readable.

**Fix:** Increase to `text-6xl` or larger with Space Grotesk. Tagline at `text-base`
with better contrast. Add very subtle radial depth to the header background.

---

### H2 — Color: Surface/background are nearly identical

**Location:** `tailwind.config.js`

- `background: '#0a0a0f'`
- `surface: '#13131a'`

Delta of only ~9 in the blue channel and ~11 in green. Cards barely lift off
the background. On a projector in a conference room, this will look entirely flat.

**Fix:** `surface: '#0e0e18'`, add `surface-elevated: '#151523'` for raised components.
Increase `border: '#252538'` (from `#1f1f2e` — too close to surface).

---

### H3 — ActivityFeed: No visual energy for the "wow" moment

**Location:** `ActivityFeed.tsx`
**Impact:** The live SSE feed is the demo's main "wow factor" — audience sees Claude thinking
in real time. The current UI doesn't reflect this excitement.

Current: plain list, `w-1.5 h-1.5` bullet dots, `text-sm text-gray-200` text,
header "Actividad en tiempo real" at `text-sm font-medium text-gray-300`.

**Fix:** Left accent border on the container, larger/brighter bullets, visible pulse
animation on the most recent step, header that communicates live activity.

---

### H4 — Select: No visible chevron indicator

**Location:** `IdeaForm.tsx` line 87

The country select has `appearance-none` (which removes the system chevron) but no
replacement indicator. Users cannot tell it's a dropdown on first glance.

**Fix:** Add `ChevronDown` from lucide-react (already installed) positioned absolutely.

---

## Medium Issues

### M1 — CompetitorCard: Favicon too small, hierarchy weak

**Location:** `CompetitorCard.tsx`

Favicon at 20×20px is very small. Competitor name at `text-sm font-semibold` looks
the same weight as body text throughout the app. No visual differentiation.

**Fix:** 28px favicon with rounded-md, competitor name at `text-base font-semibold`.

---

### M2 — MarketSnapshot: Values not prominent

**Location:** `MarketSnapshot.tsx`

`p className="text-white font-medium text-sm"` for market size values — same
visual weight as labels. This is key data that should read as a stat.

**Fix:** Values at `text-xl font-semibold text-white`, labels clearly subordinated.

---

### M3 — RiskRadarChart: Grid and fill too subtle

**Location:** `RiskRadarChart.tsx`

`PolarGrid stroke="#1f1f2e"` — the grid is the same color as the border token,
nearly invisible. `fillOpacity={0.3}` — the risk area is very transparent.

**Fix:** Grid stroke `#2e2e45` (more visible), fillOpacity `0.45`.

---

### M4 — Dashboard: Section labels identical to card headers

**Location:** `Dashboard.tsx`

"Competidores" section label: `text-sm font-medium text-gray-300 uppercase tracking-widest` —
identical to card-internal headers like "Análisis de Riesgos" and "Panorama de Mercado".

**Fix:** Lowercase with a horizontal rule or accent left border to differentiate
page-level section headers from component-level headers.

---

### M5 — FirstSteps: No stagger animation

**Location:** `FirstSteps.tsx`

The numbered list renders instantly with no entrance animation. Given Framer Motion
is already in the codebase and used on every other major component, this is a
conspicuous gap.

**Fix:** `motion.li` with staggered `delay: index * 0.05`.

---

### M6 — VerdictCard: Font doesn't match the moment

**Location:** `VerdictCard.tsx`

`text-5xl font-black` in Inter — correct scale but generic font. The verdict word
"LANZA / VALIDA / PIVOTA / EVITA" is the visual climax of the entire app.

**Fix:** Apply Space Grotesk (display font) to the verdict word. Increase to `text-6xl`.

---

### M7 — ShareButton: Unicode arrow, no Lucide icon

**Location:** `ShareButton.tsx`

`<span aria-hidden="true">↗</span>` — uses a Unicode arrow character while the
rest of the app uses Lucide icons (Loader2 in IdeaForm). Inconsistent.

**Fix:** Replace with `Link2` from lucide-react.

---

## Low Issues

### L1 — Textarea/select: Barely distinguishable from surface

The textarea `bg-surface` on a `bg-background` page with `border-border` is
hard to perceive as an interactive field at low contrast. A slightly elevated
background (`surface-elevated`) would make inputs feel distinct from the page.

### L2 — IdeaForm submit button: Generic shape

`rounded-lg` with flat `bg-primary` color. Could benefit from a stronger hover
state (slight scale or brightness increase, not just color).

---

## Positive Findings

1. **VerdictCard dynamic color** — semantic color per verdict type is genuinely well-done
2. **Framer Motion with `useReducedMotion()`** — accessibility-aware animation throughout
3. **MarketSnapshot timing badge** — proper semantic color, good proportions
4. **Accessibility foundation** — ARIA labels, `aria-live`, `role="alert"`, `aria-invalid` all correct
5. **Semantic Tailwind tokens** — `background`, `surface`, `border`, `primary` are the right abstraction level
6. **Dashboard layout structure** — verdict → chart+market → competitors → steps is correct information hierarchy

---

## Recommended Fix Sequence

### Phase 5: Design Foundation
1. Font system: Space Grotesk + Plus Jakarta Sans (index.html + tailwind.config)
2. Color tokens: surface depth + border visibility (tailwind.config)
3. App header redesign (App.tsx)

### Phase 6: Component Polish
4. IdeaForm: chevron + input elevation + button
5. ActivityFeed: accent border + energy
6. VerdictCard: display font + larger verdict
7. MarketSnapshot: stat-scale values
8. CompetitorCard: favicon + hierarchy
9. RiskRadarChart: grid + fill
10. Dashboard: section differentiation
11. FirstSteps: stagger animation
12. ShareButton: Lucide icon

---
*Generated: 2026-05-27 by impeccable audit*
