# 004 — Map presentation polish (keep satellite base)

## Title
Polish quiz-map presentation while keeping the satellite base and introducing NO place-name labels
(AC5)

## Goal
Improve the presentation of the quiz map without changing its core style. `.mapStyle(.imagery)`
(satellite) is the deliberate, correct answer to the place-name-label problem: a standard MapKit
style writes country/city names everywhere, revealing answers, and iOS MapKit gives no fine label
suppression. Keep the satellite base; improve only the surrounding presentation.

## Scope
- Tidy the overlay prompt card on the quiz map.
- Improve the "Apple Maps / Legal" attribution placement.
- Ensure consistent styling across the Map quiz and the Name-Feature quiz.

## Out of Scope (HARD)
- **No place-name labels** may be introduced anywhere on the quiz map (hard correctness constraint,
  not a style preference).
- A full vector / non-MapKit quiz-map redesign (drawing country shapes on a plain background) — the
  satellite base stays for this pass.

## Constraints
- KEEP `.mapStyle(.imagery)`; do not switch to a labeled map style.
- Any new user-visible strings localized to ALL locales (`just l10n-check`).
- Project generated from `project.yml` via `just generate` — never hand-edit pbxproj.
- `just lint` + `just test` must pass.
- Follow CLAUDE.md allowlistable-command conventions.

## Acceptance Criteria
1. The satellite base (`.mapStyle(.imagery)`) is retained.
2. NO answer-revealing place-name labels appear on the quiz map (verified via screenshot
   inspection across both map-based quizzes).
3. The overlay prompt card and the "Apple Maps / Legal" attribution are tidied and consistently
   placed across the Map and Name-Feature quizzes.
4. `just l10n-check`, `just lint`, and `just test` pass.

## Verification (LIVE — AC9 baked in)
Verification is LIVE via `just ui-walkthrough <script> <run>` against the booted iPhone 17 /
iOS 26.5 sim — read screenshots AND accessibility dumps.
- Author the action script under
  `.workflow/ui-walkthrough/scripts/004-map-polish.json` covering both the Map quiz and the
  Name-Feature quiz (screenshot the overlay card + attribution; dump tree).
- Inspect the produced screenshots to confirm **no place-name labels** are visible on the map and
  that the overlay/attribution are tidy and consistent across both quizzes.
- Capture **before/after** evidence (screenshots + accessibility dumps) and reference the run
  artifacts in the story/verify log (AC9).

## Branch
`feat/ship-readiness-uiux` (HANA_FEATURE_SLUG="ship-readiness-uiux").
