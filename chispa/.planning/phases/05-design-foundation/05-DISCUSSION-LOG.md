# Phase 5 Discussion Log

**Date:** 2026-05-27

## Design Direction Agreed

**Source:** Impeccable audit findings + `/impeccable teach-impeccable` design context

**Brand personality:** Decisive, energetic, sharp. "Chispa" = spark.
Not corporate, not playful — confident and direct, like a smart advisor.

**Aesthetic:** Dark premium. High contrast. Bold typography hierarchy.
Stripe's dark mode polish + Vercel's typography precision.
Anti-pattern: generic AI chatbot UI, glassmorphism, neon glow.

**Font decision:**
- Space Grotesk for brand/display moments (App header, VerdictCard verdict word)
- Plus Jakarta Sans for everything else (warmer, more distinctive than Inter)
- Two families max — no more than this

**Color decision:**
- Surface lifted: `#0e0e18` vs background `#0a0a0f` — clear differentiation
- Added `surface-elevated: #151523` for raised cards
- Border strengthened: `#252538` (was barely visible at `#1f1f2e`)
- Added `border-strong: #3b3b55` for active/focus emphasis
- Primary purple unchanged — already in demo materials

**Header decision:**
- `text-6xl font-bold` Space Grotesk for "Chispa"
- Spark `✦` in primary color, slightly separated from the word
- Tagline rewritten: clearer, better contrast, slightly larger
- Very subtle radial background glow (8% primary opacity, blur-3xl)
- Conference-readable at 10 feet

## Why Plus Jakarta Sans over staying with Inter

Inter is 40% of the web. Plus Jakarta Sans:
- Warmer personality (slightly humanist)
- Better in medium-weight (500/600) which is used heavily in dark UIs
- Less immediately recognizable as "any tech website"
- Same character set coverage for Spanish/LatAm content

## Why Space Grotesk for display

- Geometric without being cold
- Excellent at large weights (700) — fills space confidently
- Distinctive enough to make the brand and verdict moments memorable
- Not overused — doesn't immediately read as "another AI tool"
