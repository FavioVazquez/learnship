# Phase 5: Design Foundation — Context

**Phase:** 5 of 6
**Milestone:** v1.1 — Impeccable UI
**Date:** 2026-05-27

## Goal

Establish the design system. Font, color, and header changes that everything
downstream depends on. Phases 5 and 6 are sequenced — foundation first,
component application second.

## Requirements in Scope

- UI-01: Space Grotesk display font
- UI-02: Plus Jakarta Sans body font
- UI-03: Type scale (display/heading/subheading/body/caption)
- UI-04: App header redesign
- UI-05: Surface/background color differentiation
- UI-06: Border token strengthening

## Key Decisions

### Font approach: Google Fonts CDN (not fontsource packages)

For conference demo on localhost, CDN is fine. No npm install needed.
Use `preconnect` + `display=swap` for performance.
Two families: Space Grotesk 700 (display only) + Plus Jakarta Sans 400/500/600/700.

### Color token changes (additive, backward-compatible)

New tokens added to tailwind.config.js:
- `surface`: `#13131a` → `#0e0e18` (more blue-shifted, clearly distinct from background)
- `surface-elevated`: `#151523` (new — raised components like cards)
- `border`: `#1f1f2e` → `#252538` (more visible)
- `border-strong`: `#3b3b55` (new — for active/focus states)

Rationale: The existing tokens work but the surface/background contrast is too low
for a projector environment. These are minimal changes that won't break existing components.

### Header: radial glow is acceptable — but kept very subtle

A `bg-primary/8 blur-3xl` radial shape gives the header section depth without
crossing into "neon on dark" AI slop territory. Kept at 8% opacity max.

### No new npm packages

lucide-react already installed. fonts via CDN. No package.json changes.

## What This Phase Does NOT Change

- Server code, routes, agent logic
- React component logic (only visual/styling)
- Types, hooks, data flow
- Accessibility attributes (already correct)
