# Phase 6: Component Polish — Context

**Phase:** 6 of 6
**Milestone:** v1.1 — Impeccable UI
**Date:** 2026-05-27

**Depends on:** Phase 5 complete (font + color tokens must be in place)

## Goal

Apply the design foundation to every component. Each component should have its
own visual identity — no more interchangeable gray boxes. The activity feed needs
to feel alive. The verdict reveal needs to feel like a climax.

## Requirements in Scope

- UI-07: IdeaForm — ChevronDown select, elevated inputs, stronger button
- UI-08: ActivityFeed — accent border, energy, animated latest step
- UI-09: VerdictCard — Space Grotesk verdict word, larger, better proportions
- UI-10: Dashboard — section differentiation
- UI-11: CompetitorCard — larger favicon, hierarchy
- UI-12: MarketSnapshot — stat-scale values
- UI-13: RiskRadarChart — grid + fill visibility
- UI-14: FirstSteps — stagger animation
- UI-15: ShareButton — Link2 Lucide icon

## Design Principles for This Phase

1. **The verdict is the climax** — VerdictCard should be the most visually
   dominant element on the page
2. **Feed = live spectacle** — ActivityFeed is where the magic happens for
   demo audiences; it needs to feel dynamic, not like a static log
3. **Differentiate, don't decorate** — components should look different from
   each other through typography and layout, not random decorative elements
4. **Conference-scale legibility** — key data (market size, verdict, step numbers)
   must be readable from 10 feet

## What This Phase Does NOT Change

- Server code, API, analysis types
- Shared TypeScript interfaces (analysis.ts)
- Animation timing/easing patterns already established (keep `easeOut`, keep `useReducedMotion`)
- Accessibility attributes (ARIA labels, live regions, etc. — all stay)
