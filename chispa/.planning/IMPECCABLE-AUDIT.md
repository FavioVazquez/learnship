# Impeccable UI Audit — Chispa
_Date: 2026-05-26 | Auditor: impeccable/audit_

---

## Accessibility

- **[MAJOR — FIXED]** `IdeaForm` textarea lacked `aria-describedby` linking to its error message and char counter. Screen readers could not announce validation errors. Fixed: added `aria-describedby="idea-error"` / `"idea-counter"`, `aria-invalid`, and `role="alert"` on the error span.
- **[MAJOR — FIXED]** Submit button had no `aria-busy` during streaming state and the `Loader2` spinner had no `aria-hidden`. Fixed: added `aria-busy={isStreaming}`, `aria-label` during loading, and `aria-hidden="true"` on the spinner.
- **[MAJOR — FIXED]** `ActivityFeed` scrollable list had no `aria-live` region. Screen readers were silent while analysis steps streamed in. Fixed: added `aria-live="polite"` and `aria-label` to the step list container; added `role="status"` to the initial "Iniciando análisis..." state.
- **[MAJOR — FIXED]** Error banners in `App.tsx` (both URL-load error and analysis failure) had no `role="alert"`, so screen readers would not interrupt to announce them. Fixed: added `role="alert"` to both error containers.
- **[MAJOR — FIXED]** `ShareButton` used bare Unicode `↗` and `✓` characters without `aria-hidden`, causing screen readers to announce them as decoration. Also lacked an `aria-label` describing the clipboard action. Fixed: added `aria-hidden="true"` to both icon spans and `aria-label` to the button.
- **[MINOR]** `FirstSteps` step number circles are 28×28 px — below the 44×44 px minimum tap target for mobile. Not blocking (they are not interactive), but worth revisiting if steps become tappable.

---

## Animation / Reduced Motion

- **[MAJOR — FIXED]** `VerdictCard` flip animation (`rotateX: 90 → 0`) had no `prefers-reduced-motion` guard. A jarring 3D rotation is exactly what motion-sensitive users need to avoid. Fixed: used Framer Motion's `useReducedMotion()` hook to collapse the animation to a simple opacity fade (0.15 s) when the user preference is set.
- **[MAJOR — FIXED]** `Dashboard` slide-up animation (`y: 40 → 0`) also lacked reduced-motion handling. Fixed: same pattern — `useReducedMotion()` collapses to opacity-only fade.
- **[MAJOR — FIXED]** `ActivityFeed` per-step slide-in (`x: -8 → 0`) had no reduced-motion guard. Fixed: `useReducedMotion()` used to skip horizontal translate and shorten duration to 0.1 s.
- **[MAJOR — FIXED]** `RiskRadarChart` had `isAnimationActive={true}` hardcoded, enabling Recharts' built-in draw animation regardless of system preference. Fixed: reads `window.matchMedia('(prefers-reduced-motion: reduce)')` via `useMemo` and passes the result to `isAnimationActive`.

---

## Spanish Copy Quality

- **[MAJOR — FIXED]** `MarketSnapshot` heading "Snapshot de Mercado" mixed English "Snapshot" into an otherwise fully Spanish UI. Fixed: renamed to "Panorama de Mercado" — clear, natural Spanish equivalent.
- **[MINOR]** All other copy is correctly in Spanish throughout. Labels, error messages, country names, and UI strings are consistent and natural.

---

## Visual Hierarchy

- **[MINOR]** `RiskRadarChart` and `MarketSnapshot` section headings use `text-sm` — visually identical weight to body label text. No change made (the compact dark-card style is intentional), but worth revisiting with a slightly bolder weight (`font-semibold`) to distinguish section headings from data labels.
- **[MINOR]** `Dashboard` uses `text-sm uppercase tracking-widest` for section headings ("Competidores", "Primeros pasos") which is visually quiet. Consistent with the design system but the lowest readable contrast in the hierarchy.

---

## Empty / Edge States

- **[MINOR — No fix needed]** 0-competitor edge case is handled in `Dashboard` with a dedicated message card. The copy is helpful: "No se encontraron competidores directos — eso puede ser una ventaja."
- **[MINOR — No fix needed]** `FirstSteps` correctly returns `null` for PIVOT and AVOID verdicts — no orphan UI.
- **[MINOR — No fix needed]** `ActivityFeed` handles empty `steps[]` with a pulsing indicator, not a blank card.
- **[MINOR]** Very long `verdictReason` text in `VerdictCard` has no `line-clamp` — could overflow the card on small screens with verbose AI output. Low risk for demo context.

---

## Mobile

- **[MINOR — FIXED]** `IdeaForm` char counter and validation error were on the same `flex justify-between` row. On narrow screens (<320 px) both items compete for horizontal space and the error would truncate. Fixed: changed to `flex-col` stacked layout on mobile, switching to `sm:flex-row` at the small breakpoint.
- **[MINOR]** `RiskRadarChart` at 280 px height renders axis labels (`fontSize: 12`) at a comfortable size on mobile, but very long axis labels could clip. The six labels ("Mercado", "Competencia", etc.) are all short — no immediate issue.
- **[MINOR]** No fixed widths found across any component. All layouts use `w-full`, `max-w-*`, and responsive grid classes. Mobile overflow risk is low.

---

## Positive Findings

- Consistent use of `disabled:opacity-50 disabled:cursor-not-allowed` across interactive elements — clear affordance for the locked-during-streaming state.
- `CompetitorCard` favicon uses `alt=""` (correctly marking it decorative) and has a graceful `onError` hide fallback.
- Loading skeleton in `App.tsx` uses `aria-hidden="true"` correctly — assistive tech ignores the pulsing placeholder.
- Error copy throughout is specific and actionable (e.g., "Ajusta tu idea e intenta de nuevo con el formulario de arriba"), not generic.
- `ShareButton` clipboard failure is silently swallowed — correct UX for non-HTTPS dev environments.
