# Phase 6 Discussion Log

**Date:** 2026-05-27

## Component-by-Component Design Decisions

### IdeaForm

**Problem:** Textarea/select indistinguishable from page background; select has no
visible affordance; submit button is generic rounded-lg.

**Decision:**
- Use `surface-elevated` as textarea/select background — visibly raised
- Add ChevronDown icon (lucide-react, already installed) to select
- Select wrapper becomes `relative` with icon positioned `right-3`
- Submit button: slight brightness increase on hover via `brightness-110`; no scale
  animation (feels wrong for a form submit); keep rounded-lg

### ActivityFeed

**Problem:** Plain list doesn't communicate "Claude is thinking in real-time."
The wow factor of the demo lives here.

**Decision:**
- Left accent border on the container: `border-l-2 border-primary`
- Larger bullets: `w-2 h-2` (was `w-1.5 h-1.5`)
- Animate latest step bullet with `animate-pulse` only on the last step
- Header: add live indicator dot (pulsing green) + "En vivo" label
- No changes to scroll behavior (already correct with `behavior: 'instant'`)

### VerdictCard

**Problem:** Inter font doesn't match the drama of the verdict reveal.

**Decision:**
- Apply `font-display` (Space Grotesk) to the verdict word only
- Increase verdict from `text-5xl font-black` to `text-7xl font-bold`
  (Space Grotesk 700 is more impactful than Inter 900 at the same size)
- Padding: `p-8` instead of `p-6` (more room for the larger text)
- Border thickness: `2px` instead of `1px` for the verdict border
- "Veredicto" label: increase to `text-xs` uppercase — already good, keep

### MarketSnapshot

**Problem:** Market size/growth values look like labels, not data.

**Decision:**
- Label: `text-xs text-gray-500 uppercase tracking-wider` → keep as is
- Value: `text-white font-medium text-sm` → `text-white font-semibold text-xl`
- Use `leading-tight` to keep values from pushing cards apart too much
- Timing badge: already good, keep

### CompetitorCard

**Problem:** Tiny favicon, competitor name indistinguishable from description.

**Decision:**
- Favicon: `width={20} height={20}` → `width={28} height={28}`, `rounded`
- Name: `text-sm font-semibold` → `text-base font-semibold`
- Description: keep `text-gray-400 text-sm` — intentional subordination

### RiskRadarChart

**Problem:** Grid lines invisible, fill area too light.

**Decision:**
- PolarGrid stroke: `#1f1f2e` → `#2a2a42` (more visible without being harsh)
- fillOpacity: `0.3` → `0.45` (more present, still breathable)
- Axis tick color: `#9ca3af` → `#a1a1b5` (slightly lighter, reads better)

### FirstSteps

**Problem:** List renders without animation; inconsistent with other animated components.

**Decision:**
- Wrap individual `<li>` items in `motion.li`
- `initial={{ opacity: 0, x: -12 }}` → `animate={{ opacity: 1, x: 0 }}`
- `delay: index * 0.07` (0, 70ms, 140ms, 210ms, 280ms for 5 items)
- Duration: `0.35s` with `easeOut`
- Reduced motion: `initial={{ opacity: 0 }}` → `animate={{ opacity: 1 }}`

### ShareButton

**Problem:** `↗` Unicode character inconsistent with lucide-react icons used elsewhere.

**Decision:**
- Replace with `Link2` from lucide-react at `w-4 h-4`
- Keep all other styling identical (this is a polish fix, not a redesign)
- Checkmark in copy state: keep `✓` Unicode (it's a checkmark, not an arrow)

### Dashboard sections

**Problem:** "Competidores" section heading looks like a card header.

**Decision:**
- Page-level section headers: remove `uppercase tracking-widest`, use
  `text-sm font-medium text-gray-400` with a left accent border or horizontal rule
- Differentiate: `<h3>` with `border-l-2 border-primary/50 pl-3 text-gray-300`
  — clearly a section label, not a component title
