# 003 — Small UI polish: chevron, header icon, Progress table legend

## Title
Fix Settings double chevron, map-learning header icon, and label the Progress category table
(AC3 + AC4 + AC7)

## Goal
Three small, independent UI-polish defects grouped into one story because each is a contained view
tweak with no shared logic across the rest of the feature.

### AC3 — Settings "Idioma" double chevron
The "Idioma" row shows two disclosure chevrons (`>  >`) — a manual chevron stacked on the
`NavigationLink`'s built-in one. Show exactly one chevron.

### AC4 — Map-learning header icon
"Aprendizaje en mapa" shows a blurry/duplicated icon next to the back button. Clean it up to a
single crisp element.

### AC7 — Label the Progress category table
The per-category table header uses bare icons (circle / flame / refresh / star) with no legend. Add
accessible labels and/or a visible legend so the columns (new / learning / review / mastered) are
understandable. Any new visible/label strings must be localized to ALL locales.

## Scope
- Settings "Idioma" row: remove the redundant manual chevron.
- Map-learning header: single crisp icon (no blur/duplication) next to the back button.
- Progress category table: accessible labels and/or a visible legend for the four status columns.

## Out of Scope
- The redundant quiz back-nav (AC6 — handled in story 002).
- Map presentation polish (AC5), MC localization (AC1), Type-Capital layout (AC8).

## Constraints
- Any new user-visible strings or accessibility labels added to ALL locales so `just l10n-check`
  passes.
- Project generated from `project.yml` via `just generate` — never hand-edit pbxproj.
- `just lint` + `just test` must pass.
- Follow CLAUDE.md allowlistable-command conventions.

## Acceptance Criteria
1. The Settings "Idioma" row shows exactly one disclosure chevron.
2. The "Aprendizaje en mapa" header shows a single, crisp icon (no blur, no duplicate) beside the
   back button.
3. The Progress category table communicates the four columns (new / learning / review / mastered)
   via accessible labels and/or a visible legend; the accessibility dump exposes meaningful labels
   rather than bare icons.
4. `just l10n-check`, `just lint`, and `just test` pass.

## Verification (LIVE — AC9 baked in)
Verification is LIVE via `just ui-walkthrough <script> <run>` against the booted iPhone 17 /
iOS 26.5 sim — read screenshots AND accessibility dumps.
- Author action script(s) under
  `.workflow/ui-walkthrough/scripts/003-ui-polish.json` covering: Settings → Idioma row
  (screenshot + dump shows one chevron); open map-learning header (screenshot shows one crisp icon);
  Progress table (dump shows column labels / legend text).
- Capture **before/after** evidence (screenshots + accessibility dumps) for each of the three fixes
  and reference the run artifacts in the story/verify log (AC9).

## Branch
`feat/ship-readiness-uiux` (HANA_FEATURE_SLUG="ship-readiness-uiux").
