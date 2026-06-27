## Goal

Three small, independent UI-polish defects from the ship-readiness UI/UX feature, grouped into one
story because each is a contained view tweak with no shared logic. This lands incrementally on `main`.

## Summary of changes

- **AC3 — Settings "Idioma" double chevron.** The language row showed two disclosure chevrons
  (a manual chevron stacked on the `NavigationLink`'s built-in one). Removed the redundant manual
  chevron so exactly one is shown.
- **AC4 — Map-learning header icon.** The "Aprendizaje en mapa" header showed a blurry/duplicated
  icon next to the back button. Cleaned up to a single crisp element (no blur, no duplicate).
- **AC7 — Progress per-category table legend + labels.** The per-category table header used bare
  icons (circle / flame / refresh / star) with no legend. Added accessible labels plus a visible
  localized legend for the four states — **new / learning / review / mastered**
  (Nuevo / Aprendiendo / Repaso / Dominado) — localized to all 21 locales so `just l10n-check`
  passes. The accessibility dump now exposes meaningful labels per column and per cell instead of
  bare icons.
- **AC9 — Live walkthrough evidence.** Captured BEFORE/AFTER screenshots and accessibility dumps via
  the real `just ui-walkthrough` driver (iPhone 17 / iOS 26.5 sim).

## Walkthrough evidence (real driver runs)

- BEFORE: `.workflow/ui-walkthrough/003-before`
- AFTER:  `.workflow/ui-walkthrough/003-after`
  - Settings (one chevron): `006-step.png` — before: two chevrons; after: one
  - Map header (crisp back): `012-step.png` — before: blurry doubled chevron; after: single crisp
  - Progress table labels: `017-step.json` + `018-step.png` — before dump: 0 tier-name labels;
    after dump: Nuevo / Aprendiendo / Repaso / Dominado per column and per cell

## Test plan

- [x] `just l10n-check` — PASS
- [x] `just lint` — PASS
- [x] `just test` — PASS (** TEST SUCCEEDED **)
- [x] AC3: Settings "Idioma" row shows exactly one disclosure chevron
- [x] AC4: "Aprendizaje en mapa" header shows a single crisp icon beside the back button
- [x] AC7: Progress category table exposes meaningful column labels + visible localized legend
- [x] AC9: BEFORE/AFTER walkthrough screenshots + a11y dumps captured for all three fixes
